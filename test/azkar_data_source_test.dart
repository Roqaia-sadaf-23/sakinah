import 'package:flutter_test/flutter_test.dart';
import 'package:sakinah/features/azkar/data/datasources/azkar_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled Azkar assets expose all requested referenced categories',
    () async {
      final categories = await AssetAzkarLocalDataSource().loadCategories();

      expect(categories, hasLength(10));
      expect(
        categories.map((category) => category.id),
        containsAll(<String>[
          'morning',
          'evening',
          'after_prayer',
          'sleep',
          'waking',
          'mosque',
          'home',
          'food',
          'travel',
          'general',
        ]),
      );
      expect(
        categories.singleWhere((category) => category.id == 'morning').items,
        hasLength(26),
      );
      expect(
        categories.singleWhere((category) => category.id == 'evening').items,
        hasLength(24),
      );
      expect(
        categories
            .singleWhere((category) => category.id == 'after_prayer')
            .items,
        hasLength(13),
      );
      expect(
        categories.singleWhere((category) => category.id == 'mosque').items,
        hasLength(2),
      );

      final items = categories.expand((category) => category.items);
      expect(items.every((item) => item.arabicText.isNotEmpty), isTrue);
      expect(items.where((item) => item.reference.isNotEmpty).length, 98);
      expect(items.every((item) => item.repeatCount > 0), isTrue);
      expect(
        categories
            .singleWhere((category) => category.id == 'after_prayer')
            .items
            .first
            .repeatCount,
        3,
      );
    },
  );
}
