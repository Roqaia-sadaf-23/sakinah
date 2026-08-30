import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/azkar_category.dart';
import '../../domain/entities/azkar_position.dart';
import '../../domain/entities/dhikr.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../../domain/usecases/get_azkar_categories.dart';

enum AzkarViewStatus { loading, success, error }

class AzkarController extends GetxController {
  AzkarController(this._getCategories, this._repository);

  final GetAzkarCategories _getCategories;
  final AzkarRepository _repository;

  final status = AzkarViewStatus.loading.obs;
  final errorKey = 'azkar_data_error'.obs;
  final categories = <AzkarCategory>[].obs;
  final currentCategory = Rxn<AzkarCategory>();
  final currentIndex = 0.obs;
  final countsByCategory = <String, Map<String, int>>{}.obs;
  final favoriteIds = <String>{}.obs;
  final lastPosition = Rxn<AzkarPosition>();
  final fontSize = 28.0.obs;

  Future<void>? _loadFuture;
  Future<void> _persistenceQueue = Future<void>.value();

  static const minFontSize = 20.0;
  static const maxFontSize = 40.0;

  @override
  void onInit() {
    super.onInit();
    favoriteIds.assignAll(_repository.getFavoriteIds());
    lastPosition.value = _repository.getLastPosition();
    fontSize.value = _repository.getFontSize();
    unawaited(loadCategories());
  }

  Future<void> loadCategories() {
    final active = _loadFuture;
    if (active != null) return active;
    if (status.value == AzkarViewStatus.success && categories.isNotEmpty) {
      return Future<void>.value();
    }
    final future = _load();
    _loadFuture = future;
    return future.whenComplete(() => _loadFuture = null);
  }

  Future<void> _load() async {
    status.value = AzkarViewStatus.loading;
    try {
      final loaded = await _getCategories();
      final progress = await Future.wait([
        for (final category in loaded) _repository.getCounts(category),
      ]);
      categories.assignAll(loaded);
      countsByCategory.assignAll(<String, Map<String, int>>{
        for (var index = 0; index < loaded.length; index++)
          loaded[index].id: progress[index],
      });
      status.value = AzkarViewStatus.success;
    } catch (_) {
      errorKey.value = 'azkar_data_error';
      status.value = AzkarViewStatus.error;
    }
  }

  AzkarCategory? categoryById(String id) {
    if (id == 'favorites') return _favoritesCategory();
    return categories.firstWhereOrNull((category) => category.id == id);
  }

  Future<void> openCategory(String id) async {
    await Get.toNamed<dynamic>(AppRoutes.azkarCategoryPath(id));
    lastPosition.value = _repository.getLastPosition();
  }

  Future<void> continueAzkar() async {
    final position = lastPosition.value;
    if (position == null) return;
    await openCategory(position.categoryId);
  }

  Future<void> selectCategory(String id) async {
    await loadCategories();
    final category = categoryById(id);
    if (category == null || category.items.isEmpty) {
      currentCategory.value = null;
      errorKey.value = id == 'favorites'
          ? 'azkar_no_favorites'
          : 'azkar_category_not_found';
      return;
    }
    currentCategory.value = category;
    final saved = lastPosition.value;
    final savedIndex = saved?.categoryId == id
        ? category.items.indexWhere((item) => item.id == saved!.dhikrId)
        : -1;
    currentIndex.value = savedIndex >= 0 ? savedIndex : 0;
    _saveCurrentPosition();
  }

  Dhikr? get currentDhikr {
    final category = currentCategory.value;
    final index = currentIndex.value;
    if (category == null || index < 0 || index >= category.items.length) {
      return null;
    }
    return category.items[index];
  }

  int countFor(Dhikr item) => countsByCategory[item.categoryId]?[item.id] ?? 0;

  bool isCompleted(Dhikr item) => countFor(item) >= item.repeatCount;

  int completedCount(AzkarCategory category) =>
      category.items.where(isCompleted).length;

  void incrementCurrent() {
    final item = currentDhikr;
    if (item == null) return;
    final current = countFor(item);
    if (current >= item.repeatCount) return;
    _updateCount(item, current + 1);
  }

  void resetCurrent() {
    final item = currentDhikr;
    if (item == null || countFor(item) == 0) return;
    _updateCount(item, 0);
  }

  void _updateCount(Dhikr item, int value) {
    final category = categoryById(item.categoryId);
    if (category == null) return;
    final updated = Map<String, int>.from(
      countsByCategory[item.categoryId] ?? const <String, int>{},
    );
    final safeValue = value.clamp(0, item.repeatCount);
    if (safeValue == 0) {
      updated.remove(item.id);
    } else {
      updated[item.id] = safeValue;
    }
    countsByCategory[item.categoryId] = updated;
    countsByCategory.refresh();
    _queuePersistence(() => _repository.saveCounts(category, updated));
  }

  void showPrevious() {
    if (currentIndex.value <= 0) return;
    currentIndex.value--;
    _saveCurrentPosition();
  }

  void showNext() {
    final category = currentCategory.value;
    if (category == null || currentIndex.value >= category.items.length - 1) {
      return;
    }
    currentIndex.value++;
    _saveCurrentPosition();
  }

  bool get hasPrevious => currentIndex.value > 0;

  bool get hasNext {
    final category = currentCategory.value;
    return category != null && currentIndex.value < category.items.length - 1;
  }

  bool isFavorite(Dhikr item) => favoriteIds.contains(item.id);

  void toggleFavoriteCurrent() {
    final item = currentDhikr;
    if (item == null) return;
    final updated = favoriteIds.toSet();
    if (!updated.add(item.id)) updated.remove(item.id);
    favoriteIds.assignAll(updated);
    _queuePersistence(() => _repository.saveFavoriteIds(updated));
    if (currentCategory.value?.id == 'favorites') {
      final refreshed = _favoritesCategory();
      currentCategory.value = refreshed.items.isEmpty ? null : refreshed;
      if (refreshed.items.isNotEmpty) {
        currentIndex.value = currentIndex.value.clamp(
          0,
          refreshed.items.length - 1,
        );
        _saveCurrentPosition();
      }
    }
  }

  void increaseFontSize() => _setFontSize(fontSize.value + 2);

  void decreaseFontSize() => _setFontSize(fontSize.value - 2);

  void _setFontSize(double value) {
    final safeValue = value.clamp(minFontSize, maxFontSize).toDouble();
    if (safeValue == fontSize.value) return;
    fontSize.value = safeValue;
    _queuePersistence(() => _repository.saveFontSize(safeValue));
  }

  void _saveCurrentPosition() {
    final category = currentCategory.value;
    final item = currentDhikr;
    if (category == null || item == null) return;
    final position = AzkarPosition(categoryId: category.id, dhikrId: item.id);
    lastPosition.value = position;
    _queuePersistence(() => _repository.saveLastPosition(position));
  }

  AzkarCategory _favoritesCategory() {
    final seen = <String>{};
    final items = <Dhikr>[
      for (final category in categories)
        for (final item in category.items)
          if (favoriteIds.contains(item.id) && seen.add(item.id)) item,
    ];
    return AzkarCategory(
      id: 'favorites',
      titleKey: 'favorites',
      isDaily: false,
      items: items,
    );
  }

  void _queuePersistence(Future<void> Function() action) {
    _persistenceQueue = _persistenceQueue.then((_) => action()).catchError((
      Object _,
    ) {
      // UI state remains usable if a local preference write fails.
    });
  }
}
