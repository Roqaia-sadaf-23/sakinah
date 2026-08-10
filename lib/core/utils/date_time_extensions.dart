extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
}

extension DurationDisplay on Duration {
  String get clock {
    final safeSeconds = isNegative ? 0 : inSeconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final seconds = safeSeconds % 60;
    return [
      hours,
      minutes,
      seconds,
    ].map((value) => value.toString().padLeft(2, '0')).join(':');
  }
}
