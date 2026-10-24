import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/entities/prayer_reminder_settings.dart';
import 'prayer_alarm_sound_config.dart';

abstract class PrayerAlarmPreviewPlayer {
  Future<void> preview(PrayerAlarmSound sound);

  Future<void> stop();

  Future<void> dispose();
}

class JustAudioPrayerAlarmPreviewPlayer implements PrayerAlarmPreviewPlayer {
  JustAudioPrayerAlarmPreviewPlayer({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  static const androidDefaultNotificationSound =
      'content://settings/system/notification_sound';

  final AudioPlayer _player;

  @override
  Future<void> preview(PrayerAlarmSound sound) async {
    await _player.stop();
    switch (sound) {
      case PrayerAlarmSound.systemDefault:
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          await _player.setUrl(androidDefaultNotificationSound);
          return _player.play();
        }
        return SystemSound.play(SystemSoundType.alert);
      case PrayerAlarmSound.jerusalem:
      case PrayerAlarmSound.masjidAlHaram:
      case PrayerAlarmSound.masjidAnNabawi:
        await _player.setAsset(sound.config.flutterAssetPath!);
        return _player.play();
      case PrayerAlarmSound.silent:
        return;
    }
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
