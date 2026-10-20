/// Formatting owned by the reader UI. The validated Quran API text contains
/// the Ayah text and diacritics, while its verse number is a separate field.
abstract final class QuranVerseMarker {
  /// U+06DD ARABIC END OF AYAH is the semantic Quranic verse terminator.
  static const endOfAyah = '\u06DD';

  static String format(int number) => '$endOfAyah${arabicIndic(number)}';

  static String arabicIndic(int value) {
    const western = '0123456789';
    const arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';
    return value.toString().split('').map((digit) {
      final index = western.indexOf(digit);
      return index < 0 ? digit : arabicIndicDigits[index];
    }).join();
  }
}
