import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/storage/storage_keys.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_reader_controller.dart';

void main() {
  test('restores and persists reading mode and Quran font size', () async {
    final storage = _MemoryStorageService()
      ..values[StorageKeys.quranReadingMode] = 'memorization'
      ..values[StorageKeys.quranFontSize] = '36';
    final controller = QuranReaderController(storage)..onInit();

    expect(controller.readingMode.value, QuranReadingMode.memorization);
    expect(controller.fontSize.value, 36);

    controller.setReadingMode(QuranReadingMode.reading);
    controller.increaseFontSize();
    await Future<void>.delayed(Duration.zero);

    expect(storage.values[StorageKeys.quranReadingMode], 'reading');
    expect(storage.values[StorageKeys.quranFontSize], '38');

    final restored = QuranReaderController(storage)..onInit();
    expect(restored.readingMode.value, QuranReadingMode.reading);
    expect(restored.fontSize.value, 38);
  });

  test('clamps font size to safe bounds and rejects invalid stored values', () {
    final storage = _MemoryStorageService()
      ..values[StorageKeys.quranFontSize] = '-500'
      ..values[StorageKeys.quranReadingMode] = 'unknown';
    final controller = QuranReaderController(storage)..onInit();

    expect(controller.readingMode.value, QuranReadingMode.reading);
    expect(controller.fontSize.value, QuranReaderController.minFontSize);

    for (var index = 0; index < 50; index++) {
      controller.increaseFontSize();
    }
    expect(controller.fontSize.value, QuranReaderController.maxFontSize);
    expect(controller.canIncreaseFont, isFalse);

    for (var index = 0; index < 50; index++) {
      controller.decreaseFontSize();
    }
    expect(controller.fontSize.value, QuranReaderController.minFontSize);
    expect(controller.canDecreaseFont, isFalse);
  });

  test('uses defaults for a non-numeric persisted font size', () {
    final storage = _MemoryStorageService()
      ..values[StorageKeys.quranFontSize] = 'not-a-number';
    final controller = QuranReaderController(storage)..onInit();

    expect(controller.fontSize.value, QuranReaderController.defaultFontSize);
  });
}

class _MemoryStorageService extends StorageService {
  final Map<String, String> values = <String, String>{};

  @override
  String? readString(String key) => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }
}
