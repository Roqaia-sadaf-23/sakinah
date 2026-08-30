import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/location/location_data.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/usecases/get_prayer_schedule.dart';
import '../services/prayer_notification_scheduler.dart';

enum PrayerTimesViewStatus { loading, success, error }

class PrayerTimesController extends GetxController {
  PrayerTimesController(
    this._locationService,
    this._getPrayerSchedule, [
    this._notificationScheduler,
  ]);

  final LocationService _locationService;
  final GetPrayerSchedule _getPrayerSchedule;
  final PrayerNotificationScheduler? _notificationScheduler;

  final status = PrayerTimesViewStatus.loading.obs;
  final location = Rxn<LocationData>();
  final todaySchedule = Rxn<PrayerSchedule>();
  final tomorrowSchedule = Rxn<PrayerSchedule>();
  final nextPrayer = Rxn<Prayer>();
  final remaining = Duration.zero.obs;
  final now = DateTime.now().obs;
  final errorKey = ''.obs;

  Timer? _ticker;
  DateTime? _loadedDate;
  bool _isRefreshing = false;

  bool get isUsingCache =>
      location.value?.isCached == true || todaySchedule.value?.isCached == true;

  bool get canOpenSettings => {
    'location_services_disabled',
    'location_permission_permanently_denied',
  }.contains(errorKey.value);

  String get locationLabel {
    final value = location.value?.displayName ?? '';
    return value.isEmpty ? 'location_unknown'.tr : value;
  }

  String get gregorianDate =>
      DateFormat.yMMMMd(Get.locale?.languageCode).format(now.value);

  String get hijriDate =>
      todaySchedule.value?.hijriLabel(
        arabic: Get.locale?.languageCode == 'ar',
      ) ??
      '—';

  String formatTime(DateTime time) =>
      DateFormat.jm(Get.locale?.languageCode).format(time);

  @override
  void onInit() {
    super.onInit();
    //refreshPrayerTimes();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void onReady() {
    super.onReady();

    Future.microtask(() async {
      await refreshPrayerTimes();
    });
  }

  Future<void> refreshPrayerTimes() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    status.value = PrayerTimesViewStatus.loading;
    errorKey.value = '';

    try {
      debugPrint('1 - Getting location');

      final currentLocation = await _locationService.getCurrentLocation();

      debugPrint('2 - Location received');

      final currentDate = DateTime.now().dateOnly;

      debugPrint('3 - Getting today schedule');

      final today = await _getPrayerSchedule(
        date: currentDate,
        location: currentLocation,
      );

      debugPrint('4 - Today schedule received');

      final tomorrow = await _getPrayerSchedule(
        date: currentDate.add(const Duration(days: 1)),
        location: currentLocation,
      );

      debugPrint('5 - Tomorrow schedule received');

      location.value = currentLocation;
      todaySchedule.value = today;
      tomorrowSchedule.value = tomorrow;

      _loadedDate = currentDate;
      status.value = PrayerTimesViewStatus.success;

      _updateNextPrayer(DateTime.now());

      final scheduler = _notificationScheduler;
      if (scheduler != null) {
        unawaited(
          scheduler
              .updateSchedules(
                today: today,
                tomorrow: tomorrow,
                languageCode: Get.locale?.languageCode ?? 'en',
              )
              .catchError((Object error, StackTrace stackTrace) {
                debugPrint('Prayer reminder update failed: $error');
              }),
        );
      }

      debugPrint('6 - Prayer times completed');
    } catch (error, stackTrace) {
      debugPrint('Prayer times error: $error');
      debugPrintStack(stackTrace: stackTrace);

      errorKey.value = error is AppException
          ? error.localizationKey
          : 'prayer_times_error';

      status.value = PrayerTimesViewStatus.error;
    } finally {
      _isRefreshing = false;
    }
  }

  /*
  Future<void> refreshPrayerTimes() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    status.value = PrayerTimesViewStatus.loading;
    errorKey.value = '';
    try {
      final currentLocation = await _locationService.getCurrentLocation();
      final currentDate = DateTime.now().dateOnly;
      final schedules = await Future.wait([
        _getPrayerSchedule(date: currentDate, location: currentLocation),
        _getPrayerSchedule(
          date: currentDate.add(const Duration(days: 1)),
          location: currentLocation,
        ),
      ]);
      location.value = currentLocation;
      todaySchedule.value = schedules[0];
      tomorrowSchedule.value = schedules[1];
      _loadedDate = currentDate;
      status.value = PrayerTimesViewStatus.success;
      _updateNextPrayer(DateTime.now());
    } catch (error) {
      errorKey.value = error is AppException
          ? error.localizationKey
          : 'prayer_times_error';
      status.value = PrayerTimesViewStatus.error;
    } finally {
      _isRefreshing = false;
    }
  }
 */
  Future<void> openRelevantSettings() async {
    if (errorKey.value == 'location_services_disabled') {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }

  void _tick() {
    final current = DateTime.now();
    now.value = current;
    if (_loadedDate != null && _loadedDate != current.dateOnly) {
      unawaited(refreshPrayerTimes());
      return;
    }
    _updateNextPrayer(current);
  }

  void _updateNextPrayer(DateTime current) {
    final today = todaySchedule.value;
    if (today == null) return;
    final upcoming = today.prayers
        .where((prayer) => prayer.name.isObligatory)
        .where((prayer) => prayer.time.isAfter(current))
        .firstOrNull;
    final selected =
        upcoming ?? tomorrowSchedule.value?.prayer(PrayerName.fajr);
    nextPrayer.value = selected;
    remaining.value = selected == null
        ? Duration.zero
        : selected.time.difference(current);
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }
}
