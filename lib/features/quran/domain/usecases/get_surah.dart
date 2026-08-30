import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetSurah {
  const GetSurah(this._repository);

  final QuranRepository _repository;

  Future<Surah> call(int surahNumber, {bool forceRefresh = false}) =>
      _repository.getSurah(surahNumber, forceRefresh: forceRefresh);
}
