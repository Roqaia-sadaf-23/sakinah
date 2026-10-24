import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer_reminder_settings.dart';
import 'package:sakinah/features/prayer_times/presentation/services/prayer_alarm_sound_config.dart';

void main() {
  test('custom Adhan resources match their recorded source entries', () {
    final manifest =
        jsonDecode(
              File(
                'assets/data/prayer_notification_sounds.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final entries = manifest['sounds'] as Map<String, dynamic>;
    const expected = <PrayerAlarmSound, (String, double)>{
      PrayerAlarmSound.jerusalem: (
        'Adhan_Al_Aqsa_-_Jerusalem_(أذان_المسجد_الأقصى_-_القدس).mp3',
        37.0,
      ),
      PrayerAlarmSound.masjidAlHaram: (
        'Adhan_Fajr_Al_Haram_Al_Maki_(أذان_الفجر_الحرم_المكي).mp3',
        79.5,
      ),
      PrayerAlarmSound.masjidAnNabawi: (
        'Adhan_Al_Haram_Al_Madani_-_Al_Madinah_1_(أذان_الحرم_المدني_-_المدينة_المنورة).mp3',
        50.0,
      ),
    };

    for (final item in expected.entries) {
      final sound = item.key;
      final entry = entries[sound.name] as Map<String, dynamic>;
      final resource = File(sound.config.flutterAssetPath!);

      expect(entry['sourceUrl'], 'https://github.com/Kiwifu/adhan-mp3');
      expect(entry['sourceFile'], item.value.$1);
      expect(entry['outputPath'], sound.config.flutterAssetPath);
      expect(entry['excerptEndSeconds'], item.value.$2);
      expect(entry['technicalVerified'], isTrue);
      expect(entry['verified'], isFalse);
      expect(entry['license'], isEmpty);
      expect(entry['licenseEvidence'], isNotEmpty);
      expect(resource.existsSync(), isTrue);
      expect(resource.lengthSync(), greaterThan(10 * 1024));
      expect(
        resource.readAsBytesSync().take(3),
        orderedEquals('ID3'.codeUnits),
      );
    }
  });
}
