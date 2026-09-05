import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/location/location_data.dart';
import 'package:sakinah/core/location/location_service.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/core/utils/timezone_utils.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:sakinah/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/presentation/controllers/prayer_times_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrayerTimesController next prayer', () {
    late PrayerTimesController controller;

    setUp(() {
      controller = _controller();
      controller.todaySchedule.value = _schedule(DateTime(2026, 8, 30));
      controller.tomorrowSchedule.value = _schedule(DateTime(2026, 8, 31));
    });

    tearDown(() => controller.onClose());

    test('selects the next obligatory prayer during the day', () {
      controller.recomputeAt(DateTime.utc(2026, 8, 30, 13));

      expect(controller.nextPrayer.value?.name, PrayerName.asr);
      expect(controller.remaining.value, const Duration(hours: 2, minutes: 30));
    });

    test('moves to the following prayer exactly when one begins', () {
      controller.recomputeAt(DateTime.utc(2026, 8, 30, 12));

      expect(controller.nextPrayer.value?.name, PrayerName.asr);
    });

    test('after Isha selects tomorrow Fajr', () {
      controller.recomputeAt(DateTime.utc(2026, 8, 30, 21));

      expect(controller.nextPrayer.value?.name, PrayerName.fajr);
      expect(controller.nextPrayer.value?.time, DateTime.utc(2026, 8, 31, 5));
    });

    test('compares API prayer time and now on one timezone-safe timeline', () {
      final riyadh = TimezoneUtils.location('Asia/Riyadh');
      controller.todaySchedule.value = _schedule(
        DateTime(2026, 8, 30),
        timezone: 'Asia/Riyadh',
        prayers: [
          Prayer(
            name: PrayerName.fajr,
            time: TimezoneUtils.atWallClock(
              location: riyadh,
              date: DateTime(2026, 8, 30),
              hour: 4,
              minute: 28,
            ),
          ),
        ],
      );

      controller.recomputeAt(DateTime.utc(2026, 8, 30, 1));

      expect(riyadh.name, 'Asia/Riyadh');
      expect(controller.nextPrayer.value?.name, PrayerName.fajr);
      expect(controller.remaining.value, const Duration(minutes: 28));
    });
  });

  test('resume immediately recomputes countdown from current wall time', () {
    var current = DateTime.utc(2026, 8, 30, 13);
    final controller = _controller(currentTime: () => current);
    controller.todaySchedule.value = _schedule(DateTime(2026, 8, 30));
    controller.tomorrowSchedule.value = _schedule(DateTime(2026, 8, 31));
    controller.recomputeAt(current);
    expect(controller.remaining.value, const Duration(hours: 2, minutes: 30));

    current = DateTime.utc(2026, 8, 30, 14);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(controller.remaining.value, const Duration(hours: 1, minutes: 30));
    controller.onClose();
  });

  test('lifecycle changes never leave duplicate ticker timers', () {
    final timers = <_TrackingTimer>[];
    final controller = _controller(
      tickerFactory: (duration, callback) {
        final timer = _TrackingTimer();
        timers.add(timer);
        return timer;
      },
    );

    controller.onInit();
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(timers.where((timer) => timer.isActive), hasLength(1));
    expect(timers, hasLength(1));

    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(timers.where((timer) => timer.isActive), hasLength(1));
    expect(timers, hasLength(2));

    controller.onClose();
    expect(timers.where((timer) => timer.isActive), isEmpty);
  });
}

PrayerTimesController _controller({
  PrayerTimesNow? currentTime,
  PrayerTickerFactory? tickerFactory,
}) {
  final storage = _MemoryStorageService();
  final location = LocationData(
    latitude: 24.7136,
    longitude: 46.6753,
    city: 'Riyadh',
    country: 'Saudi Arabia',
    capturedAt: DateTime(2026, 8, 30),
  );
  final repository = _FakePrayerTimesRepository();
  return PrayerTimesController(
    _FakeLocationService(storage, location),
    GetPrayerSchedule(repository),
    null,
    currentTime,
    tickerFactory,
  );
}

PrayerSchedule _schedule(
  DateTime date, {
  String timezone = 'UTC',
  List<Prayer>? prayers,
}) => PrayerSchedule(
  date: date,
  prayers:
      prayers ??
      [
        Prayer(
          name: PrayerName.fajr,
          time: DateTime.utc(date.year, date.month, date.day, 5),
        ),
        Prayer(
          name: PrayerName.sunrise,
          time: DateTime.utc(date.year, date.month, date.day, 6),
        ),
        Prayer(
          name: PrayerName.dhuhr,
          time: DateTime.utc(date.year, date.month, date.day, 12),
        ),
        Prayer(
          name: PrayerName.asr,
          time: DateTime.utc(date.year, date.month, date.day, 15, 30),
        ),
        Prayer(
          name: PrayerName.maghrib,
          time: DateTime.utc(date.year, date.month, date.day, 18, 30),
        ),
        Prayer(
          name: PrayerName.isha,
          time: DateTime.utc(date.year, date.month, date.day, 20),
        ),
      ],
  hijriDay: '17',
  hijriMonthEnglish: 'Rabi al-Awwal',
  hijriMonthArabic: 'ربيع الأول',
  hijriYear: '1448',
  timezone: timezone,
);

class _FakeLocationService extends LocationService {
  _FakeLocationService(super.storage, this.value);

  final LocationData value;

  @override
  Future<LocationData> getCurrentLocation() async => value;
}

class _FakePrayerTimesRepository implements PrayerTimesRepository {
  @override
  Future<PrayerSchedule> getSchedule({
    required DateTime date,
    required LocationData location,
  }) async => _schedule(date);
}

class _MemoryStorageService extends StorageService {}

class _TrackingTimer implements Timer {
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() => _active = false;
}
