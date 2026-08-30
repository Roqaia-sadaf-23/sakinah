import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/tasbih_item.dart';

enum TasbihTapResult { ignored, incremented, dhikrCompleted, sessionCompleted }

class TasbihController extends GetxController {
  TasbihController(
    this._storage, {
    DateTime Function()? now,
    this.transitionDuration = const Duration(milliseconds: 350),
  }) : _now = now ?? DateTime.now;

  final StorageService _storage;
  final DateTime Function() _now;
  final Duration transitionDuration;

  final currentIndex = 0.obs;
  final currentCount = 0.obs;
  final itemCounts = List<int>.filled(tasbihSequence.length, 0).obs;
  final isCompleted = false.obs;
  final isTransitioning = false.obs;

  Timer? _transitionTimer;
  Future<void> _persistenceQueue = Future<void>.value();

  static const totalTarget = 100;

  TasbihItem get currentDhikr => tasbihSequence[currentIndex.value];

  int get currentTarget => currentDhikr.target;

  List<int> get completedCounts => itemCounts.toList(growable: false);

  int get totalCompleted => itemCounts.fold(0, (total, value) => total + value);

  double get progress => (totalCompleted / totalTarget).clamp(0, 1);

  bool get hasProgress => totalCompleted > 0 || isCompleted.value;

  @override
  void onInit() {
    super.onInit();
    loadProgress();
  }

  void loadProgress() {
    _transitionTimer?.cancel();
    isTransitioning.value = false;
    final json = _storage.readJson(StorageKeys.tasbihProgress);
    if (json == null || json['date'] != _todayKey()) {
      _setInitialState();
      if (json != null) _queueSave();
      return;
    }

    final storedCounts = json['counts'];
    final restored = List<int>.filled(tasbihSequence.length, 0);
    if (storedCounts is List) {
      for (
        var index = 0;
        index < storedCounts.length && index < restored.length;
        index++
      ) {
        final value = _toInt(storedCounts[index]) ?? 0;
        restored[index] = value.clamp(0, tasbihSequence[index].target);
      }
    }

    var firstIncomplete = -1;
    for (var index = 0; index < restored.length; index++) {
      if (restored[index] < tasbihSequence[index].target) {
        firstIncomplete = index;
        break;
      }
    }
    if (firstIncomplete == -1) {
      itemCounts.assignAll(restored);
      currentIndex.value = tasbihSequence.length - 1;
      currentCount.value = tasbihSequence.last.target;
      isCompleted.value = true;
      return;
    }

    for (var index = 0; index < firstIncomplete; index++) {
      restored[index] = tasbihSequence[index].target;
    }
    for (var index = firstIncomplete + 1; index < restored.length; index++) {
      restored[index] = 0;
    }
    itemCounts.assignAll(restored);
    currentIndex.value = firstIncomplete;
    currentCount.value = restored[firstIncomplete];
    isCompleted.value = false;
  }

  TasbihTapResult increment() {
    if (isCompleted.value || isTransitioning.value) {
      return TasbihTapResult.ignored;
    }
    final index = currentIndex.value;
    final target = tasbihSequence[index].target;
    if (currentCount.value >= target) return TasbihTapResult.ignored;

    final nextCount = (currentCount.value + 1).clamp(0, target);
    currentCount.value = nextCount;
    itemCounts[index] = nextCount;

    if (nextCount < target) {
      _queueSave();
      return TasbihTapResult.incremented;
    }
    if (index == tasbihSequence.length - 1) {
      isCompleted.value = true;
      _queueSave();
      return TasbihTapResult.sessionCompleted;
    }

    isTransitioning.value = true;
    _queueSave();
    _transitionTimer?.cancel();
    _transitionTimer = Timer(transitionDuration, _moveToNextDhikr);
    return TasbihTapResult.dhikrCompleted;
  }

  void _moveToNextDhikr() {
    if (!isTransitioning.value || isCompleted.value) return;
    currentIndex.value++;
    currentCount.value = itemCounts[currentIndex.value];
    isTransitioning.value = false;
    _queueSave();
  }

  void reset() {
    _transitionTimer?.cancel();
    _setInitialState();
    _queueSave();
  }

  Future<void> saveProgress() {
    final snapshot = <String, dynamic>{
      'date': _todayKey(),
      'currentIndex': currentIndex.value,
      'currentCount': currentCount.value,
      'counts': itemCounts.toList(growable: false),
      'completed': isCompleted.value,
    };
    _persistenceQueue = _persistenceQueue
        .then((_) => _storage.writeJson(StorageKeys.tasbihProgress, snapshot))
        .then<void>((_) {})
        .catchError((Object _) {
          // Counting remains available if a local preference write fails.
        });
    return _persistenceQueue;
  }

  void _queueSave() {
    unawaited(saveProgress());
  }

  void _setInitialState() {
    currentIndex.value = 0;
    currentCount.value = 0;
    itemCounts.assignAll(List<int>.filled(tasbihSequence.length, 0));
    isCompleted.value = false;
    isTransitioning.value = false;
  }

  String _todayKey() {
    final date = _now().toLocal();
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  int? _toInt(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  @override
  void onClose() {
    _transitionTimer?.cancel();
    super.onClose();
  }
}
