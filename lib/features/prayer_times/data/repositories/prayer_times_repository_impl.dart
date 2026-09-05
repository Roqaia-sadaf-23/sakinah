import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/location_data.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/repositories/prayer_times_repository.dart';
import '../datasources/prayer_times_remote_data_source.dart';
import '../models/prayer_schedule_model.dart';

class PrayerTimesRepositoryImpl implements PrayerTimesRepository {
  const PrayerTimesRepositoryImpl(this._remoteDataSource, this._storage);

  final PrayerTimesRemoteDataSource _remoteDataSource;
  final StorageService _storage;

  @override
  Future<PrayerSchedule> getSchedule({
    required DateTime date,
    required LocationData location,
  }) async {
    final key = _cacheKey(date, location);
    late final PrayerScheduleModel model;
    try {
      model = await _remoteDataSource.fetchSchedule(
        date: date,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    } catch (networkError) {
      final cached = _storage.readJson(key);
      if (cached != null) {
        try {
          final schedule = PrayerScheduleModel.fromCache(cached).schedule;
          if (kDebugMode) {
            debugPrint(
              '[PrayerTime] Schedule ${_dateLabel(date)} source=cache '
              '(network failed: $networkError)',
            );
          }
          return schedule;
        } catch (cacheError) {
          if (kDebugMode) {
            debugPrint('[PrayerTime] Invalid prayer cache: $cacheError');
          }
          // The original data-source exception gives a more useful error.
        }
      }
      rethrow;
    }

    try {
      await _storage.writeJson(key, model.toCache());
    } catch (cacheWriteError) {
      if (kDebugMode) {
        debugPrint(
          '[PrayerTime] Could not cache fresh schedule: $cacheWriteError',
        );
      }
    }
    if (kDebugMode) {
      debugPrint('[PrayerTime] Schedule ${_dateLabel(date)} source=network');
    }
    return model.schedule;
  }

  static String _dateLabel(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  String _cacheKey(DateTime date, LocationData location) {
    final datePart = DateFormat('yyyy-MM-dd').format(date);
    final latitude = location.latitude.toStringAsFixed(2);
    final longitude = location.longitude.toStringAsFixed(2);
    return '${StorageKeys.prayerSchedulePrefix}.$datePart.$latitude.$longitude';
  }
}
