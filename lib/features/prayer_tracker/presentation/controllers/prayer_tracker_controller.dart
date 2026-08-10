import 'package:get/get.dart';

import '../../../prayer_times/domain/entities/prayer.dart';
import '../../domain/repositories/prayer_tracker_repository.dart';

class PrayerTrackerController extends GetxController {
  PrayerTrackerController(this._repository);

  final PrayerTrackerRepository _repository;
  final completed = <String>{}.obs;
  late DateTime _activeDate;

  static const prayers = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];

  int get completedCount => completed.length;

  @override
  void onInit() {
    super.onInit();
    _activeDate = DateTime.now();
    completed.assignAll(_repository.completedFor(_activeDate));
  }

  bool isCompleted(PrayerName prayer) => completed.contains(prayer.name);

  Future<void> toggle(PrayerName prayer) async {
    _rollToTodayIfNeeded();
    if (!completed.add(prayer.name)) completed.remove(prayer.name);
    await _repository.saveCompleted(_activeDate, completed.toSet());
  }

  void _rollToTodayIfNeeded() {
    final current = DateTime.now();
    if (current.year == _activeDate.year &&
        current.month == _activeDate.month &&
        current.day == _activeDate.day) {
      return;
    }
    _activeDate = current;
    completed.assignAll(_repository.completedFor(current));
  }
}
