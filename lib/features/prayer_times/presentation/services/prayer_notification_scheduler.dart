import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/notifications/notification_ids.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_reminder_settings.dart';
import '../../domain/entities/prayer_schedule.dart';

typedef PrayerReminderNow = tz.TZDateTime Function(tz.Location location);

class PrayerReminderPlan {
  const PrayerReminderPlan({
    required this.id,
    required this.prayerName,
    required this.scheduledDate,
    required this.title,
    required this.body,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
  });

  final int id;
  final PrayerName prayerName;
  final tz.TZDateTime scheduledDate;
  final String title;
  final String body;
  final String channelId;
  final String channelName;
  final String channelDescription;

  LocalNotificationRequest toRequest() => LocalNotificationRequest(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    channelId: channelId,
    channelName: channelName,
    channelDescription: channelDescription,
    payload: 'prayer-reminder:${prayerName.name}',
  );
}

class PrayerNotificationScheduler {
  PrayerNotificationScheduler(
    this._notifications,
    this._storage, {
    PrayerReminderNow? now,
  }) : _now = now ?? tz.TZDateTime.now;

  final NotificationService _notifications;
  final StorageService _storage;
  final PrayerReminderNow _now;

  List<PrayerSchedule> _schedules = const [];
  String _languageCode = 'en';
  Future<void> _operationQueue = Future<void>.value();

  Future<void> updateSchedules({
    required PrayerSchedule today,
    required PrayerSchedule tomorrow,
    required String languageCode,
  }) {
    _schedules = [today, tomorrow];
    _languageCode = languageCode;
    final settings = PrayerReminderSettings.fromJson(
      _storage.readJson(StorageKeys.prayerReminderSettings),
    );
    return _enqueue(() => _reschedule(settings));
  }

  Future<void> settingsChanged(
    PrayerReminderSettings settings, {
    required String languageCode,
  }) {
    _languageCode = languageCode;
    return _enqueue(() => _reschedule(settings));
  }

  Future<void> cancelPrayerReminders() => _enqueue(_cancelStoredIds);

  List<PrayerReminderPlan> buildPlans(
    List<PrayerSchedule> schedules,
    PrayerReminderSettings settings, {
    required String languageCode,
  }) {
    _ensureTimezoneDatabase();
    final plansById = <int, PrayerReminderPlan>{};

    for (final schedule in schedules) {
      final location = _locationFor(schedule.timezone);
      final now = _now(location);

      for (final prayer in schedule.prayers) {
        final slot = _slotFor(prayer.name);
        if (slot == null) continue;

        final prayerTime = tz.TZDateTime(
          location,
          schedule.date.year,
          schedule.date.month,
          schedule.date.day,
          prayer.time.hour,
          prayer.time.minute,
        );
        final reminderTime = prayerTime.subtract(
          Duration(minutes: settings.minutesBefore),
        );
        if (!reminderTime.isAfter(now)) continue;

        final isArabic = languageCode == 'ar';
        final channelId = settings.type == PrayerReminderType.takbeer
            ? 'prayer_reminders_takbeer_v1'
            : 'prayer_reminders_text_v1';
        final id = NotificationIds.prayerReminder(
          date: schedule.date,
          prayerSlot: slot,
        );
        plansById[id] = PrayerReminderPlan(
          id: id,
          prayerName: prayer.name,
          scheduledDate: reminderTime,
          title: isArabic ? 'سكينة' : 'Sakinah',
          body: _bodyFor(
            prayer.name,
            isArabic: isArabic,
            minutes: settings.minutesBefore,
          ),
          channelId: channelId,
          channelName: isArabic ? 'تذكير الصلاة' : 'Prayer Reminders',
          channelDescription: isArabic
              ? 'تنبيهات قبل مواقيت الصلاة'
              : 'Reminders before obligatory prayer times',
        );
      }
    }

    final plans = plansById.values.toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return plans;
  }

  Future<void> _reschedule(PrayerReminderSettings settings) async {
    await _cancelStoredIds();
    if (!settings.enabled || _schedules.isEmpty) return;

    await _notifications.initialize();
    final notificationsEnabled = await _notifications.areNotificationsEnabled();
    final exactAlarmsEnabled = await _notifications
        .canScheduleExactNotifications();
    if (!notificationsEnabled || !exactAlarmsEnabled) return;

    final plans = buildPlans(_schedules, settings, languageCode: _languageCode);
    await _storage.writeJson(StorageKeys.prayerReminderScheduledIds, {
      'ids': plans.map((plan) => plan.id).toList(),
    });

    for (final plan in plans) {
      await _notifications.schedule(plan.toRequest());
    }
  }

  Future<void> _cancelStoredIds() async {
    final stored = _storage.readJson(StorageKeys.prayerReminderScheduledIds);
    final rawIds = stored?['ids'];
    final ids = rawIds is List
        ? rawIds.whereType<num>().map((value) => value.toInt()).toSet()
        : const <int>{};

    for (final id in ids) {
      await _notifications.cancel(id);
    }
    await _storage.writeJson(StorageKeys.prayerReminderScheduledIds, {
      'ids': <int>[],
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _operationQueue.then<void>((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Prayer reminder scheduling failed: $error');
      },
    );
    return result;
  }

  static bool _timezoneDatabaseInitialized = false;

  static void _ensureTimezoneDatabase() {
    if (_timezoneDatabaseInitialized) return;
    tz_data.initializeTimeZones();
    _timezoneDatabaseInitialized = true;
  }

  static tz.Location _locationFor(String timezone) {
    _ensureTimezoneDatabase();
    if (timezone.isEmpty) return tz.local;
    try {
      return tz.getLocation(timezone);
    } on tz.LocationNotFoundException {
      return tz.local;
    }
  }

  static int? _slotFor(PrayerName prayer) => switch (prayer) {
    PrayerName.fajr => 1,
    PrayerName.dhuhr => 2,
    PrayerName.asr => 3,
    PrayerName.maghrib => 4,
    PrayerName.isha => 5,
    PrayerName.sunrise => null,
  };

  static String _bodyFor(
    PrayerName prayer, {
    required bool isArabic,
    required int minutes,
  }) {
    if (isArabic) {
      return switch (prayer) {
        PrayerName.fajr => 'أذان الفجر بعد قليل',
        PrayerName.dhuhr => 'أذان الظهر بعد قليل',
        PrayerName.asr => 'أذان العصر بعد قليل',
        PrayerName.maghrib => 'أذان المغرب بعد قليل',
        PrayerName.isha => 'أذان العشاء بعد قليل',
        PrayerName.sunrise => '',
      };
    }

    final prayerName = switch (prayer) {
      PrayerName.fajr => 'Fajr',
      PrayerName.dhuhr => 'Dhuhr',
      PrayerName.asr => 'Asr',
      PrayerName.maghrib => 'Maghrib',
      PrayerName.isha => 'Isha',
      PrayerName.sunrise => '',
    };
    return '$prayerName prayer is in $minutes minutes';
  }
}
