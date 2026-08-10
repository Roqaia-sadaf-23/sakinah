import '../../../../core/location/location_data.dart';
import '../entities/prayer_schedule.dart';

abstract interface class PrayerTimesRepository {
  Future<PrayerSchedule> getSchedule({
    required DateTime date,
    required LocationData location,
  });
}
