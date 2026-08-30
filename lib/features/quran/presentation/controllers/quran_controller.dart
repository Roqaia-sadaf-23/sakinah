import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/quran_reading_position.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/usecases/get_quran_surahs.dart';
import '../../domain/usecases/get_surah.dart';

enum QuranViewStatus { loading, success, error }

class QuranController extends GetxController {
  QuranController(this._getQuranSurahs, this._getSurah, this._repository);

  final GetQuranSurahs _getQuranSurahs;
  final GetSurah _getSurah;
  final QuranRepository _repository;

  final status = QuranViewStatus.loading.obs;
  final surahStatus = QuranViewStatus.loading.obs;
  final surahs = <Surah>[].obs;
  final filteredSurahs = <Surah>[].obs;
  final currentSurah = Rxn<Surah>();
  final lastReadingPosition = Rxn<QuranReadingPosition>();
  final errorKey = 'quran_data_error'.obs;
  final surahErrorKey = 'quran_data_error'.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    lastReadingPosition.value = _repository.getLastReadingPosition();
    unawaited(loadSurahs());
  }

  Future<void> loadSurahs({bool forceRefresh = false}) async {
    status.value = QuranViewStatus.loading;
    try {
      final result = await _getQuranSurahs(forceRefresh: forceRefresh);
      surahs.assignAll(result);
      _applySearch(searchQuery.value);
      lastReadingPosition.value = _repository.getLastReadingPosition();
      status.value = QuranViewStatus.success;
    } catch (error) {
      errorKey.value = _errorKeyFor(error);
      status.value = QuranViewStatus.error;
    }
  }

  Future<void> loadSurah(int surahNumber, {bool forceRefresh = false}) async {
    surahStatus.value = QuranViewStatus.loading;
    currentSurah.value = null;
    try {
      currentSurah.value = await _getSurah(
        surahNumber,
        forceRefresh: forceRefresh,
      );
      surahStatus.value = QuranViewStatus.success;
    } catch (error) {
      surahErrorKey.value = _errorKeyFor(error);
      surahStatus.value = QuranViewStatus.error;
    }
  }

  void search(String query) {
    searchQuery.value = query;
    _applySearch(query);
  }

  Future<void> openSurah(Surah surah, {int ayahNumber = 1}) async {
    await markReadingPosition(surah.number, ayahNumber);
    await Get.toNamed<dynamic>(
      AppRoutes.surahPath(surah.number),
      arguments: <String, dynamic>{'ayah': ayahNumber},
    );
    lastReadingPosition.value = _repository.getLastReadingPosition();
  }

  Future<void> continueReading() async {
    final position = lastReadingPosition.value;
    if (position == null) return;
    final surah = surahs.firstWhereOrNull(
      (item) => item.number == position.surahNumber,
    );
    if (surah != null) {
      await openSurah(surah, ayahNumber: position.ayahNumber);
    }
  }

  Future<void> markReadingPosition(int surahNumber, int ayahNumber) async {
    final position = QuranReadingPosition(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    lastReadingPosition.value = position;
    try {
      await _repository.saveLastReadingPosition(position);
    } catch (_) {
      // Reading must remain available even if preferences cannot be persisted.
    }
  }

  void _applySearch(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) {
      filteredSurahs.assignAll(surahs);
      return;
    }
    filteredSurahs.assignAll(
      surahs.where((surah) {
        final number = surah.number.toString();
        return number == normalized ||
            _normalize(surah.arabicName).contains(normalized) ||
            _normalize(surah.englishName).contains(normalized) ||
            _normalize(surah.englishNameTranslation).contains(normalized);
      }),
    );
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
      .replaceAll('ٱ', 'ا')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _errorKeyFor(Object error) {
    if (error is AppException) {
      return switch (error.type) {
        AppErrorType.network => 'quran_no_internet',
        AppErrorType.timeout => 'quran_timeout',
        _ => 'quran_data_error',
      };
    }
    return 'quran_data_error';
  }
}
