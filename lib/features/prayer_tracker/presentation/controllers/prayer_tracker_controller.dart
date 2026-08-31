import 'package:get/get.dart';

import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';
import '../../domain/repositories/prayer_tracker_repository.dart';

class PrayerTrackerController extends GetxController {
  PrayerTrackerController(this._repository, this._prayerTimesController);

  final PrayerTrackerRepository _repository;
  final PrayerTimesController _prayerTimesController;
  final completed = <String>{}.obs;
  late DateTime _activeDate;
  Worker? _dayChangeWorker;

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
    _activeDate = _prayerTimesController.now.value;
    completed.assignAll(_repository.completedFor(_activeDate));
    _dayChangeWorker = ever<DateTime>(
      _prayerTimesController.now,
      _rollToDateIfNeeded,
    );
  }

  bool isCompleted(PrayerName prayer) => completed.contains(prayer.name);

  bool canMarkPrayer(PrayerName prayer) {
    final current = _prayerTimesController.now.value;
    final schedule = _prayerTimesController.todaySchedule.value;
    if (schedule == null || !_isSameDate(schedule.date, current)) return false;

    final prayerData = schedule.prayers
        .where((item) => item.name == prayer)
        .firstOrNull;
    if (prayerData == null) return false;

    return !current.isBefore(prayerData.time);
  }

  Future<void> toggle(PrayerName prayer) async {
    _rollToDateIfNeeded(_prayerTimesController.now.value);

    if (isCompleted(prayer)) {
      completed.remove(prayer.name);
    } else {
      if (!canMarkPrayer(prayer)) return;
      completed.add(prayer.name);
    }

    await _repository.saveCompleted(_activeDate, completed.toSet());
  }

  void _rollToDateIfNeeded(DateTime current) {
    if (_isSameDate(current, _activeDate)) return;

    _activeDate = current;
    completed.assignAll(_repository.completedFor(current));
  }

  bool _isSameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  @override
  void onClose() {
    _dayChangeWorker?.dispose();
    super.onClose();
  }
}
