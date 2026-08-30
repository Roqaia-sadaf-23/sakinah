import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:sakinah/features/azkar/data/models/azkar_category_model.dart';
import 'package:sakinah/features/azkar/data/models/dhikr_model.dart';
import 'package:sakinah/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:sakinah/features/azkar/domain/entities/azkar_position.dart';

void main() {
  test(
    'daily category progress resets when the local calendar day changes',
    () async {
      final storage = _MemoryStorageService();
      var now = DateTime(2026, 8, 30, 20);
      final repository = AzkarRepositoryImpl(
        _FakeAzkarLocalDataSource(),
        storage,
        now: () => now,
      );
      final category = (await repository.getCategories()).first;

      await repository.saveCounts(category, <String, int>{'daily-1': 2});
      expect(await repository.getCounts(category), <String, int>{'daily-1': 2});

      now = DateTime(2026, 8, 31, 1);
      expect(await repository.getCounts(category), isEmpty);
    },
  );

  test(
    'favorites, position, and Azkar font size persist independently',
    () async {
      final storage = _MemoryStorageService();
      final repository = AzkarRepositoryImpl(
        _FakeAzkarLocalDataSource(),
        storage,
      );

      await repository.saveFavoriteIds(<String>{'daily-1'});
      await repository.saveLastPosition(
        const AzkarPosition(categoryId: 'morning', dhikrId: 'daily-1'),
      );
      await repository.saveFontSize(40);

      final reopened = AzkarRepositoryImpl(
        _FakeAzkarLocalDataSource(),
        storage,
      );
      expect(reopened.getFavoriteIds(), <String>{'daily-1'});
      expect(reopened.getLastPosition()?.categoryId, 'morning');
      expect(reopened.getLastPosition()?.dhikrId, 'daily-1');
      expect(reopened.getFontSize(), 40);
    },
  );
}

class _FakeAzkarLocalDataSource implements AzkarLocalDataSource {
  @override
  Future<List<AzkarCategoryModel>> loadCategories() async => const [
    AzkarCategoryModel(
      id: 'morning',
      titleKey: 'morning_azkar',
      isDaily: true,
      items: [
        DhikrModel(
          id: 'daily-1',
          arabicText: 'سُبْحَانَ اللهِ',
          translation: 'Glory is to Allah.',
          repeatCount: 3,
          reference: 'Muslim',
        ),
      ],
    ),
  ];
}

class _MemoryStorageService extends StorageService {
  final Map<String, String> strings = <String, String>{};
  final Map<String, Map<String, dynamic>> json =
      <String, Map<String, dynamic>>{};

  @override
  String? readString(String key) => strings[key];

  @override
  Map<String, dynamic>? readJson(String key) {
    final value = json[key];
    return value == null ? null : Map<String, dynamic>.from(value);
  }

  @override
  Future<bool> writeString(String key, String value) async {
    strings[key] = value;
    return true;
  }

  @override
  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    json[key] = Map<String, dynamic>.from(value);
    return true;
  }
}
