import 'package:intl/intl.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_service.dart';
import '../../domain/repositories/prayer_tracker_repository.dart';

class LocalPrayerTrackerRepository implements PrayerTrackerRepository {
  const LocalPrayerTrackerRepository(this._storage);

  final StorageService _storage;

  @override
  Set<String> completedFor(DateTime date) {
    final json = _storage.readJson(_key(date));
    final completed = json?['completed'];
    if (completed is! List) return <String>{};
    return completed.whereType<String>().toSet();
  }

  @override
  Future<void> saveCompleted(DateTime date, Set<String> prayerKeys) =>
      _storage.writeJson(_key(date), {'completed': prayerKeys.toList()});

  String _key(DateTime date) =>
      '${StorageKeys.prayerTrackerPrefix}.${DateFormat('yyyy-MM-dd').format(date)}';
}
