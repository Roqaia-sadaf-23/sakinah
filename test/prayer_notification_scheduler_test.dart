import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/notifications/notification_ids.dart';
import 'package:sakinah/core/notifications/prayer_notification_channels.dart';
import 'package:sakinah/core/notifications/notification_service.dart';
import 'package:sakinah/core/storage/storage_keys.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_schedule.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_sound_availability.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_sound_config.dart';
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

    test('subtracts the selected minutes from the prayer time', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18),
      );
      final plans = scheduler.buildPlans(
        [
          _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 36)]),
        ],
        const PrayerReminderSettings(enabled: true, minutesBefore: 15),
        languageCode: 'en',
      );

      expect(
        plans.single.scheduledDate,
        tz.TZDateTime(tz.UTC, 2026, 8, 30, 18, 21),
      );
    });

    test('does not schedule a reminder whose time has passed', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18, 30),
      );
      final plans = scheduler.buildPlans(
        [
          _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 36)]),
        ],
        const PrayerReminderSettings(enabled: true, minutesBefore: 15),
        languageCode: 'en',
      );

      expect(plans, isEmpty);
    });

    test('each attributed Adhan uses its dedicated channel and raw sound', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18),
      );
      const expected = <PrayerAlarmSound, (String, String)>{
        PrayerAlarmSound.jerusalem: (
          'prayer_reminders_adhan_jerusalem_v1',
          'adhan_jerusalem_short',
        ),
        PrayerAlarmSound.masjidAlHaram: (
          'prayer_reminders_adhan_masjid_al_haram_v1',
          'adhan_masjid_al_haram_short',
        ),
        PrayerAlarmSound.masjidAnNabawi: (
          'prayer_reminders_adhan_masjid_an_nabawi_v1',
          'adhan_masjid_an_nabawi_short',
        ),
      };

      for (final entry in expected.entries) {
        final plan = scheduler
            .buildPlans(
              [
                _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 36)]),
              ],
              PrayerReminderSettings(
                enabled: true,
                minutesBefore: 15,
                alarmSound: entry.key,
              ),
              languageCode: 'en',
            )
            .single;

        expect(plan.channelId, entry.value.$1);
        expect(plan.androidSoundResource, entry.value.$2);
        expect(plan.toRequest().androidSoundResource, entry.value.$2);
      }
    });

    test('normal plans use the dedicated default-sound channel', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18),
      );
      final plan = scheduler
          .buildPlans(
            [
              _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 36)]),
            ],
            const PrayerReminderSettings(enabled: true, minutesBefore: 15),
            languageCode: 'en',
          )
          .single;

      expect(plan.channelId, 'prayer_reminders_default_v3');
      expect(plan.androidSoundResource, isNull);
      expect(plan.playSound, isTrue);
    });

    test('silent plans use a channel with sound disabled', () {
      final scheduler = _scheduler(
        now: (location) => tz.TZDateTime(location, 2026, 8, 30, 18),
      );
      final plan = scheduler
          .buildPlans(
            [
              _schedule(prayers: [_prayer(PrayerName.maghrib, 18, 36)]),
            ],
            const PrayerReminderSettings(
              enabled: true,
              alarmSound: PrayerAlarmSound.silent,
            ),
            languageCode: 'en',
          )
          .single;

      expect(plan.channelId, PrayerNotificationChannels.silentId);
      expect(plan.androidSoundResource, isNull);
      expect(plan.playSound, isFalse);
      expect(plan.toRequest().playSound, isFalse);
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

  group('Android prayer notification channels', () {
    test('sound channels play and the silent channel does not', () {
      expect(PrayerNotificationChannels.defaultChannel.playSound, isTrue);
      expect(PrayerNotificationChannels.silentChannel.playSound, isFalse);
      expect(
        PrayerNotificationChannels.defaultChannel.audioAttributesUsage,
        AudioAttributesUsage.notification,
      );
      expect(
        PrayerNotificationChannels.all.map((channel) => channel.id),
        containsAll(<String>[
          'prayer_reminders_default_v3',
          'prayer_reminders_silent_v2',
        ]),
      );
    });

    test('custom notification details use the selected raw sound', () {
      final config = PrayerAlarmSound.jerusalem.config;
      final request = _unrelatedRequest(
        channelId: config.channelId,
        androidSoundResource: config.androidResource,
      );
      final details = PrayerNotificationChannels.detailsFor(
        request.channelId,
        channelName: request.channelName,
        channelDescription: request.channelDescription,
        androidSoundResource: request.androidSoundResource,
      );

      expect(details.channelId, 'prayer_reminders_adhan_jerusalem_v1');
      expect(details.playSound, isTrue);
      expect(details.sound, isA<RawResourceAndroidNotificationSound>());
      expect(details.audioAttributesUsage, AudioAttributesUsage.notification);
    });

    test('normal notification details use the default-sound channel', () {
      final request = _unrelatedRequest(
        channelId: PrayerNotificationChannels.defaultId,
      );
      final details = PrayerNotificationChannels.detailsFor(
        request.channelId,
        channelName: request.channelName,
        channelDescription: request.channelDescription,
        androidSoundResource: request.androidSoundResource,
      );

      expect(details.channelId, 'prayer_reminders_default_v3');
      expect(details.playSound, isTrue);
      expect(details.sound, isNull);
      expect(details.audioAttributesUsage, AudioAttributesUsage.notification);
    });

    test('silent notification details explicitly disable sound', () {
      final details = PrayerNotificationChannels.detailsFor(
        PrayerNotificationChannels.silentId,
        channelName: PrayerNotificationChannels.silentName,
        channelDescription: PrayerNotificationChannels.silentDescription,
        playSound: false,
      );

      expect(details.channelId, PrayerNotificationChannels.silentId);
      expect(details.playSound, isFalse);
      expect(details.sound, isNull);
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
      expect(notifications.cancelled, isEmpty);

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

  test('enabling schedules with the selected stored settings', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final scheduler = PrayerNotificationScheduler(
      notifications,
      storage,
      now: (location) => tz.TZDateTime(location, 2026, 8, 30),
    );
    await storage.writeJson(
      StorageKeys.prayerReminderSettings,
      const PrayerReminderSettings(enabled: false, minutesBefore: 15).toJson(),
    );
    await scheduler.updateSchedules(
      today: _schedule(prayers: [_prayer(PrayerName.fajr, 5, 10)]),
      tomorrow: _schedule(
        date: DateTime(2026, 8, 31),
        prayers: [_prayer(PrayerName.fajr, 5, 11)],
      ),
      languageCode: 'en',
    );

    expect(notifications.pending, isEmpty);
    await scheduler.settingsChanged(
      const PrayerReminderSettings(enabled: true, minutesBefore: 15),
      languageCode: 'en',
    );

    expect(notifications.pending, hasLength(2));
    expect(notifications.pending[202608301]!.scheduledDate.hour, 4);
    expect(notifications.pending[202608301]!.scheduledDate.minute, 55);
  });

  test(
    'sound changes preserve existing reminders until schedules load',
    () async {
      final storage = _MemoryStorageService();
      final notifications = _FakeNotificationService();
      final existing = _unrelatedRequest(id: 202608301);
      notifications.pending[existing.id] = existing;
      await storage.writeJson(StorageKeys.prayerReminderScheduledIds, {
        'ids': <int>[existing.id],
      });
      final scheduler = PrayerNotificationScheduler(notifications, storage);

      await scheduler.settingsChanged(
        const PrayerReminderSettings(
          enabled: true,
          alarmSound: PrayerAlarmSound.silent,
        ),
        languageCode: 'en',
      );

      expect(notifications.pending, contains(existing.id));
      expect(notifications.cancelled, isEmpty);
      expect(storage.readJson(StorageKeys.prayerReminderScheduledIds)?['ids'], [
        existing.id,
      ]);
    },
  );

  test('changing minutes replaces the existing prayer reminders', () async {
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
    await scheduler.updateSchedules(
      today: _schedule(prayers: [_prayer(PrayerName.fajr, 5, 10)]),
      tomorrow: _schedule(
        date: DateTime(2026, 8, 31),
        prayers: [_prayer(PrayerName.fajr, 5, 11)],
      ),
      languageCode: 'en',
    );

    expect(notifications.pending[202608301]!.scheduledDate.minute, 5);
    await scheduler.settingsChanged(
      const PrayerReminderSettings(enabled: true, minutesBefore: 15),
      languageCode: 'en',
    );

    expect(notifications.pending, hasLength(2));
    expect(notifications.pending[202608301]!.scheduledDate.minute, 55);
    expect(notifications.cancelled, isEmpty);
  });

  test(
    'changing to a verified Adhan replaces requests with its sound',
    () async {
      final storage = _MemoryStorageService();
      final notifications = _FakeNotificationService();
      final scheduler = PrayerNotificationScheduler(
        notifications,
        storage,
        now: (location) => tz.TZDateTime(location, 2026, 8, 30),
        soundAvailability: const _FakeSoundAvailability.all(),
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

      expect(notifications.pending[202608301]!.androidSoundResource, isNull);
      await scheduler.settingsChanged(
        const PrayerReminderSettings(
          enabled: true,
          alarmSound: PrayerAlarmSound.masjidAnNabawi,
        ),
        languageCode: 'en',
      );

      expect(
        notifications.pending.values,
        everyElement(
          isA<LocalNotificationRequest>()
              .having(
                (request) => request.channelId,
                'channelId',
                'prayer_reminders_adhan_masjid_an_nabawi_v1',
              )
              .having(
                (request) => request.androidSoundResource,
                'androidSoundResource',
                'adhan_masjid_an_nabawi_short',
              ),
        ),
      );
    },
  );

  test(
    'changing sounds repeatedly keeps stable IDs without duplicates',
    () async {
      final storage = _MemoryStorageService();
      final notifications = _FakeNotificationService();
      final scheduler = PrayerNotificationScheduler(
        notifications,
        storage,
        now: (location) => tz.TZDateTime(location, 2026, 8, 30),
        soundAvailability: const _FakeSoundAvailability.all(),
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

      await scheduler.settingsChanged(
        const PrayerReminderSettings(
          enabled: true,
          alarmSound: PrayerAlarmSound.jerusalem,
        ),
        languageCode: 'en',
      );
      await scheduler.settingsChanged(
        const PrayerReminderSettings(
          enabled: true,
          alarmSound: PrayerAlarmSound.silent,
        ),
        languageCode: 'en',
      );

      expect(notifications.pending.keys, {202608301, 202608311});
      expect(
        notifications.pending.values,
        everyElement(
          isA<LocalNotificationRequest>()
              .having(
                (request) => request.channelId,
                'channelId',
                PrayerNotificationChannels.silentId,
              )
              .having((request) => request.playSound, 'playSound', isFalse),
        ),
      );
      expect(notifications.cancelled, isEmpty);
    },
  );

  test('sound test uses the selected sound after ten seconds', () async {
    final notifications = _FakeNotificationService();
    final now = tz.TZDateTime(tz.UTC, 2026, 10, 16, 12);
    final scheduler = PrayerNotificationScheduler(
      notifications,
      _MemoryStorageService(),
      now: (_) => now,
      soundAvailability: const _FakeSoundAvailability.all(),
    );

    await scheduler.scheduleSoundTest(
      PrayerAlarmSound.masjidAlHaram,
      languageCode: 'ar',
    );

    final request = notifications.pending[900000001];
    expect(request, isNotNull);
    expect(request!.scheduledDate, now.add(const Duration(seconds: 10)));
    expect(request.channelId, PrayerAlarmSound.masjidAlHaram.config.channelId);
    expect(request.androidSoundResource, 'adhan_masjid_al_haram_short');
    expect(request.body, 'اختبار صوت تذكير الصلاة');
  });

  test('failed replacement does not cancel existing reminders', () async {
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
    await scheduler.updateSchedules(
      today: _schedule(prayers: [_prayer(PrayerName.fajr, 5, 10)]),
      tomorrow: _schedule(
        date: DateTime(2026, 8, 31),
        prayers: [_prayer(PrayerName.fajr, 5, 11)],
      ),
      languageCode: 'en',
    );

    notifications.failId = 202608311;
    await expectLater(
      scheduler.settingsChanged(
        const PrayerReminderSettings(
          enabled: true,
          alarmSound: PrayerAlarmSound.silent,
        ),
        languageCode: 'en',
      ),
      throwsStateError,
    );

    expect(notifications.cancelled, isEmpty);
    expect(notifications.pending.keys, {202608301, 202608311});
    expect(storage.readJson(StorageKeys.prayerReminderScheduledIds)?['ids'], [
      202608301,
      202608311,
    ]);
  });

  test('unverified custom sound leaves existing reminders untouched', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final existing = _unrelatedRequest(id: 202608301);
    notifications.pending[existing.id] = existing;
    await storage.writeJson(StorageKeys.prayerReminderScheduledIds, {
      'ids': <int>[existing.id],
    });
    await storage.writeJson(
      StorageKeys.prayerReminderSettings,
      const PrayerReminderSettings(enabled: true).toJson(),
    );
    final scheduler = PrayerNotificationScheduler(
      notifications,
      storage,
      now: (location) => tz.TZDateTime(location, 2026, 8, 30),
      soundAvailability: const _FakeSoundAvailability.systemOnly(),
    );
    await scheduler.updateSchedules(
      today: _schedule(prayers: [_prayer(PrayerName.fajr, 5, 10)]),
      tomorrow: _schedule(
        date: DateTime(2026, 8, 31),
        prayers: [_prayer(PrayerName.fajr, 5, 11)],
      ),
      languageCode: 'en',
    );

    await expectLater(
      scheduler.settingsChanged(
        const PrayerReminderSettings(
          enabled: true,
          alarmSound: PrayerAlarmSound.jerusalem,
        ),
        languageCode: 'en',
      ),
      throwsA(isA<PrayerAlarmSoundUnavailableException>()),
    );

    expect(notifications.pending, contains(existing.id));
    expect(notifications.cancelled, isEmpty);
  });

  test('cancelling prayer reminders leaves unrelated notifications', () async {
    final storage = _MemoryStorageService();
    final notifications = _FakeNotificationService();
    final scheduler = PrayerNotificationScheduler(notifications, storage);
    notifications.pending[999] = _unrelatedRequest();
    notifications.pending[202608301] = _unrelatedRequest(id: 202608301);
    await storage.writeJson(StorageKeys.prayerReminderScheduledIds, {
      'ids': <int>[202608301],
    });

    await scheduler.cancelPrayerReminders();

    expect(notifications.pending, contains(999));
    expect(notifications.pending, isNot(contains(202608301)));
    expect(notifications.cancelled, [202608301]);
  });
}

LocalNotificationRequest _unrelatedRequest({
  int id = 999,
  String channelId = 'other',
  String? androidSoundResource,
}) => LocalNotificationRequest(
  id: id,
  title: 'Other',
  body: 'Other notification',
  scheduledDate: tz.TZDateTime(tz.UTC, 2026, 9, 1),
  channelId: channelId,
  channelName: 'Other',
  channelDescription: 'Other notifications',
  payload: 'other',
  androidSoundResource: androidSoundResource,
);

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
  int? failId;

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
    if (request.id == failId) throw StateError('simulated schedule failure');
    pending[request.id] = request;
  }
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
