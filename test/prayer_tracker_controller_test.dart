import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/location/location_data.dart';
import 'package:sakinah/core/location/location_service.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/home/presentation/widgets/prayer_tracker_card.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:sakinah/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/presentation/controllers/prayer_times_controller.dart';
import 'package:sakinah/features/prayer_tracker/domain/repositories/prayer_tracker_repository.dart';
import 'package:sakinah/features/prayer_tracker/presentation/controllers/prayer_tracker_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  test('prayer becomes available exactly when its prayer time starts', () {
    final harness = _Harness(DateTime(2026, 8, 31, 12, 19));

    expect(harness.tracker.canMarkPrayer(PrayerName.dhuhr), isFalse);

    harness.times.now.value = DateTime(2026, 8, 31, 12, 20);
    expect(harness.tracker.canMarkPrayer(PrayerName.dhuhr), isTrue);

    harness.times.now.value = DateTime(2026, 8, 31, 13);
    expect(harness.tracker.canMarkPrayer(PrayerName.dhuhr), isTrue);
  });

  test(
    'later available prayer is not blocked by an incomplete prayer',
    () async {
      final harness = _Harness(DateTime(2026, 8, 31, 13));

      expect(harness.tracker.isCompleted(PrayerName.fajr), isFalse);
      expect(harness.tracker.canMarkPrayer(PrayerName.dhuhr), isTrue);
      expect(harness.tracker.canMarkPrayer(PrayerName.asr), isFalse);

      await harness.tracker.toggle(PrayerName.dhuhr);

      expect(harness.tracker.isCompleted(PrayerName.fajr), isFalse);
      expect(harness.tracker.isCompleted(PrayerName.dhuhr), isTrue);
    },
  );

  test('future prayer cannot be completed programmatically', () async {
    final harness = _Harness(DateTime(2026, 8, 31, 13));

    await harness.tracker.toggle(PrayerName.asr);

    expect(harness.tracker.isCompleted(PrayerName.asr), isFalse);
    expect(harness.repository.saveCount, 0);
  });

  test('completed state persists when the tracker is reopened', () async {
    final repository = _MemoryPrayerTrackerRepository();
    final harness = _Harness(DateTime(2026, 8, 31, 13), repository: repository);
    await harness.tracker.toggle(PrayerName.dhuhr);

    Get.delete<PrayerTrackerController>();
    final reopened = Get.put(
      PrayerTrackerController(repository, harness.times),
    );

    expect(reopened.isCompleted(PrayerName.dhuhr), isTrue);
  });

  test(
    'day change resets completion and waits for the new Fajr time',
    () async {
      final firstDay = DateTime(2026, 8, 31, 21);
      final harness = _Harness(firstDay);
      await harness.tracker.toggle(PrayerName.isha);
      expect(harness.tracker.isCompleted(PrayerName.isha), isTrue);

      harness.times.now.value = DateTime(2026, 9, 1);

      expect(harness.tracker.completed, isEmpty);
      expect(harness.tracker.canMarkPrayer(PrayerName.fajr), isFalse);

      harness.times.todaySchedule.value = _schedule(DateTime(2026, 9, 1));
      harness.times.now.value = DateTime(2026, 9, 1, 4, 59);
      expect(harness.tracker.canMarkPrayer(PrayerName.fajr), isFalse);

      harness.times.now.value = DateTime(2026, 9, 1, 5, 10);
      expect(harness.tracker.canMarkPrayer(PrayerName.fajr), isTrue);
    },
  );

  testWidgets('tracker UI unlocks a prayer when its time arrives', (
    tester,
  ) async {
    final harness = _Harness(DateTime(2026, 8, 31, 12, 19));
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: PrayerTrackerCard(controller: harness.tracker)),
      ),
    );

    expect(find.byIcon(Icons.lock_clock_rounded), findsNWidgets(4));
    await tester.tap(find.text('dhuhr'));
    await tester.pump();
    expect(harness.tracker.isCompleted(PrayerName.dhuhr), isFalse);

    harness.times.now.value = DateTime(2026, 8, 31, 12, 20);
    await tester.pump();

    expect(find.byIcon(Icons.lock_clock_rounded), findsNWidgets(3));
    await tester.tap(find.text('dhuhr'));
    await tester.pump();
    expect(harness.tracker.isCompleted(PrayerName.dhuhr), isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _Harness {
  _Harness(DateTime now, {_MemoryPrayerTrackerRepository? repository})
    : repository = repository ?? _MemoryPrayerTrackerRepository() {
    times =
        Get.put<PrayerTimesController>(
              _TestPrayerTimesController(_MemoryStorageService()),
            )
            as _TestPrayerTimesController;
    times.now.value = now;
    times.todaySchedule.value = _schedule(
      DateTime(now.year, now.month, now.day),
    );
    tracker = Get.put(PrayerTrackerController(this.repository, times));
  }

  final _MemoryPrayerTrackerRepository repository;
  late final _TestPrayerTimesController times;
  late final PrayerTrackerController tracker;
}

PrayerSchedule _schedule(DateTime date) => PrayerSchedule(
  date: date,
  prayers: [
    Prayer(
      name: PrayerName.fajr,
      time: DateTime(date.year, date.month, date.day, 5, 10),
    ),
    Prayer(
      name: PrayerName.sunrise,
      time: DateTime(date.year, date.month, date.day, 6, 30),
    ),
    Prayer(
      name: PrayerName.dhuhr,
      time: DateTime(date.year, date.month, date.day, 12, 20),
    ),
    Prayer(
      name: PrayerName.asr,
      time: DateTime(date.year, date.month, date.day, 15, 45),
    ),
    Prayer(
      name: PrayerName.maghrib,
      time: DateTime(date.year, date.month, date.day, 18, 40),
    ),
    Prayer(
      name: PrayerName.isha,
      time: DateTime(date.year, date.month, date.day, 20, 10),
    ),
  ],
  hijriDay: '18',
  hijriMonthEnglish: 'Rabi al-Awwal',
  hijriMonthArabic: 'ربيع الأول',
  hijriYear: '1448',
  timezone: 'Asia/Riyadh',
);

class _TestPrayerTimesController extends PrayerTimesController {
  _TestPrayerTimesController(StorageService storage)
    : super(
        LocationService(storage),
        GetPrayerSchedule(_UnusedPrayerTimesRepository()),
      );

  @override
  // Unit tests drive the reactive clock directly, so no timer is started.
  // ignore: must_call_super, unnecessary_overrides
  void onInit() {}

  @override
  void onReady() {}
}

class _UnusedPrayerTimesRepository implements PrayerTimesRepository {
  @override
  Future<PrayerSchedule> getSchedule({
    required DateTime date,
    required LocationData location,
  }) => throw UnimplementedError();
}

class _MemoryPrayerTrackerRepository implements PrayerTrackerRepository {
  final _values = <String, Set<String>>{};
  int saveCount = 0;

  @override
  Set<String> completedFor(DateTime date) =>
      Set<String>.from(_values[_key(date)] ?? const <String>{});

  @override
  Future<void> saveCompleted(DateTime date, Set<String> prayerKeys) async {
    saveCount++;
    _values[_key(date)] = Set<String>.from(prayerKeys);
  }

  String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';
}

class _MemoryStorageService extends StorageService {
  @override
  String? readString(String key) => null;

  @override
  Future<bool> writeString(String key, String value) async => true;
}
