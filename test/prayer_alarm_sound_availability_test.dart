import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_sound_availability.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_sound_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('debug exposes technically verified sounds without changing license', () async {
    final bundle = _bundle();
    final availability = BundledPrayerAlarmSoundAvailability(
      bundle: bundle,
      allowTechnicallyVerifiedDebugSounds: true,
    );

    expect(
      await availability.availableSounds(),
      containsAll(PrayerAlarmSound.values),
    );
  });

  test('release keeps sounds unavailable while redistribution is unverified', () async {
    final bundle = _bundle();
    final availability = BundledPrayerAlarmSoundAvailability(
      bundle: bundle,
      allowTechnicallyVerifiedDebugSounds: false,
    );

    expect(await availability.availableSounds(), {
      PrayerAlarmSound.systemDefault,
      PrayerAlarmSound.silent,
    });
  });

  test('debug still rejects a sound that failed technical verification', () async {
    final manifest = _manifest();
    final sounds = manifest['sounds'] as Map<String, dynamic>;
    (sounds[PrayerAlarmSound.jerusalem.name] as Map<String, dynamic>)[
          'technicalVerified'
        ] =
        false;
    final availability = BundledPrayerAlarmSoundAvailability(
      bundle: _bundle(manifest: manifest),
      allowTechnicallyVerifiedDebugSounds: true,
    );

    expect(
      await availability.availableSounds(),
      isNot(contains(PrayerAlarmSound.jerusalem)),
    );
  });
}

Map<String, dynamic> _manifest() => {
  'sounds': {
    for (final sound in const [
      PrayerAlarmSound.jerusalem,
      PrayerAlarmSound.masjidAlHaram,
      PrayerAlarmSound.masjidAnNabawi,
    ])
      sound.name: {
        'technicalVerified': true,
        'verified': false,
        'sourceUrl': 'https://github.com/Kiwifu/adhan-mp3',
        'license': '',
      },
  },
};

_MemoryAssetBundle _bundle({Map<String, dynamic>? manifest}) {
  final files = <String, List<int>>{
    BundledPrayerAlarmSoundAvailability.manifestAsset: utf8.encode(
      jsonEncode(manifest ?? _manifest()),
    ),
    for (final sound in const [
      PrayerAlarmSound.jerusalem,
      PrayerAlarmSound.masjidAlHaram,
      PrayerAlarmSound.masjidAnNabawi,
    ])
      sound.config.flutterAssetPath!: const [1, 2, 3],
  };
  return _MemoryAssetBundle(files);
}

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(this.files);

  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    final bytes = files[key];
    if (bytes == null) throw FlutterError('Missing test asset: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
