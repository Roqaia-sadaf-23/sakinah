import 'package:get/get.dart';

import '../../../../core/location/location_service.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../prayer_times/data/datasources/prayer_times_remote_data_source.dart';
import '../../../prayer_times/data/repositories/prayer_times_repository_impl.dart';
import '../../../prayer_times/domain/repositories/prayer_times_repository.dart';
import '../../../prayer_times/domain/usecases/get_prayer_schedule.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';
import '../../../prayer_times/presentation/controllers/prayer_reminder_controller.dart';
import '../../../prayer_times/presentation/services/prayer_notification_scheduler.dart';
import '../../../prayer_tracker/data/repositories/local_prayer_tracker_repository.dart';
import '../../../prayer_tracker/domain/repositories/prayer_tracker_repository.dart';
import '../../../prayer_tracker/presentation/controllers/prayer_tracker_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    final storage = Get.find<StorageService>();

    // Prayer Times dependencies
    Get.lazyPut<LocationService>(() => LocationService(storage));

    Get.lazyPut<PrayerTimesRemoteDataSource>(PrayerTimesRemoteDataSource.new);

    Get.lazyPut<PrayerTimesRepository>(
      () => PrayerTimesRepositoryImpl(
        Get.find<PrayerTimesRemoteDataSource>(),
        storage,
      ),
    );

    Get.lazyPut<GetPrayerSchedule>(
      () => GetPrayerSchedule(Get.find<PrayerTimesRepository>()),
    );

    Get.lazyPut<NotificationService>(FlutterLocalNotificationService.new);

    Get.lazyPut<PrayerNotificationScheduler>(
      () =>
          PrayerNotificationScheduler(Get.find<NotificationService>(), storage),
    );

    Get.lazyPut<PrayerReminderController>(
      () => PrayerReminderController(
        storage,
        Get.find<PrayerNotificationScheduler>(),
        Get.find<NotificationService>(),
      ),
    );

    Get.lazyPut<PrayerTimesController>(
      () => PrayerTimesController(
        Get.find<LocationService>(),
        Get.find<GetPrayerSchedule>(),
        Get.find<PrayerNotificationScheduler>(),
      ),
    );

    // Prayer Tracker dependencies
    Get.lazyPut<PrayerTrackerRepository>(
      () => LocalPrayerTrackerRepository(storage),
    );

    Get.lazyPut<PrayerTrackerController>(
      () => PrayerTrackerController(
        Get.find<PrayerTrackerRepository>(),
        Get.find<PrayerTimesController>(),
      ),
    );
  }
}
