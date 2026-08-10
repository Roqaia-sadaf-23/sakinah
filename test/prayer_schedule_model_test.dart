import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/prayer_times/data/models/prayer_schedule_model.dart';
import 'package:sakinah/features/prayer_times/domain/entities/prayer.dart';

void main() {
  group('PrayerScheduleModel', () {
    test('maps API timings and Hijri date into the domain entity', () {
      final date = DateTime(2026, 8, 10);
      final model = PrayerScheduleModel.fromApi({
        'timings': {
          'Fajr': '04:28 (+03)',
          'Sunrise': '05:50 (+03)',
          'Dhuhr': '12:28 (+03)',
          'Asr': '15:48 (+03)',
          'Maghrib': '19:06 (+03)',
          'Isha': '20:36 (+03)',
        },
        'date': {
          'hijri': {
            'day': '26',
            'month': {'en': 'Safar', 'ar': 'صَفَر'},
            'year': '1448',
          },
        },
        'meta': {'timezone': 'Asia/Riyadh'},
      }, date);

      expect(model.schedule.prayer(PrayerName.asr).time.hour, 15);
      expect(model.schedule.prayer(PrayerName.asr).time.minute, 48);
      expect(model.schedule.hijriLabel(arabic: false), '26 Safar 1448');
      expect(model.schedule.timezone, 'Asia/Riyadh');
    });

    test('round-trips through the cache format', () {
      final date = DateTime(2026, 8, 10);
      final original = PrayerScheduleModel.fromApi({
        'timings': {
          'Fajr': '04:28',
          'Sunrise': '05:50',
          'Dhuhr': '12:28',
          'Asr': '15:48',
          'Maghrib': '19:06',
          'Isha': '20:36',
        },
        'date': {
          'hijri': {
            'day': '26',
            'month': {'en': 'Safar', 'ar': 'صَفَر'},
            'year': '1448',
          },
        },
        'meta': {'timezone': 'Asia/Riyadh'},
      }, date);

      final cached = PrayerScheduleModel.fromCache(original.toCache());

      expect(cached.schedule.isCached, isTrue);
      expect(
        cached.schedule.prayer(PrayerName.fajr).time,
        DateTime(2026, 8, 10, 4, 28),
      );
    });
  });
}
