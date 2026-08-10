import 'prayer.dart';

class PrayerSchedule {
  const PrayerSchedule({
    required this.date,
    required this.prayers,
    required this.hijriDay,
    required this.hijriMonthEnglish,
    required this.hijriMonthArabic,
    required this.hijriYear,
    required this.timezone,
    this.isCached = false,
  });

  final DateTime date;
  final List<Prayer> prayers;
  final String hijriDay;
  final String hijriMonthEnglish;
  final String hijriMonthArabic;
  final String hijriYear;
  final String timezone;
  final bool isCached;

  Prayer prayer(PrayerName name) =>
      prayers.firstWhere((item) => item.name == name);

  String hijriLabel({required bool arabic}) {
    final month = arabic ? hijriMonthArabic : hijriMonthEnglish;
    return '$hijriDay $month $hijriYear';
  }

  PrayerSchedule asCached() => PrayerSchedule(
    date: date,
    prayers: prayers,
    hijriDay: hijriDay,
    hijriMonthEnglish: hijriMonthEnglish,
    hijriMonthArabic: hijriMonthArabic,
    hijriYear: hijriYear,
    timezone: timezone,
    isCached: true,
  );
}
