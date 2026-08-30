import '../entities/quran_reading_position.dart';
import '../entities/reciter.dart';
import '../entities/surah.dart';

abstract interface class QuranRepository {
  Future<List<Surah>> getSurahs({bool forceRefresh = false});

  Future<Surah> getSurah(int surahNumber, {bool forceRefresh = false});

  Future<Map<int, String>> getAyahAudioUrls({
    required int surahNumber,
    required Reciter reciter,
  });

  Reciter getSelectedReciter();

  Future<void> saveSelectedReciter(Reciter reciter);

  QuranReadingPosition? getLastReadingPosition();

  Future<void> saveLastReadingPosition(QuranReadingPosition position);
}
