import '../../../../core/location/location_data.dart';
import '../entities/prayer_schedule.dart';
import '../repositories/prayer_times_repository.dart';

class GetPrayerSchedule {
  const GetPrayerSchedule(this._repository);

  final PrayerTimesRepository _repository;

  Future<PrayerSchedule> call({
    required DateTime date,
    required LocationData location,
  }) => _repository.getSchedule(date: date, location: location);
}
