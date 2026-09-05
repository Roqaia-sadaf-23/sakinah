import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract final class TimezoneUtils {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _initialized = true;
  }

  static tz.Location location(String identifier) {
    ensureInitialized();
    final normalized = identifier.trim();
    if (normalized.isEmpty) return tz.local;
    if (normalized == 'UTC' || normalized == 'GMT') return tz.UTC;
    try {
      return tz.getLocation(normalized);
    } on tz.LocationNotFoundException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[PrayerTime] Unknown timezone "$identifier"; using device timezone: '
          '$error',
        );
      }
      return tz.local;
    }
  }

  static tz.TZDateTime atWallClock({
    required tz.Location location,
    required DateTime date,
    required int hour,
    required int minute,
  }) => tz.TZDateTime(location, date.year, date.month, date.day, hour, minute);
}
