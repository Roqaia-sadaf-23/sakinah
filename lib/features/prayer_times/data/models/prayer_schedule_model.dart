import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/timezone_utils.dart';
import '../../domain/entities/prayer.dart';
import '../../domain/entities/prayer_schedule.dart';

class PrayerScheduleModel {
  const PrayerScheduleModel({required this.schedule});

  final PrayerSchedule schedule;

  factory PrayerScheduleModel.fromApi(
    Map<String, dynamic> json,
    DateTime requestedDate,
  ) {
    final timings = json['timings'] as Map<String, dynamic>?;
    final date = json['date'] as Map<String, dynamic>?;
    final hijri = date?['hijri'] as Map<String, dynamic>?;
    final month = hijri?['month'] as Map<String, dynamic>?;
    final meta = json['meta'] as Map<String, dynamic>?;
    if (timings == null || hijri == null || month == null) {
      throw const FormatException('Missing prayer schedule fields');
    }

    final timezone = meta?['timezone']?.toString() ?? '';
    final location = TimezoneUtils.location(timezone);

    DateTime parseTime(String key) {
      final raw = timings[key]?.toString();
      final match = raw == null
          ? null
          : RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
      if (match == null) throw FormatException('Invalid $key time');
      final parsed = TimezoneUtils.atWallClock(
        location: location,
        date: requestedDate,
        hour: int.parse(match.group(1)!),
        minute: int.parse(match.group(2)!),
      );
      if (kDebugMode) {
        debugPrint('[PrayerTime] Parsed $key: $parsed ($timezone)');
      }
      return parsed;
    }

    return PrayerScheduleModel(
      schedule: PrayerSchedule(
        date: DateTime(
          requestedDate.year,
          requestedDate.month,
          requestedDate.day,
        ),
        prayers: [
          Prayer(name: PrayerName.fajr, time: parseTime('Fajr')),
          Prayer(name: PrayerName.sunrise, time: parseTime('Sunrise')),
          Prayer(name: PrayerName.dhuhr, time: parseTime('Dhuhr')),
          Prayer(name: PrayerName.asr, time: parseTime('Asr')),
          Prayer(name: PrayerName.maghrib, time: parseTime('Maghrib')),
          Prayer(name: PrayerName.isha, time: parseTime('Isha')),
        ],
        hijriDay: hijri['day']?.toString() ?? '',
        hijriMonthEnglish: month['en']?.toString() ?? '',
        hijriMonthArabic: month['ar']?.toString() ?? '',
        hijriYear: hijri['year']?.toString() ?? '',
        timezone: timezone,
      ),
    );
  }

  factory PrayerScheduleModel.fromCache(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    final times = json['times'] as Map<String, dynamic>;
    final timezone = json['timezone'] as String? ?? '';
    final location = TimezoneUtils.location(timezone);

    DateTime parseCachedTime(PrayerName name) {
      final raw = times[name.name] as String;
      final match = RegExp(r'(?:T|^)(\d{1,2}):(\d{2})').firstMatch(raw);
      if (match == null) {
        throw FormatException('Invalid cached ${name.name} time');
      }
      return TimezoneUtils.atWallClock(
        location: location,
        date: date,
        hour: int.parse(match.group(1)!),
        minute: int.parse(match.group(2)!),
      );
    }

    return PrayerScheduleModel(
      schedule: PrayerSchedule(
        date: date,
        prayers: PrayerName.values
            .map((name) => Prayer(name: name, time: parseCachedTime(name)))
            .toList(growable: false),
        hijriDay: json['hijriDay'] as String,
        hijriMonthEnglish: json['hijriMonthEnglish'] as String,
        hijriMonthArabic: json['hijriMonthArabic'] as String,
        hijriYear: json['hijriYear'] as String,
        timezone: timezone,
        isCached: true,
      ),
    );
  }

  Map<String, dynamic> toCache() => {
    'date': DateFormat('yyyy-MM-dd').format(schedule.date),
    'times': {
      for (final prayer in schedule.prayers)
        prayer.name.name: DateFormat('HH:mm').format(prayer.time),
    },
    'hijriDay': schedule.hijriDay,
    'hijriMonthEnglish': schedule.hijriMonthEnglish,
    'hijriMonthArabic': schedule.hijriMonthArabic,
    'hijriYear': schedule.hijriYear,
    'timezone': schedule.timezone,
  };
}
