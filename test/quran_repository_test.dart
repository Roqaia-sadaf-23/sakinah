import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/errors/app_exception.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/quran/data/datasources/quran_audio_remote_data_source.dart';
import 'package:sakinah/features/quran/data/datasources/quran_remote_data_source.dart';
import 'package:sakinah/features/quran/data/models/ayah_model.dart';
import 'package:sakinah/features/quran/data/models/surah_model.dart';
import 'package:sakinah/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:sakinah/features/quran/domain/entities/quran_reading_position.dart';
import 'package:sakinah/features/quran/domain/entities/reciter.dart';

void main() {
  test('loads and caches all 114 Surahs', () async {
    final storage = _MemoryStorageService();
    final remote = _FakeQuranRemoteDataSource();
    final repository = QuranRepositoryImpl(
      remote,
      _FakeQuranAudioRemoteDataSource(),
      storage,
    );

    final first = await repository.getSurahs();
    expect(first, hasLength(114));
    expect(remote.catalogRequests, 1);

    final offlineRepository = QuranRepositoryImpl(
      _FakeQuranRemoteDataSource(offline: true),
      _FakeQuranAudioRemoteDataSource(),
      storage,
    );
    final cached = await offlineRepository.getSurahs();
    expect(cached, hasLength(114));
    expect(cached.first.arabicName, 'سُورَةُ ٱلْفَاتِحَةِ');
  });

  test('caches a loaded Surah with Arabic Ayahs in Quran order', () async {
    final storage = _MemoryStorageService();
    final repository = QuranRepositoryImpl(
      _FakeQuranRemoteDataSource(),
      _FakeQuranAudioRemoteDataSource(),
      storage,
    );

    final surah = await repository.getSurah(1);
    expect(surah.ayahs, hasLength(7));
    expect(surah.ayahs.first.numberInSurah, 1);
    expect(surah.ayahs.last.numberInSurah, 7);
    expect(surah.ayahs.first.text, startsWith('بِسْمِ'));

    final offlineRepository = QuranRepositoryImpl(
      _FakeQuranRemoteDataSource(offline: true),
      _FakeQuranAudioRemoteDataSource(),
      storage,
    );
    final cached = await offlineRepository.getSurah(1);
    expect(cached.ayahs.map((ayah) => ayah.numberInSurah), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
  });

  test('persists selected reciter and last reading position', () async {
    final storage = _MemoryStorageService();
    final repository = QuranRepositoryImpl(
      _FakeQuranRemoteDataSource(),
      _FakeQuranAudioRemoteDataSource(),
      storage,
    );

    await repository.saveSelectedReciter(SupportedReciters.husary);
    await repository.saveLastReadingPosition(
      const QuranReadingPosition(surahNumber: 2, ayahNumber: 25),
    );

    expect(repository.getSelectedReciter().id, SupportedReciters.husary.id);
    expect(repository.getLastReadingPosition()?.surahNumber, 2);
    expect(repository.getLastReadingPosition()?.ayahNumber, 25);
  });
}

class _FakeQuranRemoteDataSource implements QuranRemoteDataSource {
  _FakeQuranRemoteDataSource({this.offline = false});

  final bool offline;
  int catalogRequests = 0;

  @override
  Future<List<SurahModel>> fetchSurahs() async {
    catalogRequests++;
    if (offline) throw const AppException(AppErrorType.network);
    return List<SurahModel>.generate(
      114,
      (index) => SurahModel(
        number: index + 1,
        arabicName: index == 0 ? 'سُورَةُ ٱلْفَاتِحَةِ' : 'سورة ${index + 1}',
        englishName: index == 0 ? 'Al-Faatiha' : 'Surah ${index + 1}',
        englishNameTranslation: index == 0 ? 'The Opening' : 'Translation',
        revelationType: index.isEven ? 'Meccan' : 'Medinan',
        numberOfAyahs: index == 0 ? 7 : 1,
      ),
      growable: false,
    );
  }

  @override
  Future<SurahModel> fetchSurah(int surahNumber) async {
    if (offline) throw const AppException(AppErrorType.network);
    return SurahModel(
      number: 1,
      arabicName: 'سُورَةُ ٱلْفَاتِحَةِ',
      englishName: 'Al-Faatiha',
      englishNameTranslation: 'The Opening',
      revelationType: 'Meccan',
      numberOfAyahs: 7,
      ayahs: List<AyahModel>.generate(
        7,
        (index) => AyahModel(
          number: index + 1,
          numberInSurah: index + 1,
          text: index == 0 ? '\uFEFFبِسْمِ ٱللَّهِ' : 'آية ${index + 1}',
          juz: 1,
          page: 1,
        ),
        growable: false,
      ),
    );
  }
}

class _FakeQuranAudioRemoteDataSource implements QuranAudioRemoteDataSource {
  @override
  Future<Map<int, String>> fetchAyahAudioUrls({
    required int surahNumber,
    required String audioIdentifier,
  }) async => <int, String>{1: 'https://example.com/$audioIdentifier/1.mp3'};
}

class _MemoryStorageService extends StorageService {
  final Map<String, String> _strings = {};
  final Map<String, Map<String, dynamic>> _json = {};

  @override
  String? readString(String key) => _strings[key];

  @override
  Map<String, dynamic>? readJson(String key) => _json[key];

  @override
  Future<bool> writeString(String key, String value) async {
    _strings[key] = value;
    return true;
  }

  @override
  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    _json[key] = value;
    return true;
  }
}
