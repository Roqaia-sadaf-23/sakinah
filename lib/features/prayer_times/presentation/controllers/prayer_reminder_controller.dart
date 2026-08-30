import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/prayer_reminder_settings.dart';
import '../services/prayer_notification_scheduler.dart';

enum PrayerReminderPermissionIssue { notifications, exactAlarm, scheduling }

class PrayerReminderController extends GetxController {
  PrayerReminderController(this._storage, this._scheduler, this._notifications);

  final StorageService _storage;
  final PrayerNotificationScheduler _scheduler;
  final NotificationService _notifications;

  final settings = PrayerReminderSettings.defaults.obs;
  final isBusy = false.obs;
  final permissionIssue = Rxn<PrayerReminderPermissionIssue>();

  bool get isEnabled => settings.value.enabled;
  int get minutesBefore => settings.value.minutesBefore;
  PrayerReminderType get reminderType => settings.value.type;

  @override
  void onInit() {
    super.onInit();
    settings.value = PrayerReminderSettings.fromJson(
      _storage.readJson(StorageKeys.prayerReminderSettings),
    );
    if (settings.value.enabled) {
      unawaited(refreshPermissionState());
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (isBusy.value || enabled == settings.value.enabled) return;
    isBusy.value = true;
    permissionIssue.value = null;

    try {
      if (!enabled) {
        await _save(settings.value.copyWith(enabled: false));
        await _scheduler.cancelPrayerReminders();
        return;
      }

      var notificationsAllowed = await _notifications.areNotificationsEnabled();
      var nextSettings = settings.value;
      if (!notificationsAllowed &&
          !nextSettings.notificationPermissionRequested) {
        final result = await _notifications.requestNotificationPermission();
        nextSettings = nextSettings.copyWith(
          notificationPermissionRequested: true,
        );
        notificationsAllowed = result == NotificationPermissionState.granted;
      }
      if (!notificationsAllowed) {
        permissionIssue.value = PrayerReminderPermissionIssue.notifications;
        await _save(nextSettings.copyWith(enabled: false));
        return;
      }

      var exactAlarmsAllowed = await _notifications
          .canScheduleExactNotifications();
      if (!exactAlarmsAllowed && !nextSettings.exactAlarmPermissionRequested) {
        exactAlarmsAllowed = await _notifications.requestExactAlarmPermission();
        nextSettings = nextSettings.copyWith(
          exactAlarmPermissionRequested: true,
        );
      }
      if (!exactAlarmsAllowed) {
        permissionIssue.value = PrayerReminderPermissionIssue.exactAlarm;
        await _save(nextSettings.copyWith(enabled: false));
        return;
      }

      nextSettings = nextSettings.copyWith(enabled: true);
      await _save(nextSettings);
      await _scheduler.settingsChanged(
        nextSettings,
        languageCode: Get.locale?.languageCode ?? 'en',
      );
    } catch (_) {
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
      await _save(settings.value.copyWith(enabled: false));
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> setReminderType(PrayerReminderType type) async {
    if (isBusy.value || settings.value.type == type) return;
    isBusy.value = true;
    permissionIssue.value = null;
    try {
      final updated = settings.value.copyWith(type: type);
      await _save(updated);
      await _scheduler.settingsChanged(
        updated,
        languageCode: Get.locale?.languageCode ?? 'en',
      );
    } catch (_) {
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> refreshPermissionState() async {
    try {
      final notificationsAllowed = await _notifications
          .areNotificationsEnabled();
      if (!notificationsAllowed) {
        permissionIssue.value = PrayerReminderPermissionIssue.notifications;
        return;
      }
      final exactAlarmsAllowed = await _notifications
          .canScheduleExactNotifications();
      permissionIssue.value = exactAlarmsAllowed
          ? null
          : PrayerReminderPermissionIssue.exactAlarm;
    } catch (_) {
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
    }
  }

  Future<void> openRelevantSettings() async {
    isBusy.value = true;
    try {
      if (permissionIssue.value == PrayerReminderPermissionIssue.exactAlarm) {
        await _notifications.requestExactAlarmPermission();
      } else {
        await _notifications.openAppNotificationSettings();
      }
      await refreshPermissionState();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> _save(PrayerReminderSettings value) async {
    settings.value = value;
    await _storage.writeJson(
      StorageKeys.prayerReminderSettings,
      value.toJson(),
    );
  }
}
