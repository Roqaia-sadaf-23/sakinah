abstract final class NotificationIds {
  static int prayerReminder({required DateTime date, required int prayerSlot}) {
    assert(prayerSlot >= 1 && prayerSlot <= 5);
    final datePart = date.year * 10000 + date.month * 100 + date.day;
    return datePart * 10 + prayerSlot;
  }
}
