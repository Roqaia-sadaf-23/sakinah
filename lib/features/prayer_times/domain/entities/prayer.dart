enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension PrayerNameX on PrayerName {
  String get key => name;

  bool get isObligatory => this != PrayerName.sunrise;
}

class Prayer {
  const Prayer({required this.name, required this.time});

  final PrayerName name;
  final DateTime time;
}
