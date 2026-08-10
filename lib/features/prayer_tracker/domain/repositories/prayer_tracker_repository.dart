abstract interface class PrayerTrackerRepository {
  Set<String> completedFor(DateTime date);

  Future<void> saveCompleted(DateTime date, Set<String> prayerKeys);
}
