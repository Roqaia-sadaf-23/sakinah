import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/notifications/notification_ids.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/timezone_utils.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_reminder_settings.dart';
import '../../domain/entities/prayer_schedule.dart';
import 'prayer_alarm_sound_availability.dart';
import 'prayer_alarm_sound_config.dart';

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
    this.androidSoundResource,
    this.playSound = true,
  });

  final int id;
  final PrayerName prayerName;
  final tz.TZDateTime scheduledDate;
  final String title;
  final String body;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String? androidSoundResource;
  final bool playSound;

  LocalNotificationRequest toRequest() => LocalNotificationRequest(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    channelId: channelId,
    channelName: channelName,
    channelDescription: channelDescription,
    payload: 'prayer-reminder:${prayerName.name}',
    androidSoundResource: androidSoundResource,
    playSound: playSound,
  );
}

class PrayerNotificationScheduler {
  PrayerNotificationScheduler(
    this._notifications,
    this._storage, {
    PrayerReminderNow? now,
    PrayerAlarmSoundAvailability? soundAvailability,
  }) : _now = now ?? tz.TZDateTime.now,
       _soundAvailability =
           soundAvailability ?? BundledPrayerAlarmSoundAvailability();

  final NotificationService _notifications;
  final StorageService _storage;
  final PrayerReminderNow _now;
  final PrayerAlarmSoundAvailability _soundAvailability;

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

  Future<void> scheduleSoundTest(
    PrayerAlarmSound sound, {
    required String languageCode,
  }) {
    return _enqueue(() async {
      await _ensureSoundAvailable(sound);
      await _notifications.initialize();
      final timezone = await _notifications.refreshLocalTimezone();
      final scheduledDate = _now(
        TimezoneUtils.location(timezone),
      ).add(const Duration(seconds: 10));
      final config = sound.config;
      await _notifications.schedule(
        LocalNotificationRequest(
          id: 900000001,
          title: languageCode == 'ar' ? 'سكينة' : 'Sakinah',
          body: languageCode == 'ar'
              ? 'اختبار صوت تذكير الصلاة'
              : 'Prayer reminder sound test',
          scheduledDate: scheduledDate,
          channelId: config.channelId,
          channelName: config.channelName,
          channelDescription: config.channelDescription,
          payload: 'prayer-reminder:sound-test',
          androidSoundResource: config.androidResource,
          playSound: config.playSound,
        ),
      );
      debugPrint(
        '[PrayerNotification] Scheduled sound test '
        'id=900000001 at=$scheduledDate '
        'channel=${config.channelId}',
      );
    });
  }

  List<PrayerReminderPlan> buildPlans(
    List<PrayerSchedule> schedules,
    PrayerReminderSettings settings, {
    required String languageCode,
  }) {
    TimezoneUtils.ensureInitialized();
    final plansById = <int, PrayerReminderPlan>{};

    for (final schedule in schedules) {
      final location = TimezoneUtils.location(schedule.timezone);
      final now = _now(location);

      for (final prayer in schedule.prayers) {
        final slot = _slotFor(prayer.name);
        if (slot == null) continue;

        final prayerTime = TimezoneUtils.atWallClock(
          location: location,
          date: schedule.date,
          hour: prayer.time.hour,
          minute: prayer.time.minute,
        );
        final reminderTime = prayerTime.subtract(
          Duration(minutes: settings.minutesBefore),
        );
        if (!reminderTime.isAfter(now)) continue;

        final isArabic = languageCode == 'ar';
        final sound = settings.alarmSound;
        final soundConfig = sound.config;
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
          channelId: soundConfig.channelId,
          channelName: soundConfig.channelName,
          channelDescription: soundConfig.channelDescription,
          androidSoundResource: soundConfig.androidResource,
          playSound: soundConfig.playSound,
        );
      }
    }

    final plans = plansById.values.toList()
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return plans;
  }

  Future<void> _reschedule(PrayerReminderSettings settings) async {
    if (!settings.enabled) {
      await _cancelStoredIds();
      return;
    }

    // A settings interaction can happen while prayer times are still loading.
    // Keep the OS-owned reminders until replacement schedules are available.
    if (_schedules.isEmpty) return;

    await _ensureSoundAvailable(settings.alarmSound);

    await _notifications.initialize();
    await _notifications.refreshLocalTimezone();
    final notificationsEnabled = await _notifications.areNotificationsEnabled();
    final exactSchedulingAvailable = await _notifications
        .canScheduleExactNotifications();
    if (kDebugMode) {
      debugPrint(
        '[PrayerNotification] notificationsEnabled=$notificationsEnabled '
        'exactSchedulingAvailable=$exactSchedulingAvailable',
      );
    }
    if (!notificationsEnabled) return;

    final plans = buildPlans(_schedules, settings, languageCode: _languageCode);
    final oldIds = _storedIds();
    final scheduledIds = <int>[];
    Object? firstFailure;
    StackTrace? firstFailureStack;
    for (final plan in plans) {
      try {
        await _notifications.schedule(plan.toRequest());
        scheduledIds.add(plan.id);
        if (kDebugMode) {
          debugPrint(
            '[PrayerNotification] Scheduled ${plan.prayerName.name} '
            'id=${plan.id} at=${plan.scheduledDate} '
            'timezone=${plan.scheduledDate.location.name}',
          );
        }
      } catch (error, stackTrace) {
        firstFailure ??= error;
        firstFailureStack ??= stackTrace;
        if (kDebugMode) {
          debugPrint(
            '[PrayerNotification] Scheduling failed for '
            '${plan.prayerName.name} at=${plan.scheduledDate}: $error',
          );
        }
      }
    }
    if (firstFailure != null) {
      // Some same-ID requests may already have been replaced. Keep the union
      // so every old or new request remains manageable on the next attempt.
      await _writeStoredIds({...oldIds, ...scheduledIds});
      Error.throwWithStackTrace(firstFailure, firstFailureStack!);
    }

    // Scheduling with a stable ID replaces that prayer's pending request
    // without creating a duplicate. Only stale IDs are cancelled, and only
    // after all replacement requests have succeeded.
    final replacementIds = scheduledIds.toSet();
    for (final staleId in oldIds.difference(replacementIds)) {
      await _notifications.cancel(staleId);
    }
    await _writeStoredIds(replacementIds);
  }

  Set<int> _storedIds() {
    final stored = _storage.readJson(StorageKeys.prayerReminderScheduledIds);
    final rawIds = stored?['ids'];
    return rawIds is List
        ? rawIds.whereType<num>().map((value) => value.toInt()).toSet()
        : <int>{};
  }

  Future<void> _writeStoredIds(Set<int> ids) => _storage.writeJson(
    StorageKeys.prayerReminderScheduledIds,
    {'ids': ids.toList()..sort()},
  );

  Future<void> _ensureSoundAvailable(PrayerAlarmSound sound) async {
    if (!await _soundAvailability.isAvailable(sound)) {
      throw PrayerAlarmSoundUnavailableException(sound);
    }
  }

  Future<void> _cancelStoredIds() async {
    for (final id in _storedIds()) {
      await _notifications.cancel(id);
    }
    await _writeStoredIds(<int>{});
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
