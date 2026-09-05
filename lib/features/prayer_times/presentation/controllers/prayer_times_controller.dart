import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/errors/app_exception.dart';
import '../../../../core/location/location_data.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../../core/utils/timezone_utils.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_schedule.dart';
import '../../domain/usecases/get_prayer_schedule.dart';
import '../services/prayer_notification_scheduler.dart';

enum PrayerTimesViewStatus { loading, success, error }

typedef PrayerTimesNow = DateTime Function();
typedef PrayerTickerFactory =
    Timer Function(Duration duration, void Function(Timer timer) callback);

class PrayerTimesController extends GetxController with WidgetsBindingObserver {
  PrayerTimesController(
    this._locationService,
    this._getPrayerSchedule, [
    this._notificationScheduler,
    PrayerTimesNow? currentTime,
    PrayerTickerFactory? tickerFactory,
  ]) : _currentTime = currentTime ?? DateTime.now,
       _tickerFactory = tickerFactory ?? Timer.periodic;

  final LocationService _locationService;
  final GetPrayerSchedule _getPrayerSchedule;
  final PrayerNotificationScheduler? _notificationScheduler;
  final PrayerTimesNow _currentTime;
  final PrayerTickerFactory _tickerFactory;

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
  PrayerName? _lastLoggedPrayer;
  int? _lastLoggedMinute;

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
    WidgetsBinding.instance.addObserver(this);
    _ensureTicker();
  }

  @override
  void onReady() {
    super.onReady();

    Future.microtask(() async {
      await refreshPrayerTimes();
    });
  }

  Future<void> refreshPrayerTimes({bool showLoading = true}) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    if (showLoading || todaySchedule.value == null) {
      status.value = PrayerTimesViewStatus.loading;
    }
    errorKey.value = '';

    try {
      final currentLocation = await _locationService.getCurrentLocation();
      final deviceNow = _currentTime();
      var scheduleDate = deviceNow.dateOnly;
      var today = await _getPrayerSchedule(
        date: scheduleDate,
        location: currentLocation,
      );

      // The requested calendar day must be the day at the location returned by
      // the API, not an accidentally different day in the device timezone.
      final locationNow = tz.TZDateTime.from(
        deviceNow,
        TimezoneUtils.location(today.timezone),
      );
      final resolvedDate = DateTime(
        locationNow.year,
        locationNow.month,
        locationNow.day,
      );
      if (resolvedDate != scheduleDate) {
        scheduleDate = resolvedDate;
        today = await _getPrayerSchedule(
          date: scheduleDate,
          location: currentLocation,
        );
      }
      final tomorrow = await _getPrayerSchedule(
        date: DateTime(
          scheduleDate.year,
          scheduleDate.month,
          scheduleDate.day + 1,
        ),
        location: currentLocation,
      );

      location.value = currentLocation;
      todaySchedule.value = today;
      tomorrowSchedule.value = tomorrow;

      _loadedDate = scheduleDate;
      status.value = PrayerTimesViewStatus.success;

      _recompute(deviceNow);

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
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[PrayerTime] Refresh failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      errorKey.value = error is AppException
          ? error.localizationKey
          : 'prayer_times_error';

      if (todaySchedule.value == null) {
        status.value = PrayerTimesViewStatus.error;
      }
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> openRelevantSettings() async {
    if (errorKey.value == 'location_services_disabled') {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }

  void _tick() {
    final current = _currentTime();
    now.value = current;
    final today = todaySchedule.value;
    final currentScheduleDate = today == null
        ? current.dateOnly
        : _dateAtScheduleLocation(current, today);
    if (_loadedDate != null && _loadedDate != currentScheduleDate) {
      remaining.value = Duration.zero;
      unawaited(refreshPrayerTimes(showLoading: false));
      return;
    }
    _recompute(current);
  }

  void _recompute(DateTime current) {
    final today = todaySchedule.value;
    if (today == null) return;
    final comparableNow = tz.TZDateTime.from(
      current,
      TimezoneUtils.location(today.timezone),
    );
    final upcoming = today.prayers
        .where((prayer) => prayer.name.isObligatory)
        .where((prayer) => prayer.time.isAfter(comparableNow))
        .firstOrNull;
    final tomorrowFajr = tomorrowSchedule.value?.prayer(PrayerName.fajr);
    final selected =
        upcoming ??
        (tomorrowFajr?.time.isAfter(comparableNow) == true
            ? tomorrowFajr
            : null);
    nextPrayer.value = selected;
    remaining.value = selected == null
        ? Duration.zero
        : selected.time.difference(comparableNow);
    _logState(comparableNow, selected);
  }

  DateTime _dateAtScheduleLocation(DateTime current, PrayerSchedule schedule) {
    final value = tz.TZDateTime.from(
      current,
      TimezoneUtils.location(schedule.timezone),
    );
    return DateTime(value.year, value.month, value.day);
  }

  void _ensureTicker() {
    if (_ticker?.isActive == true) return;
    _ticker?.cancel();
    _ticker = _tickerFactory(const Duration(seconds: 1), (_) => _tick());
  }

  void _cancelTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @visibleForTesting
  void recomputeAt(DateTime current) {
    now.value = current;
    _recompute(current);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final current = _currentTime();
      now.value = current;
      _recompute(current);
      _ensureTicker();
      unawaited(refreshPrayerTimes(showLoading: false));
      return;
    }
    _cancelTicker();
  }

  void _logState(DateTime current, Prayer? selected) {
    if (!kDebugMode) return;
    final remainingMinute = remaining.value.inMinutes;
    if (_lastLoggedPrayer == selected?.name &&
        _lastLoggedMinute == remainingMinute) {
      return;
    }
    _lastLoggedPrayer = selected?.name;
    _lastLoggedMinute = remainingMinute;
    debugPrint(
      '[PrayerTime] now=$current timezone=${todaySchedule.value?.timezone} '
      'next=${selected?.name.name ?? 'none'} '
      'at=${selected?.time.toIso8601String() ?? 'none'} '
      'remaining=${remaining.value}',
    );
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTicker();
    super.onClose();
  }
}
