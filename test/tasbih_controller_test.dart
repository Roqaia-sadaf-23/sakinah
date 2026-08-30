import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/tasbih/domain/entities/tasbih_item.dart';
import 'package:sakinah/features/tasbih/presentation/controllers/tasbih_controller.dart';

void main() {
  test('uses the exact 33, 33, 33, 1 Arabic sequence', () {
    expect(tasbihSequence.map((item) => item.text), <String>[
      'سبحان الله',
      'الحمد لله',
      'الله أكبر',
      'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير',
    ]);
    expect(tasbihSequence.map((item) => item.target), <int>[33, 33, 33, 1]);
    expect(
      tasbihSequence.fold(0, (total, item) => total + item.target),
      TasbihController.totalTarget,
    );
  });

  test(
    'holds the completed count briefly before moving to the next Dhikr',
    () async {
      final controller = _controller(_MemoryStorageService());
      controller.loadProgress();

      for (var count = 0; count < 32; count++) {
        expect(controller.increment(), TasbihTapResult.incremented);
      }
      expect(controller.increment(), TasbihTapResult.dhikrCompleted);
      expect(controller.currentIndex.value, 0);
      expect(controller.currentCount.value, 33);
      expect(controller.isTransitioning.value, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 1));
      expect(controller.currentIndex.value, 1);
      expect(controller.currentDhikr.text, 'الحمد لله');
      expect(controller.currentCount.value, 0);
      expect(controller.totalCompleted, 33);
    },
  );

  test('completes exactly 100 counts and never exceeds a target', () async {
    final controller = _controller(_MemoryStorageService());
    controller.loadProgress();

    for (var itemIndex = 0; itemIndex < tasbihSequence.length; itemIndex++) {
      final target = tasbihSequence[itemIndex].target;
      TasbihTapResult result = TasbihTapResult.ignored;
      for (var count = 0; count < target; count++) {
        result = controller.increment();
      }
      if (itemIndex < tasbihSequence.length - 1) {
        expect(result, TasbihTapResult.dhikrCompleted);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      } else {
        expect(result, TasbihTapResult.sessionCompleted);
      }
    }

    expect(controller.totalCompleted, 100);
    expect(controller.progress, 1);
    expect(controller.isCompleted.value, isTrue);
    expect(controller.increment(), TasbihTapResult.ignored);
    expect(controller.currentCount.value, 1);
  });

  test(
    'restores a halfway session through the existing storage service',
    () async {
      final storage = _MemoryStorageService();
      final first = _controller(storage);
      first.loadProgress();
      for (var count = 0; count < 33; count++) {
        first.increment();
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
      for (var count = 0; count < 17; count++) {
        first.increment();
      }
      await first.saveProgress();

      final reopened = _controller(storage)..loadProgress();
      expect(reopened.currentIndex.value, 1);
      expect(reopened.currentDhikr.text, 'الحمد لله');
      expect(reopened.currentCount.value, 17);
      expect(reopened.completedCounts, <int>[33, 17, 0, 0]);
      expect(reopened.totalCompleted, 50);
    },
  );

  test('resets automatically on a new local calendar day', () async {
    final storage = _MemoryStorageService();
    var now = DateTime(2026, 8, 30, 23, 55);
    final first = TasbihController(
      storage,
      now: () => now,
      transitionDuration: Duration.zero,
    )..loadProgress();
    for (var count = 0; count < 12; count++) {
      first.increment();
    }
    await first.saveProgress();

    now = DateTime(2026, 8, 31, 0, 1);
    final nextDay = TasbihController(
      storage,
      now: () => now,
      transitionDuration: Duration.zero,
    )..loadProgress();
    expect(nextDay.currentIndex.value, 0);
    expect(nextDay.currentCount.value, 0);
    expect(nextDay.totalCompleted, 0);
  });

  test('reset cancels a pending transition and clears all progress', () async {
    final controller = _controller(_MemoryStorageService())..loadProgress();
    for (var count = 0; count < 33; count++) {
      controller.increment();
    }
    expect(controller.isTransitioning.value, isTrue);

    controller.reset();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(controller.currentIndex.value, 0);
    expect(controller.currentCount.value, 0);
    expect(controller.completedCounts, <int>[0, 0, 0, 0]);
    expect(controller.isCompleted.value, isFalse);
  });
}

TasbihController _controller(StorageService storage) => TasbihController(
  storage,
  now: () => DateTime(2026, 8, 30, 12),
  transitionDuration: Duration.zero,
);

class _MemoryStorageService extends StorageService {
  final Map<String, Map<String, dynamic>> values =
      <String, Map<String, dynamic>>{};

  @override
  Map<String, dynamic>? readJson(String key) {
    final value = values[key];
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  @override
  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    values[key] = Map<String, dynamic>.from(value);
    return true;
  }
}
