import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetQuranSurahs {
  const GetQuranSurahs(this._repository);

  final QuranRepository _repository;

  Future<List<Surah>> call({bool forceRefresh = false}) =>
      _repository.getSurahs(forceRefresh: forceRefresh);
}
