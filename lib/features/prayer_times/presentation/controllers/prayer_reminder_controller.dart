import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/prayer_reminder_settings.dart';
import '../services/prayer_alarm_preview_player.dart';
import '../services/prayer_notification_scheduler.dart';

enum PrayerReminderPermissionIssue { notifications, exactAlarm, scheduling }

class PrayerReminderController extends GetxController
    with WidgetsBindingObserver {
  PrayerReminderController(
    this._storage,
    this._scheduler,
    this._notifications, [
    PrayerAlarmPreviewPlayer? previewPlayer,
  ]) : _previewPlayer = previewPlayer;

  final StorageService _storage;
  final PrayerNotificationScheduler _scheduler;
  final NotificationService _notifications;
  PrayerAlarmPreviewPlayer? _previewPlayer;

  final settings = PrayerReminderSettings.defaults.obs;
  final isBusy = false.obs;
  final permissionIssue = Rxn<PrayerReminderPermissionIssue>();
  final previewingSound = Rxn<PrayerAlarmSound>();

  bool get isEnabled => settings.value.enabled;
  int get minutesBefore => settings.value.minutesBefore;
  PrayerReminderType get reminderType => settings.value.type;
  PrayerAlarmSound get alarmSound => settings.value.alarmSound;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
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
      }

      nextSettings = nextSettings.copyWith(enabled: true);
      await _save(nextSettings);
      await _scheduler.settingsChanged(
        nextSettings,
        languageCode: Get.locale?.languageCode ?? 'en',
      );
    } catch (_) {
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> setReminderType(PrayerReminderType type) async {
    await setAlarmSound(
      type == PrayerReminderType.takbeer
          ? PrayerAlarmSound.takbeer
          : PrayerAlarmSound.systemDefault,
    );
  }

  Future<void> setAlarmSound(PrayerAlarmSound sound) async {
    if (isBusy.value || settings.value.alarmSound == sound) return;
    isBusy.value = true;
    permissionIssue.value = null;
    try {
      final updated = settings.value.copyWith(alarmSound: sound);
      await _save(updated);
      if (updated.enabled) {
        await _scheduler.settingsChanged(
          updated,
          languageCode: Get.locale?.languageCode ?? 'en',
        );
      }
    } catch (_) {
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> previewAlarmSound(PrayerAlarmSound sound) async {
    if (previewingSound.value != null) return false;
    previewingSound.value = sound;
    try {
      final player = _previewPlayer ??= JustAudioPrayerAlarmPreviewPlayer();
      await player.preview(sound);
      return true;
    } catch (error, stackTrace) {
      debugPrint('[PrayerNotification] Sound preview failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    } finally {
      previewingSound.value = null;
    }
  }

  Future<bool> setMinutesBefore(int minutes) async {
    if (!PrayerReminderSettings.isValidMinutes(minutes)) return false;
    if (isBusy.value) return false;
    if (settings.value.minutesBefore == minutes) return true;

    isBusy.value = true;
    permissionIssue.value = null;
    try {
      final updated = settings.value.copyWith(minutesBefore: minutes);
      await _save(updated);
      if (updated.enabled) {
        await _scheduler.settingsChanged(
          updated,
          languageCode: Get.locale?.languageCode ?? 'en',
        );
      }
      return true;
    } catch (_) {
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
      return false;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !settings.value.enabled) return;
    unawaited(_refreshAfterResume());
  }

  Future<void> _refreshAfterResume() async {
    try {
      await refreshPermissionState();
      if (permissionIssue.value ==
          PrayerReminderPermissionIssue.notifications) {
        return;
      }
      await _scheduler.settingsChanged(
        settings.value,
        languageCode: Get.locale?.languageCode ?? 'en',
      );
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

  Future<bool> scheduleDebugTakbeerTest() async {
    if (!kDebugMode || isBusy.value) return false;
    isBusy.value = true;
    permissionIssue.value = null;
    try {
      var notificationsAllowed = await _notifications.areNotificationsEnabled();
      if (!notificationsAllowed) {
        final result = await _notifications.requestNotificationPermission();
        notificationsAllowed = result == NotificationPermissionState.granted;
      }
      if (!notificationsAllowed) {
        permissionIssue.value = PrayerReminderPermissionIssue.notifications;
        return false;
      }

      await _scheduler.scheduleDebugTakbeerTest();
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[PrayerNotification] Debug Takbeer test failed: $error\n$stackTrace',
      );
      permissionIssue.value = PrayerReminderPermissionIssue.scheduling;
      return false;
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

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    final previewPlayer = _previewPlayer;
    if (previewPlayer != null) unawaited(previewPlayer.dispose());
    super.onClose();
  }
}
