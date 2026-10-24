import '../../domain/entities/prayer_reminder_settings.dart';

class PrayerAlarmSoundConfig {
  const PrayerAlarmSoundConfig({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    this.androidResource,
    this.flutterAssetPath,
    this.playSound = true,
  });

  final String channelId;
  final String channelName;
  final String channelDescription;
  final String? androidResource;
  final String? flutterAssetPath;
  final bool playSound;

  bool get requiresBundledFile => androidResource != null;
}

extension PrayerAlarmSoundConfiguration on PrayerAlarmSound {
  PrayerAlarmSoundConfig get config => switch (this) {
    PrayerAlarmSound.jerusalem => const PrayerAlarmSoundConfig(
      channelId: 'prayer_reminders_adhan_jerusalem_v1',
      channelName: 'تذكيرات الصلاة - أذان القدس',
      channelDescription: 'تذكيرات الصلاة بمقطع قصير من أذان القدس',
      androidResource: 'adhan_jerusalem_short',
      flutterAssetPath:
          'android/app/src/main/res/raw/adhan_jerusalem_short.mp3',
    ),
    PrayerAlarmSound.masjidAlHaram => const PrayerAlarmSoundConfig(
      channelId: 'prayer_reminders_adhan_masjid_al_haram_v1',
      channelName: 'تذكيرات الصلاة - أذان المسجد الحرام',
      channelDescription: 'تذكيرات الصلاة بمقطع قصير من أذان المسجد الحرام',
      androidResource: 'adhan_masjid_al_haram_short',
      flutterAssetPath:
          'android/app/src/main/res/raw/adhan_masjid_al_haram_short.mp3',
    ),
    PrayerAlarmSound.masjidAnNabawi => const PrayerAlarmSoundConfig(
      channelId: 'prayer_reminders_adhan_masjid_an_nabawi_v1',
      channelName: 'تذكيرات الصلاة - أذان المسجد النبوي',
      channelDescription: 'تذكيرات الصلاة بمقطع قصير من أذان المسجد النبوي',
      androidResource: 'adhan_masjid_an_nabawi_short',
      flutterAssetPath:
          'android/app/src/main/res/raw/adhan_masjid_an_nabawi_short.mp3',
    ),
    PrayerAlarmSound.systemDefault => const PrayerAlarmSoundConfig(
      channelId: 'prayer_reminders_default_v3',
      channelName: 'تذكيرات الصلاة - صوت الجهاز',
      channelDescription: 'تذكيرات الصلاة بصوت الإشعارات الافتراضي للجهاز',
    ),
    PrayerAlarmSound.silent => const PrayerAlarmSoundConfig(
      channelId: 'prayer_reminders_silent_v2',
      channelName: 'تذكيرات الصلاة - صامت',
      channelDescription: 'تذكيرات الصلاة دون صوت',
      playSound: false,
    ),
  };
}
