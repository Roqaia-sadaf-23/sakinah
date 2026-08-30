import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/notifications/notification_service.dart';
import 'package:sakinah/core/storage/storage_keys.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/presentation/controllers/prayer_reminder_controller.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_notification_scheduler.dart';

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
}

class _FakeNotificationService implements NotificationService {
  bool notificationsEnabled = true;
  bool exactAlarmsEnabled = true;
  int notificationPermissionRequests = 0;

  @override
  Future<void> initialize() async {}

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
