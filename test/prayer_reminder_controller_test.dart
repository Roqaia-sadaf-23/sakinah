import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/notifications/notification_service.dart';
import 'package:sakinah/core/storage/storage_keys.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/presentation/controllers/prayer_reminder_controller.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_preview_player.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_sound_availability.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_notification_scheduler.dart';
import 'package:sakinah/features/prayer_times/presentation/widgets/prayer_reminder_settings_card.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.locale = const Locale('en');
  });

  tearDown(Get.reset);

  test('enabling and changing sound persist settings', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(
        notifications,
        storage,
        soundAvailability: const _FakeSoundAvailability.all(),
      ),
      notifications,
      null,
      const _FakeSoundAvailability.all(),
    )..onInit();
    await controller.soundAvailabilityReady;

    await controller.setEnabled(true);
    await controller.setAlarmSound(PrayerAlarmSound.jerusalem);

    final persisted = PrayerReminderSettings.fromJson(
      storage.readJson(StorageKeys.prayerReminderSettings),
    );
    expect(persisted.enabled, isTrue);
    expect(persisted.minutesBefore, 5);
    expect(persisted.alarmSound, PrayerAlarmSound.jerusalem);
  });

  test('saved reminder settings are restored on startup', () async {
    final storage = _MemoryStorageService();
    await storage.writeJson(
      StorageKeys.prayerReminderSettings,
      const PrayerReminderSettings(
        enabled: true,
        minutesBefore: 30,
        alarmSound: PrayerAlarmSound.masjidAlHaram,
        notificationPermissionRequested: true,
      ).toJson(),
    );
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      null,
      const _FakeSoundAvailability.all(),
    )..onInit();
    await controller.soundAvailabilityReady;
    addTearDown(controller.onClose);

    expect(controller.isEnabled, isTrue);
    expect(controller.minutesBefore, 30);
    expect(controller.reminderType, PrayerReminderType.takbeer);
    expect(controller.alarmSound, PrayerAlarmSound.masjidAlHaram);
  });

  test('alarm sound selection is saved and restored', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final preview = _FakeAlarmPreviewPlayer();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      preview,
      const _FakeSoundAvailability.all(),
    )..onInit();
    await controller.soundAvailabilityReady;

    await controller.setAlarmSound(PrayerAlarmSound.silent);
    for (final sound in PrayerAlarmSound.values) {
      await controller.previewAlarmSound(sound);
    }
    controller.onClose();

    final restarted = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      _FakeAlarmPreviewPlayer(),
      const _FakeSoundAvailability.all(),
    )..onInit();
    addTearDown(restarted.onClose);

    expect(restarted.alarmSound, PrayerAlarmSound.silent);
    expect(preview.previews, PrayerAlarmSound.values);
    expect(preview.stopCalls, PrayerAlarmSound.values.length);
  });

  test('legacy reminder types migrate to alarm sounds', () {
    expect(
      PrayerReminderSettings.fromJson(const <String, dynamic>{
        'type': 'takbeer',
      }).alarmSound,
      PrayerAlarmSound.systemDefault,
    );
    expect(
      PrayerReminderSettings.fromJson(const <String, dynamic>{
        'type': 'text',
      }).alarmSound,
      PrayerAlarmSound.systemDefault,
    );
    expect(
      PrayerReminderSettings.fromJson(const <String, dynamic>{
        'type': 'takbeer',
        'alarmSound': 'silent',
      }).alarmSound,
      PrayerAlarmSound.silent,
    );
  });

  test('unavailable attributed sound cannot be selected or saved', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      _FakeAlarmPreviewPlayer(),
      const _FakeSoundAvailability.systemOnly(),
    )..onInit();
    addTearDown(controller.onClose);
    await controller.soundAvailabilityReady;

    expect(await controller.setAlarmSound(PrayerAlarmSound.jerusalem), isFalse);
    expect(controller.alarmSound, PrayerAlarmSound.systemDefault);
    expect(
      controller.permissionIssue.value,
      PrayerReminderPermissionIssue.soundFileMissing,
    );
    expect(
      PrayerReminderSettings.fromJson(
        storage.readJson(StorageKeys.prayerReminderSettings),
      ).alarmSound,
      PrayerAlarmSound.systemDefault,
    );
  });

  test('test button schedules the selected silent notification', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();
    addTearDown(controller.onClose);
    await controller.soundAvailabilityReady;
    await controller.setAlarmSound(PrayerAlarmSound.silent);

    expect(
      await controller.scheduleNotificationTest(),
      PrayerNotificationTestResult.scheduled,
    );
    expect(notifications.scheduled, hasLength(1));
    expect(notifications.scheduled.single.playSound, isFalse);
  });

  test('test button reports missing exact-alarm permission', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService()
      ..exactAlarmsEnabled = false;
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
    )..onInit();
    addTearDown(controller.onClose);
    await controller.soundAvailabilityReady;

    expect(
      await controller.scheduleNotificationTest(),
      PrayerNotificationTestResult.exactAlarmDenied,
    );
    expect(notifications.scheduled, isEmpty);
    expect(
      controller.permissionIssue.value,
      PrayerReminderPermissionIssue.exactAlarm,
    );
  });

  test('custom minutes accept 1 to 120 and reject invalid values', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      _FakeAlarmPreviewPlayer(),
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
    final preview = _FakeAlarmPreviewPlayer();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      preview,
    )..onInit();
    addTearDown(controller.onClose);

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
    final preview = _FakeAlarmPreviewPlayer();
    final controller = PrayerReminderController(
      storage,
      PrayerNotificationScheduler(notifications, storage),
      notifications,
      preview,
    )..onInit();
    addTearDown(controller.onClose);

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
    expect(find.text('Alarm Sound'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Jerusalem Adhan'), findsOneWidget);
    expect(find.text('Masjid al-Haram Adhan'), findsOneWidget);
    expect(find.text('Prophet’s Mosque Adhan'), findsOneWidget);
    expect(find.text('Silent'), findsOneWidget);
    expect(
      find.text('Unavailable in this version'),
      findsNWidgets(3),
    );
    expect(find.text('Test selected sound after 10 seconds'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Preview System default'),
      200,
    );
    await tester.tap(find.byTooltip('Preview System default'));
    await tester.pump();
    expect(preview.previews, [PrayerAlarmSound.systemDefault]);
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
          body: SingleChildScrollView(
            child: PrayerReminderSettingsCard(controller: controller),
          ),
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
          body: SingleChildScrollView(
            child: PrayerReminderSettingsCard(controller: controller),
          ),
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
  final scheduled = <LocalNotificationRequest>[];

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
  Future<void> schedule(LocalNotificationRequest request) async {
    scheduled.add(request);
  }
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

class _FakeAlarmPreviewPlayer implements PrayerAlarmPreviewPlayer {
  final previews = <PrayerAlarmSound>[];
  int stopCalls = 0;

  @override
  Future<void> preview(PrayerAlarmSound sound) async => previews.add(sound);

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeSoundAvailability implements PrayerAlarmSoundAvailability {
  const _FakeSoundAvailability.all() : _all = true;
  const _FakeSoundAvailability.systemOnly() : _all = false;

  final bool _all;

  @override
  Future<Set<PrayerAlarmSound>> availableSounds() async => _all
      ? PrayerAlarmSound.values.toSet()
      : {PrayerAlarmSound.systemDefault, PrayerAlarmSound.silent};

  @override
  Future<bool> isAvailable(PrayerAlarmSound sound) async =>
      (await availableSounds()).contains(sound);
}
