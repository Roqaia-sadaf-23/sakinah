import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/notifications/notification_ids.dart';
import 'package:sakinah/core/notifications/notification_service.dart';
import 'package:sakinah/core/storage/storage_keys.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_notification_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('PrayerNotificationScheduler planning', () {
    test('schedules a prayer exactly five minutes before its time', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18),
      );
      final plans = scheduler.buildPlans(
        [
          _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 42)]),
        ],
        const PrayerReminderSettings(enabled: true),
        languageCode: 'en',
      );

      expect(plans, hasLength(1));
      expect(plans.single.scheduledDate.hour, 18);
      expect(plans.single.scheduledDate.minute, 37);
      expect(plans.single.body, 'Maghrib prayer is in 5 minutes');
      expect(plans.single.id, 202608304);
    });

    test('does not schedule a reminder whose time has passed', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18, 40),
      );
      final plans = scheduler.buildPlans(
        [
          _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 42)]),
        ],
        const PrayerReminderSettings(enabled: true),
        languageCode: 'en',
      );

      expect(plans, isEmpty);
    });

    test('supports only the five obligatory prayers with stable IDs', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30),
      );
      final plans = scheduler.buildPlans(
        [
          _schedule(
            prayers: [
              _prayer(PrayerName.fajr, 5, 10),
              _prayer(PrayerName.sunrise, 6, 30),
              _prayer(PrayerName.dhuhr, 12, 20),
              _prayer(PrayerName.asr, 15, 45),
              _prayer(PrayerName.maghrib, 18, 42),
              _prayer(PrayerName.isha, 20, 12),
            ],
          ),
        ],
        const PrayerReminderSettings(enabled: true),
        languageCode: 'ar',
      );

      expect(plans, hasLength(5));
      expect(plans.map((plan) => plan.id), [
        202608301,
        202608302,
        202608303,
        202608304,
        202608305,
      ]);
      expect(plans.first.body, 'أذان الفجر بعد قليل');
      expect(plans.last.body, 'أذان العشاء بعد قليل');
    });

    test('notification ID depends only on date and prayer slot', () {
      expect(
        NotificationIds.prayerReminder(
          date: DateTime(2026, 8, 30),
          prayerSlot: 4,
        ),
        202608304,
      );
    });
  });

  test(
    'rescheduling replaces prayer reminders and disabling cancels them',
    () async {
      final storage = _MemoryStorageService();
      final notifications = _FakeNotificationService();
      final scheduler = PrayerNotificationScheduler(
        notifications,
        storage,
        now: (location) => tz.TZDateTime(location, 2026, 8, 30),
      );
      await storage.writeJson(
        StorageKeys.prayerReminderSettings,
        const PrayerReminderSettings(enabled: true).toJson(),
      );
      final today = _schedule(prayers: [_prayer(PrayerName.fajr, 5, 10)]);
      final tomorrow = _schedule(
        date: DateTime(2026, 8, 31),
        prayers: [_prayer(PrayerName.fajr, 5, 11)],
      );

      await scheduler.updateSchedules(
        today: today,
        tomorrow: tomorrow,
        languageCode: 'en',
      );
      await scheduler.updateSchedules(
        today: today,
        tomorrow: tomorrow,
        languageCode: 'en',
      );

      expect(notifications.pending, hasLength(2));
      expect(notifications.pending.keys.toSet(), hasLength(2));
      expect(notifications.cancelled, containsAll(notifications.pending.keys));

      await scheduler.settingsChanged(
        const PrayerReminderSettings(enabled: false),
        languageCode: 'en',
      );

      expect(notifications.pending, isEmpty);
      expect(
        storage.readJson(StorageKeys.prayerReminderScheduledIds)?['ids'],
        isEmpty,
      );
    },
  );

  test(
    'uses supported scheduling fallback when exact alarms are unavailable',
    () async {
      final storage = _MemoryStorageService();
      final notifications = _FakeNotificationService()
        ..exactAlarmsEnabled = false;
      final scheduler = PrayerNotificationScheduler(
        notifications,
        storage,
        now: (location) => tz.TZDateTime(location, 2026, 8, 30),
      );
      await storage.writeJson(
        StorageKeys.prayerReminderSettings,
        const PrayerReminderSettings(enabled: true).toJson(),
      );

      await scheduler.updateSchedules(
        today: _schedule(prayers: [_prayer(PrayerName.fajr, 5, 10)]),
        tomorrow: _schedule(
          date: DateTime(2026, 8, 31),
          prayers: [_prayer(PrayerName.fajr, 5, 11)],
        ),
        languageCode: 'en',
      );

      expect(notifications.pending, hasLength(2));
    },
  );
}

PrayerNotificationScheduler _scheduler({required PrayerReminderNow now}) =>
    PrayerNotificationScheduler(
      _FakeNotificationService(),
      _MemoryStorageService(),
      now: now,
    );

Prayer _prayer(PrayerName name, int hour, int minute) =>
    Prayer(name: name, time: DateTime(2026, 8, 30, hour, minute));

PrayerSchedule _schedule({DateTime? date, required List<Prayer> prayers}) =>
    PrayerSchedule(
      date: date ?? DateTime(2026, 8, 30),
      prayers: prayers,
      hijriDay: '17',
      hijriMonthEnglish: 'Rabi al-Awwal',
      hijriMonthArabic: 'ربيع الأول',
      hijriYear: '1448',
      timezone: 'UTC',
    );

class _FakeNotificationService implements NotificationService {
  final pending = <int, LocalNotificationRequest>{};
  final cancelled = <int>[];
  bool notificationsEnabled = true;
  bool exactAlarmsEnabled = true;

  @override
  Future<void> initialize() async {}

  @override
  Future<String> refreshLocalTimezone() async => 'UTC';

  @override
  Future<bool> areNotificationsEnabled() async => notificationsEnabled;

  @override
  Future<bool> canScheduleExactNotifications() async => exactAlarmsEnabled;

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<bool> openAppNotificationSettings() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => exactAlarmsEnabled;

  @override
  Future<NotificationPermissionState> requestNotificationPermission() async =>
      notificationsEnabled
      ? NotificationPermissionState.granted
      : NotificationPermissionState.denied;

  @override
  Future<void> schedule(LocalNotificationRequest request) async {
    pending[request.id] = request;
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
