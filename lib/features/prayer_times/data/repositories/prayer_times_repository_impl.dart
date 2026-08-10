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
    try {
      final model = await _remoteDataSource.fetchSchedule(
        date: date,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      await _storage.writeJson(key, model.toCache());
      return model.schedule;
    } catch (_) {
      final cached = _storage.readJson(key);
      if (cached != null) {
        try {
          return PrayerScheduleModel.fromCache(cached).schedule;
        } catch (_) {
          // The original data-source exception gives a more useful error.
        }
      }
      rethrow;
    }
  }

  String _cacheKey(DateTime date, LocationData location) {
    final datePart = DateFormat('yyyy-MM-dd').format(date);
    final latitude = location.latitude.toStringAsFixed(2);
    final longitude = location.longitude.toStringAsFixed(2);
    return '${StorageKeys.prayerSchedulePrefix}.$datePart.$latitude.$longitude';
  }
}
