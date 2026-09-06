import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/notifications/notification_service.dart';
import 'package:sakinah/core/storage/storage_keys.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/presentation/controllers/prayer_reminder_controller.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_notification_scheduler.dart';
import 'package:sakinah/features/prayer_times/presentation/widgets/prayer_reminder_settings_card.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.locale = const Locale('en');
  });

  tearDown(Get.reset);

  test('enabling and changing type persist settings', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();

    await controller.setEnabled(true);
    await controller.setReminderType(PrayerReminderType.takbeer);

    final persisted = PrayerReminderSettings.fromJson(
      storage.readJson(StorageKeys.prayerReminderSettings),
    );
    expect(persisted.enabled, isTrue);
    expect(persisted.minutesBefore, 5);
    expect(persisted.type, PrayerReminderType.takbeer);
  });

  test('saved reminder settings are restored on startup', () async {
    final storage = _MemoryStorageService();
    await storage.writeJson(
      StorageKeys.prayerReminderSettings,
      const PrayerReminderSettings(
        enabled: true,
        minutesBefore: 30,
        type: PrayerReminderType.takbeer,
        notificationPermissionRequested: true,
      ).toJson(),
    );
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();
    addTearDown(controller.onClose);

    expect(controller.isEnabled, isTrue);
    expect(controller.minutesBefore, 30);
    expect(controller.reminderType, PrayerReminderType.takbeer);
  });

  test('custom minutes accept 1 to 120 and reject invalid values', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();
    addTearDown(controller.onClose);

    expect(await controller.setMinutesBefore(1), isTrue);
    expect(controller.minutesBefore, 1);
    expect(await controller.setMinutesBefore(120), isTrue);
    expect(controller.minutesBefore, 120);
    expect(await controller.setMinutesBefore(0), isFalse);
    expect(await controller.setMinutesBefore(-10), isFalse);
    expect(await controller.setMinutesBefore(121), isFalse);
    expect(controller.minutesBefore, 120);

    final restored = PrayerReminderSettings.fromJson(
      storage.readJson(StorageKeys.prayerReminderSettings),
    );
    expect(restored.minutesBefore, 120);
  });

  test('denied notification permission is not requested repeatedly', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService()
      ..notificationsEnabled = false;
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();

    await controller.setEnabled(true);
    await controller.setEnabled(true);

    expect(notifications.notificationPermissionRequests, 1);
    expect(controller.isEnabled, isFalse);
    expect(
      controller.permissionIssue.value,
      PrayerReminderPermissionIssue.notifications,
    );
  });

  test(
    'exact alarm denial keeps reminders enabled with fallback state',
    () async {
      final storage = _MemoryStorageService();
      final notifications = _FakeNotificationService()
        ..exactAlarmsEnabled = false;
      final controller = PrayerReminderController(
        storage,
        PrayerNotificationScheduler(notifications, storage),
        notifications,
      )..onInit();
      addTearDown(controller.onClose);

      await controller.setEnabled(true);

      expect(controller.isEnabled, isTrue);
      expect(
        controller.permissionIssue.value,
        PrayerReminderPermissionIssue.exactAlarm,
      );
      expect(
        PrayerReminderSettings.fromJson(
          storage.readJson(StorageKeys.prayerReminderSettings),
        ).enabled,
        isTrue,
      );
    },
  );

  testWidgets('settings card is constraint-safe on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: PrayerReminderSettingsCard(controller: controller),
          ),
        ),
      ),
    );

    expect(find.text('Prayer reminders'), findsOneWidget);
    expect(find.text('Takbeer'), findsOneWidget);
    expect(find.text('Text notification'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reminder time sheet updates the card immediately', (
    tester,
  ) async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();
    addTearDown(controller.onClose);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: Scaffold(
          body: PrayerReminderSettingsCard(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();

    expect(find.text('15 minutes before Adhan'), findsOneWidget);
    expect(controller.minutesBefore, 15);
    expect(
      PrayerReminderSettings.fromJson(
        storage.readJson(StorageKeys.prayerReminderSettings),
      ).minutesBefore,
      15,
    );
  });

  testWidgets('custom reminder time rejects values outside 1 to 120', (
    tester,
  ) async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();
    addTearDown(controller.onClose);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en'),
        home: Scaffold(
          body: PrayerReminderSettingsCard(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('Reminder time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Enter a whole number from 1 to 120.'), findsOneWidget);
    expect(controller.minutesBefore, 5);
  });
}

class _FakeNotificationService implements NotificationService {
  bool notificationsEnabled = true;
  bool exactAlarmsEnabled = true;
  int notificationPermissionRequests = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> refreshLocalTimezone() async => 'UTC';

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool> canScheduleExactNotifications() async => exactAlarmsEnabled;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<bool> openAppNotificationSettings() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => exactAlarmsEnabled;

  @override
  Future<NotificationPermissionState> requestNotificationPermission() async {
    notificationPermissionRequests++;
    return notificationsEnabled
        ? NotificationPermissionState.granted
        : NotificationPermissionState.denied;
  }

  @override
  Future<void> schedule(LocalNotificationRequest request) async {}
}

class _MemoryStorageService extends StorageService {
  final _json = <String, Map<String, dynamic>>{};

  @override
  Map<String, dynamic>? readJson(String key) => _json[key];

  @override
  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    _json[key] = value;
    return true;
  }
}
