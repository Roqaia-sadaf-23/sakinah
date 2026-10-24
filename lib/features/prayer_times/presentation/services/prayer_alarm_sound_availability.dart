import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/prayer_reminder_settings.dart';
import 'prayer_alarm_sound_config.dart';

abstract class PrayerAlarmSoundAvailability {
  Future<Set<PrayerAlarmSound>> availableSounds();

  Future<bool> isAvailable(PrayerAlarmSound sound);
}

class BundledPrayerAlarmSoundAvailability
    implements PrayerAlarmSoundAvailability {
  BundledPrayerAlarmSoundAvailability({
    AssetBundle? bundle,
    bool allowTechnicallyVerifiedDebugSounds = kDebugMode,
  }) : _bundle = bundle ?? rootBundle,
       _allowTechnicallyVerifiedDebugSounds =
           allowTechnicallyVerifiedDebugSounds;

  static const manifestAsset = 'assets/data/prayer_notification_sounds.json';

  final AssetBundle _bundle;
  final bool _allowTechnicallyVerifiedDebugSounds;
  Future<Set<PrayerAlarmSound>>? _cached;

  @override
  Future<Set<PrayerAlarmSound>> availableSounds() =>
      _cached ??= _loadAvailableSounds();

  @override
  Future<bool> isAvailable(PrayerAlarmSound sound) async =>
      (await availableSounds()).contains(sound);

  Future<Set<PrayerAlarmSound>> _loadAvailableSounds() async {
    final available = <PrayerAlarmSound>{
      PrayerAlarmSound.systemDefault,
      PrayerAlarmSound.silent,
    };

    // Custom Android notification sounds must be native raw resources. Do not
    // offer them on another platform as though they could work there.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return available;
    }

    Map<String, dynamic> manifest;
    try {
      manifest =
          jsonDecode(await _bundle.loadString(manifestAsset))
              as Map<String, dynamic>;
    } catch (_) {
      return available;
    }

    final entries = manifest['sounds'];
    if (entries is! Map<String, dynamic>) return available;

    for (final sound in PrayerAlarmSound.values) {
      final config = sound.config;
      if (!config.requiresBundledFile) continue;
      final entry = entries[sound.name];
      if (entry is! Map<String, dynamic> ||
          entry['technicalVerified'] != true) {
        continue;
      }

      // `technicalVerified` covers the file identity, excerpt, encoding, and
      // resource wiring. `verified` is deliberately reserved for confirmed
      // redistribution permission. Debug builds may exercise technically
      // verified local files; profile/release builds still require both the
      // permission flag and its supporting metadata.
      final redistributionVerified = entry['verified'] == true;
      if (!redistributionVerified && !_allowTechnicallyVerifiedDebugSounds) {
        continue;
      }
      if (redistributionVerified) {
        final sourceUrl = entry['sourceUrl'];
        final license = entry['license'];
        if (sourceUrl is! String || sourceUrl.trim().isEmpty) continue;
        if (license is! String || license.trim().isEmpty) continue;
      }
      try {
        await _bundle.load(config.flutterAssetPath!);
        available.add(sound);
      } catch (_) {
        // Manifest status alone is not enough: the audio must also be
        // packaged at the exact native resource path.
      }
    }
    return available;
  }
}

class PrayerAlarmSoundUnavailableException implements Exception {
  const PrayerAlarmSoundUnavailableException(this.sound);

  final PrayerAlarmSound sound;

  @override
  String toString() =>
      'The audio resource for ${sound.name} is unavailable in this build.';
}
