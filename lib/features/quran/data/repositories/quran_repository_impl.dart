import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/quran_reading_position.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_audio_remote_data_source.dart';
import '../datasources/quran_remote_data_source.dart';
import '../models/surah_model.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl(
    this._remoteDataSource,
    this._audioRemoteDataSource,
    this._storage,
  );

  final QuranRemoteDataSource _remoteDataSource;
  final QuranAudioRemoteDataSource _audioRemoteDataSource;
  final StorageService _storage;
  final Map<String, Map<int, String>> _audioCache = {};
  final Map<String, Future<Map<int, String>>> _audioRequests = {};

  @override
  Future<List<Surah>> getSurahs({bool forceRefresh = false}) async {
    final cached = _readCatalogCache();
    if (!forceRefresh && cached != null) return cached;

    try {
      final models = await _remoteDataSource.fetchSurahs();
      final surahs = models
          .map((model) => model.toEntity())
          .toList(growable: false);
      if (!_isValidCatalog(surahs)) {
        throw const AppException(AppErrorType.invalidResponse);
      }
      await _storage.writeJson(StorageKeys.quranSurahList, <String, dynamic>{
        'version': 1,
        'surahs': models.map((model) => model.toJson()).toList(growable: false),
      });
      return surahs;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<Surah> getSurah(int surahNumber, {bool forceRefresh = false}) async {
    if (surahNumber < 1 || surahNumber > 114) {
      throw const AppException(AppErrorType.invalidResponse);
    }
    final cached = _readSurahCache(surahNumber);
    if (!forceRefresh && cached != null) return cached;

    try {
      final model = await _remoteDataSource.fetchSurah(surahNumber);
      final surah = model.toEntity();
      if (!_isValidLoadedSurah(surah, surahNumber)) {
        throw const AppException(AppErrorType.invalidResponse);
      }
      await _storage.writeJson(
        '${StorageKeys.quranSurahPrefix}.$surahNumber',
        <String, dynamic>{'version': 1, 'surah': model.toJson()},
      );
      return surah;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<Map<int, String>> getAyahAudioUrls({
    required int surahNumber,
    required Reciter reciter,
  }) async {
    final key = '${reciter.audioIdentifier}:$surahNumber';
    final cached = _audioCache[key];
    if (cached != null) return cached;
    final pending = _audioRequests[key];
    if (pending != null) return pending;

    final request = _audioRemoteDataSource.fetchAyahAudioUrls(
      surahNumber: surahNumber,
      audioIdentifier: reciter.audioIdentifier,
    );
    _audioRequests[key] = request;
    try {
      final urls = await request;
      _audioCache[key] = Map<int, String>.unmodifiable(urls);
      return _audioCache[key]!;
    } finally {
      _audioRequests.remove(key);
    }
  }

  @override
  Reciter getSelectedReciter() => SupportedReciters.fromId(
    _storage.readString(StorageKeys.quranSelectedReciter),
  );

  @override
  Future<void> saveSelectedReciter(Reciter reciter) async {
    final saved = await _storage.writeString(
      StorageKeys.quranSelectedReciter,
      reciter.id,
    );
    if (!saved) throw const AppException(AppErrorType.storage);
  }

  @override
  QuranReadingPosition? getLastReadingPosition() {
    final json = _storage.readJson(StorageKeys.quranLastReadingPosition);
    final surah = json?['surah'];
    final ayah = json?['ayah'];
    if (surah is! int || ayah is! int || surah < 1 || surah > 114 || ayah < 1) {
      return null;
    }
    return QuranReadingPosition(surahNumber: surah, ayahNumber: ayah);
  }

  @override
  Future<void> saveLastReadingPosition(QuranReadingPosition position) async {
    final saved = await _storage.writeJson(
      StorageKeys.quranLastReadingPosition,
      <String, dynamic>{
        'surah': position.surahNumber,
        'ayah': position.ayahNumber,
      },
    );
    if (!saved) throw const AppException(AppErrorType.storage);
  }

  List<Surah>? _readCatalogCache() {
    try {
      final json = _storage.readJson(StorageKeys.quranSurahList);
      final rawSurahs = json?['surahs'];
      if (json?['version'] != 1 || rawSurahs is! List) return null;
      final surahs = rawSurahs
          .map((item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid cached Surah');
            }
            return SurahModel.fromJson(item).toEntity();
          })
          .toList(growable: false);
      return _isValidCatalog(surahs) ? surahs : null;
    } catch (_) {
      return null;
    }
  }

  Surah? _readSurahCache(int surahNumber) {
    try {
      final json = _storage.readJson(
        '${StorageKeys.quranSurahPrefix}.$surahNumber',
      );
      final rawSurah = json?['surah'];
      if (json?['version'] != 1 || rawSurah is! Map<String, dynamic>) {
        return null;
      }
      final surah = SurahModel.fromJson(rawSurah).toEntity();
      return _isValidLoadedSurah(surah, surahNumber) ? surah : null;
    } catch (_) {
      return null;
    }
  }

  bool _isValidCatalog(List<Surah> surahs) =>
      surahs.length == 114 &&
      List<bool>.generate(
        surahs.length,
        (index) => surahs[index].number == index + 1,
      ).every((isValid) => isValid);

  bool _isValidLoadedSurah(Surah surah, int expectedNumber) =>
      surah.number == expectedNumber &&
      surah.numberOfAyahs == surah.ayahs.length &&
      List<bool>.generate(
        surah.ayahs.length,
        (index) => surah.ayahs[index].numberInSurah == index + 1,
      ).every((isValid) => isValid);
}
