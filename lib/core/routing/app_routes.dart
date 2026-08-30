abstract final class AppRoutes {
  static const home = '/';
  static const quran = '/quran';
  static const quranSurah = '/quran/surah/:id';
  static const qibla = '/qibla';
  static const azkar = '/azkar';
  static const tasbih = '/tasbih';

  static String surahPath(int surahNumber) => '/quran/surah/$surahNumber';
}
