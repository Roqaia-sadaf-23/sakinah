import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/location/location_data.dart';
import 'package:sakinah/core/location/location_service.dart';
import 'package:sakinah/core/routing/app_routes.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/core/theme/theme_controller.dart';
import 'package:sakinah/features/home/presentation/pages/home_page.dart';
import 'package:sakinah/features/home/presentation/widgets/next_prayer_card.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/domain/repositories/prayer_times_repository.dart';
import 'package:sakinah/features/prayer_times/domain/usecases/get_prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/presentation/controllers/prayer_times_controller.dart';
import 'package:sakinah/features/prayer_tracker/domain/repositories/prayer_tracker_repository.dart';
import 'package:sakinah/features/prayer_tracker/presentation/controllers/prayer_tracker_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('HomePage lays out and scrolls on a narrow screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _registerHomeControllers();
    _setSuccessfulSchedule(controller);

    await tester.pumpWidget(_testApp(const HomePage()));
    await tester.pump();

    expect(find.byType(NextPrayerCard), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('NextPrayerCard lays out with unbounded height at wide width', (
    tester,
  ) async {
    final controller = _TestPrayerTimesController(_MemoryStorageService());
    _setSuccessfulSchedule(controller);

    await tester.pumpWidget(
      _testApp(
        SingleChildScrollView(
          child: SizedBox(
            width: 700,
            child: NextPrayerCard(controller: controller),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(NextPrayerCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quran quick action navigates to the configured route', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final controller = _registerHomeControllers();
    _setSuccessfulSchedule(controller);

    await tester.pumpWidget(_testApp(const HomePage()));
    await tester.pump();
    await tester.ensureVisible(find.text('quran'));
    await tester.tap(find.text('quran'));
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.quran);
    expect(find.byKey(const Key('quran-route-probe')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp(Widget home) => GetMaterialApp(
  home: home,
  getPages: [
    GetPage(
      name: AppRoutes.quran,
      page: () => const Scaffold(
        key: Key('quran-route-probe'),
        body: SizedBox.shrink(),
      ),
    ),
  ],
);

_TestPrayerTimesController _registerHomeControllers() {
  final storage = _MemoryStorageService();
  Get.put<ThemeController>(ThemeController(storage));
  final prayerTimesController =
      Get.put<PrayerTimesController>(_TestPrayerTimesController(storage))
          as _TestPrayerTimesController;
  Get.put<PrayerTrackerController>(
    PrayerTrackerController(
      _MemoryPrayerTrackerRepository(),
      prayerTimesController,
    ),
  );
  return prayerTimesController;
}

void _setSuccessfulSchedule(PrayerTimesController controller) {
  final today = DateTime(2026, 8, 30);
  final tomorrow = today.add(const Duration(days: 1));
  final todaySchedule = _schedule(today);
  final tomorrowSchedule = _schedule(tomorrow);
  controller.location.value = LocationData(
    latitude: 24.7136,
    longitude: 46.6753,
    city: 'Riyadh',
    country: 'Saudi Arabia',
    capturedAt: today,
  );
  controller.todaySchedule.value = todaySchedule;
  controller.tomorrowSchedule.value = tomorrowSchedule;
  controller.nextPrayer.value = todaySchedule.prayers.first;
  controller.remaining.value = const Duration(hours: 2, minutes: 15);
  controller.status.value = PrayerTimesViewStatus.success;
}

PrayerSchedule _schedule(DateTime date) => PrayerSchedule(
  date: date,
  prayers: [
    Prayer(
      name: PrayerName.fajr,
      time: DateTime(date.year, date.month, date.day, 5),
    ),
    Prayer(
      name: PrayerName.sunrise,
      time: DateTime(date.year, date.month, date.day, 6, 20),
    ),
    Prayer(
      name: PrayerName.dhuhr,
      time: DateTime(date.year, date.month, date.day, 12, 5),
    ),
    Prayer(
      name: PrayerName.asr,
      time: DateTime(date.year, date.month, date.day, 15, 30),
    ),
    Prayer(
      name: PrayerName.maghrib,
      time: DateTime(date.year, date.month, date.day, 18, 15),
    ),
    Prayer(
      name: PrayerName.isha,
      time: DateTime(date.year, date.month, date.day, 19, 45),
    ),
  ],
  hijriDay: '17',
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
  // The production implementation starts a periodic clock; layout tests do not.
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
  @override
  Set<String> completedFor(DateTime date) => <String>{};

  @override
  Future<void> saveCompleted(DateTime date, Set<String> prayerKeys) async {}
}

class _MemoryStorageService extends StorageService {
  final _strings = <String, String>{};

  @override
  String? readString(String key) => _strings[key];

  @override
  Future<bool> writeString(String key, String value) async {
    _strings[key] = value;
    return true;
  }
}
