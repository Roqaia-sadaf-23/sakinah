import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract final class PrayerNotificationChannels {
  // Android persists channel sound settings. Increment these IDs whenever a
  // released channel's sound configuration must change.
  static const defaultId = 'prayer_reminders_default_v3';
  static const defaultName = 'تذكيرات الصلاة - صوت الجهاز';
  static const defaultDescription =
      'تذكيرات الصلاة بصوت الإشعارات الافتراضي للجهاز';

  static const silentId = 'prayer_reminders_silent_v2';
  static const silentName = 'تذكيرات الصلاة - صامت';
  static const silentDescription = 'تذكيرات الصلاة دون صوت';

  static const defaultChannel = AndroidNotificationChannel(
    defaultId,
    defaultName,
    description: defaultDescription,
    importance: Importance.high,
    playSound: true,
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
