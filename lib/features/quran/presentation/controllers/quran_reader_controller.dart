import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';

enum QuranReadingMode { reading, memorization }

class QuranReaderController extends GetxController {
  QuranReaderController(this._storage);

  static const minFontSize = 20.0;
  static const maxFontSize = 42.0;
  static const defaultFontSize = 28.0;
  static const fontSizeStep = 2.0;

  final StorageService _storage;

  final readingMode = QuranReadingMode.reading.obs;
  final fontSize = defaultFontSize.obs;

  bool get canDecreaseFont => fontSize.value > minFontSize;
  bool get canIncreaseFont => fontSize.value < maxFontSize;

  @override
  void onInit() {
    super.onInit();
    readingMode.value = _modeFromStorage(
      _storage.readString(StorageKeys.quranReadingMode),
    );
    fontSize.value = _fontSizeFromStorage(
      _storage.readString(StorageKeys.quranFontSize),
    );
  }

  void setReadingMode(QuranReadingMode mode) {
    if (readingMode.value == mode) return;
    readingMode.value = mode;
    unawaited(_storage.writeString(StorageKeys.quranReadingMode, mode.name));
  }

  void increaseFontSize() => _setFontSize(fontSize.value + fontSizeStep);

  void decreaseFontSize() => _setFontSize(fontSize.value - fontSizeStep);

  void _setFontSize(double value) {
    final safeValue = value.clamp(minFontSize, maxFontSize).toDouble();
    if (fontSize.value == safeValue) return;
    fontSize.value = safeValue;
    unawaited(
      _storage.writeString(
        StorageKeys.quranFontSize,
        safeValue.toStringAsFixed(0),
      ),
    );
  }

  QuranReadingMode _modeFromStorage(String? value) =>
      value == QuranReadingMode.memorization.name
      ? QuranReadingMode.memorization
      : QuranReadingMode.reading;

  double _fontSizeFromStorage(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || !parsed.isFinite) return defaultFontSize;
    return parsed.clamp(minFontSize, maxFontSize).toDouble();
  }
}
