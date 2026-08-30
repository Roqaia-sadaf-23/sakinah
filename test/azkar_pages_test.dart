import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/routing/app_routes.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/azkar/data/datasources/azkar_local_data_source.dart';
import 'package:sakinah/features/azkar/data/models/azkar_category_model.dart';
import 'package:sakinah/features/azkar/data/models/dhikr_model.dart';
import 'package:sakinah/features/azkar/data/repositories/azkar_repository_impl.dart';
import 'package:sakinah/features/azkar/domain/usecases/get_azkar_categories.dart';
import 'package:sakinah/features/azkar/presentation/controllers/azkar_controller.dart';
import 'package:sakinah/features/azkar/presentation/pages/azkar_category_page.dart';
import 'package:sakinah/features/azkar/presentation/pages/azkar_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('Azkar categories and narrow focused reader render safely', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final controller = _registerController();

    await tester.pumpWidget(_testApp(home: const AzkarPage()));
    await _pumpUntil(
      tester,
      () => controller.status.value == AzkarViewStatus.success,
    );

    expect(find.text('Morning Azkar'), findsOneWidget);
    expect(controller.categories, hasLength(10));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Morning Azkar'));
    await tester.pump();
    await _pumpUntil(
      tester,
      () => controller.currentCategory.value?.id == 'morning',
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.currentCategory.value?.id, 'morning');
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Tap to remember'));
    await tester.pump();
    expect(controller.countFor(controller.currentDhikr!), 1);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('font controls clamp and favorites survive reader updates', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final controller = _registerController();

    await tester.pumpWidget(
      _testApp(initialRoute: AppRoutes.azkarCategoryPath('morning')),
    );
    await _pumpUntil(
      tester,
      () => controller.currentCategory.value?.id == 'morning',
    );
    await tester.pump(const Duration(milliseconds: 500));

    for (var index = 0; index < 10; index++) {
      await tester.tap(find.byTooltip('Increase Azkar text size'));
      await tester.pump();
    }
    expect(controller.fontSize.value, 40);

    await tester.tap(find.byTooltip('Add to favorites'));
    await tester.pump();
    expect(controller.favoriteIds, contains(controller.currentDhikr!.id));
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AzkarController _registerController() {
  final repository = AzkarRepositoryImpl(
    _WidgetAzkarLocalDataSource(),
    _MemoryStorageService(),
  );
  return Get.put(AzkarController(GetAzkarCategories(repository), repository));
}

class _WidgetAzkarLocalDataSource implements AzkarLocalDataSource {
  static const _categories = <(String, String)>[
    ('morning', 'morning_azkar'),
    ('evening', 'evening_azkar'),
    ('after_prayer', 'after_prayer_azkar'),
    ('sleep', 'sleep_azkar'),
    ('waking', 'wake_up_azkar'),
    ('mosque', 'mosque_azkar'),
    ('home', 'home_azkar'),
    ('food', 'food_azkar'),
    ('travel', 'travel_azkar'),
    ('general', 'general_azkar'),
  ];

  @override
  Future<List<AzkarCategoryModel>> loadCategories() async => [
    for (final category in _categories)
      AzkarCategoryModel(
        id: category.$1,
        titleKey: category.$2,
        isDaily:
            category.$1 == 'morning' ||
            category.$1 == 'evening' ||
            category.$1 == 'after_prayer',
        items: [
          DhikrModel(
            id: '${category.$1}-1',
            arabicText: 'سُبْحَانَ اللهِ',
            translation: 'Glory is to Allah.',
            repeatCount: 1,
            reference: 'Muslim',
          ),
        ],
      ),
  ];
}

Widget _testApp({Widget? home, String? initialRoute}) => GetMaterialApp(
  home: home,
  initialRoute: initialRoute,
  getPages: [
    GetPage(name: AppRoutes.azkar, page: AzkarPage.new),
    GetPage(name: AppRoutes.azkarCategory, page: AzkarCategoryPage.new),
  ],
  translations: AppTranslations(),
  locale: const Locale('en'),
);

void _setNarrowScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  final controller = Get.find<AzkarController>();
  fail(
    'Timed out waiting for the Azkar controller state. '
    'status=${controller.status.value}, categories=${controller.categories.length}, '
    'error=${controller.errorKey.value}',
  );
}

class _MemoryStorageService extends StorageService {
  final Map<String, String> strings = <String, String>{};
  final Map<String, Map<String, dynamic>> json =
      <String, Map<String, dynamic>>{};

  @override
  String? readString(String key) => strings[key];

  @override
  Map<String, dynamic>? readJson(String key) => json[key];

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
