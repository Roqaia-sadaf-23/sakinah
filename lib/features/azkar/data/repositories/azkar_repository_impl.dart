import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/azkar_category.dart';
import '../../domain/entities/azkar_position.dart';
import '../../domain/repositories/azkar_repository.dart';
import '../datasources/azkar_local_data_source.dart';

class AzkarRepositoryImpl implements AzkarRepository {
  AzkarRepositoryImpl(
    this._localDataSource,
    this._storage, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AzkarLocalDataSource _localDataSource;
  final StorageService _storage;
  final DateTime Function() _now;
  List<AzkarCategory>? _categoryCache;

  @override
  Future<List<AzkarCategory>> getCategories() async {
    final cached = _categoryCache;
    if (cached != null) return cached;
    final models = await _localDataSource.loadCategories();
    final categories = models
        .map((model) => model.toEntity())
        .toList(growable: false);
    _categoryCache = categories;
    return categories;
  }

  @override
  Future<Map<String, int>> getCounts(AzkarCategory category) async {
    final progress = _readProgress();
    final stored = progress[category.id];
    if (stored is! Map<String, dynamic>) return <String, int>{};
    if (category.isDaily && stored['date'] != _todayKey()) {
      progress.remove(category.id);
      await _storage.writeJson(StorageKeys.azkarProgress, progress);
      return <String, int>{};
    }
    final rawCounts = stored['counts'];
    if (rawCounts is! Map<String, dynamic>) return <String, int>{};
    final targets = {
      for (final item in category.items) item.id: item.repeatCount,
    };
    return <String, int>{
      for (final entry in rawCounts.entries)
        if (targets.containsKey(entry.key) && _toInt(entry.value) != null)
          entry.key: _toInt(entry.value)!.clamp(0, targets[entry.key]!),
    };
  }

  @override
  Future<void> saveCounts(
    AzkarCategory category,
    Map<String, int> counts,
  ) async {
    final progress = _readProgress();
    progress[category.id] = <String, dynamic>{
      if (category.isDaily) 'date': _todayKey(),
      'counts': <String, int>{
        for (final item in category.items)
          if ((counts[item.id] ?? 0) > 0)
            item.id: (counts[item.id] ?? 0).clamp(0, item.repeatCount),
      },
    };
    await _storage.writeJson(StorageKeys.azkarProgress, progress);
  }

  @override
  Set<String> getFavoriteIds() {
    final raw = _storage.readJson(StorageKeys.azkarFavorites)?['ids'];
    return raw is List ? raw.whereType<String>().toSet() : <String>{};
  }

  @override
  Future<void> saveFavoriteIds(Set<String> ids) => _storage.writeJson(
    StorageKeys.azkarFavorites,
    <String, dynamic>{'ids': ids.toList(growable: false)..sort()},
  );

  @override
  AzkarPosition? getLastPosition() {
    final json = _storage.readJson(StorageKeys.azkarLastPosition);
    final categoryId = json?['categoryId'];
    final dhikrId = json?['dhikrId'];
    if (categoryId is! String || dhikrId is! String) return null;
    return AzkarPosition(categoryId: categoryId, dhikrId: dhikrId);
  }

  @override
  Future<void> saveLastPosition(AzkarPosition position) =>
      _storage.writeJson(StorageKeys.azkarLastPosition, <String, dynamic>{
        'categoryId': position.categoryId,
        'dhikrId': position.dhikrId,
      });

  @override
  double getFontSize() {
    final stored = double.tryParse(
      _storage.readString(StorageKeys.azkarFontSize) ?? '',
    );
    return (stored ?? 28).clamp(20, 40).toDouble();
  }

  @override
  Future<void> saveFontSize(double size) => _storage.writeString(
    StorageKeys.azkarFontSize,
    size.clamp(20, 40).toStringAsFixed(0),
  );

  Map<String, dynamic> _readProgress() => Map<String, dynamic>.from(
    _storage.readJson(StorageKeys.azkarProgress) ?? const <String, dynamic>{},
  );

  String _todayKey() {
    final date = _now().toLocal();
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  int? _toInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}
