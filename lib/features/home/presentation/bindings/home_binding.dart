import 'package:get/get.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../prayer_times/data/datasources/prayer_times_remote_data_source.dart';
import '../../../prayer_times/data/repositories/prayer_times_repository_impl.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_times/domain/usecases/get_prayer_schedule.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';
import '../../../prayer_tracker/data/repositories/local_prayer_tracker_repository.dart';
import '../../../prayer_tracker/domain/repositories/prayer_tracker_repository.dart';
import '../../../prayer_tracker/presentation/controllers/prayer_tracker_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.find<StorageService>();
    Get.lazyPut(() => LocationService(storage));
    Get.lazyPut(PrayerTimesRemoteDataSource.new);
    Get.lazyPut<PrayerTimesRepository>(
      () => PrayerTimesRepositoryImpl(
        Get.find<PrayerTimesRemoteDataSource>(),
        storage,
      ),
    );
    Get.lazyPut(() => GetPrayerSchedule(Get.find<PrayerTimesRepository>()));
    Get.lazyPut(
      () => PrayerTimesController(
        Get.find<LocationService>(),
        Get.find<GetPrayerSchedule>(),
      ),
    );
    Get.lazyPut<PrayerTrackerRepository>(
      () => LocalPrayerTrackerRepository(storage),
    );
    Get.lazyPut(
      () => PrayerTrackerController(Get.find<PrayerTrackerRepository>()),
    );
  }
}
