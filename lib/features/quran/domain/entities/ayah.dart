class Ayah {
  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    required this.juz,
    required this.page,
  });

  /// The Ayah's global Quran number (1–6236).
  final int number;
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;
}
