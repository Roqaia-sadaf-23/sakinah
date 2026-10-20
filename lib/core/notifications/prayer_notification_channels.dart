import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract final class PrayerNotificationChannels {
  // Android persists channel sound settings. Increment these IDs whenever a
  // released channel's sound configuration must change.
  static const defaultId = 'prayer_reminders_default_v2';
  static const defaultName = 'Prayer Reminders';
  static const defaultDescription = 'Prayer reminder notifications';

  static const takbeerId = 'prayer_reminders_takbeer_v2';
  static const takbeerName = 'Prayer Reminders - Takbeer';
  static const takbeerDescription = 'Prayer reminders using Takbeer sound';
  static const takbeerSoundResource = 'takbeer_notification';

  static const silentId = 'prayer_reminders_silent_v1';
  static const silentName = 'Prayer Reminders - Silent';
  static const silentDescription = 'Silent prayer reminder notifications';

  static const defaultChannel = AndroidNotificationChannel(
    defaultId,
    defaultName,
    description: defaultDescription,
    importance: Importance.high,
    playSound: true,
    audioAttributesUsage: AudioAttributesUsage.notification,
  );

  static const takbeerChannel = AndroidNotificationChannel(
    takbeerId,
    takbeerName,
    description: takbeerDescription,
    importance: Importance.high,
    playSound: true,
    sound: RawResourceAndroidNotificationSound(takbeerSoundResource),
    audioAttributesUsage: AudioAttributesUsage.notification,
  );

  static const silentChannel = AndroidNotificationChannel(
    silentId,
    silentName,
    description: silentDescription,
    importance: Importance.high,
    playSound: false,
  );

  static const all = <AndroidNotificationChannel>[
    defaultChannel,
    takbeerChannel,
    silentChannel,
  ];

  static AndroidNotificationDetails detailsFor(
    String channelId, {
    required String channelName,
    required String channelDescription,
    String? androidSoundResource,
    bool playSound = true,
  }) {
    if (channelId == silentId) {
      return const AndroidNotificationDetails(
        silentId,
        silentName,
        channelDescription: silentDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: false,
      );
    }

    if (channelId == takbeerId) {
      return const AndroidNotificationDetails(
        takbeerId,
        takbeerName,
        channelDescription: takbeerDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(takbeerSoundResource),
        audioAttributesUsage: AudioAttributesUsage.notification,
      );
    }

    if (channelId == defaultId) {
      return const AndroidNotificationDetails(
        defaultId,
        defaultName,
        channelDescription: defaultDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      );
    }

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      playSound: playSound,
      sound: androidSoundResource == null
          ? null
          : RawResourceAndroidNotificationSound(androidSoundResource),
      audioAttributesUsage: AudioAttributesUsage.notification,
    );
  }
}
