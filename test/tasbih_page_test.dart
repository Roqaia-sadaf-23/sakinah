import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/routing/app_pages.dart';
import 'package:sakinah/core/routing/app_routes.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/home/presentation/widgets/quick_actions_section.dart';
import 'package:sakinah/features/tasbih/presentation/controllers/tasbih_controller.dart';
import 'package:sakinah/features/tasbih/presentation/pages/tasbih_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('narrow Tasbih screen increments and resets after confirmation', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final controller = _registerController();

    await tester.pumpWidget(_testApp(home: const TasbihPage()));
    await tester.pump();

    expect(find.text('سبحان الله'), findsWidgets);
    expect(find.text('0 / 33'), findsOneWidget);
    expect(find.text('Tap to count'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('tasbih-counter-button')));
    await tester.pump();
    expect(controller.currentCount.value, 1);
    expect(find.text('1 / 33'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Reset Tasbih?'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your current Tasbih session progress will be cleared.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Reset'));
    await tester.pumpAndSettle();
    expect(controller.currentCount.value, 0);
    expect(find.text('0 / 33'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full sequence reaches the calm 100-count completion view', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final controller = _registerController();
    await tester.pumpWidget(_testApp(home: const TasbihPage()));
    await tester.pump();

    for (var tap = 0; tap < TasbihController.totalTarget; tap++) {
      controller.increment();
      await tester.pump(const Duration(milliseconds: 1));
    }

    expect(controller.totalCompleted, 100);
    expect(controller.isCompleted.value, isTrue);
    expect(find.text('Tasbih completed'), findsOneWidget);
    expect(find.text('You completed 100 remembrances.'), findsOneWidget);
    expect(find.text('Restart Tasbih'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('production Tasbih route opens with its binding in Arabic', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    Get.put<StorageService>(_MemoryStorageService());

    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.tasbih,
        getPages: [
          AppPages.pages.singleWhere((page) => page.name == AppRoutes.tasbih),
        ],
        translations: AppTranslations(),
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TasbihPage), findsOneWidget);
    expect(find.text('التسبيح'), findsOneWidget);
    expect(find.text('اضغط للتسبيح'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home Tasbih quick action opens the configured route', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    await tester.pumpWidget(
      GetMaterialApp(
        home: const Scaffold(
          body: SingleChildScrollView(child: QuickActionsSection()),
        ),
        getPages: [
          GetPage(
            name: AppRoutes.tasbih,
            page: () => const Scaffold(body: Text('tasbih destination')),
          ),
        ],
        translations: AppTranslations(),
        locale: const Locale('en'),
      ),
    );

    await tester.tap(find.text('Tasbih'));
    await tester.pumpAndSettle();
    expect(find.text('tasbih destination'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TasbihController _registerController() {
  final storage = _MemoryStorageService();
  Get.put<StorageService>(storage);
  return Get.put(
    TasbihController(
      storage,
      now: () => DateTime(2026, 8, 30, 12),
      transitionDuration: Duration.zero,
    ),
  );
}

Widget _testApp({required Widget home}) => GetMaterialApp(
  home: home,
  translations: AppTranslations(),
  locale: const Locale('en'),
);

void _setNarrowScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(720, 1600);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _MemoryStorageService extends StorageService {
  final Map<String, Map<String, dynamic>> values =
      <String, Map<String, dynamic>>{};

  @override
  Map<String, dynamic>? readJson(String key) => values[key];

  @override
  Future<bool> writeJson(String key, Map<String, dynamic> value) async {
    values[key] = Map<String, dynamic>.from(value);
    return true;
  }
}
