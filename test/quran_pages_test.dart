import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/constants/app_constants.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/routing/app_routes.dart';
import 'package:sakinah/core/storage/storage_service.dart';
import 'package:sakinah/features/quran/data/services/asset_mushaf_page_source.dart';
import 'package:sakinah/features/quran/domain/entities/ayah.dart';
import 'package:sakinah/features/quran/domain/entities/mushaf_page.dart';
import 'package:sakinah/features/quran/domain/entities/quran_reading_position.dart';
import 'package:sakinah/features/quran/domain/entities/reciter.dart';
import 'package:sakinah/features/quran/domain/entities/surah.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/domain/repositories/mushaf_page_source.dart';
import 'package:sakinah/features/quran/domain/services/quran_audio_player.dart';
import 'package:sakinah/features/quran/domain/usecases/get_quran_surahs.dart';
import 'package:sakinah/features/quran/domain/usecases/get_surah.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_audio_controller.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_controller.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_reader_controller.dart';
import 'package:sakinah/features/quran/presentation/pages/quran_page.dart';
import 'package:sakinah/features/quran/presentation/pages/surah_page.dart';
import 'package:sakinah/features/quran/presentation/widgets/ayah_card.dart';
import 'package:sakinah/features/quran/presentation/widgets/quran_reading_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_WidgetMushafPageSource.prepare);
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('QuranPage renders 114 searchable Surahs on a narrow screen', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(_testApp(home: const QuranPage()));
    await _pumpReader(tester);

    expect(controllers.quran.surahs, hasLength(114));
    expect(find.text('Al-Faatiha'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '114');
    await tester.pump();
    expect(controllers.quran.filteredSurahs, hasLength(1));
    expect(find.text('Surah 114'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reading mode shows the fixed-layout Mushaf and plays a marker', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        initialRoute: AppRoutes.surahPath(1),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await _pumpReader(tester);

    expect(controllers.quran.currentSurah.value?.ayahs, hasLength(7));
    expect(find.byType(QuranReadingView), findsOneWidget);
    expect(find.byKey(const Key('mushaf-page-view')), findsOneWidget);
    expect(find.text('1 / 604'), findsOneWidget);
    expect(find.byType(AyahCard), findsNothing);

    final routeBeforeTap = Get.currentRoute;
    await tester.tap(find.byKey(const Key('mushaf-ayah-1-2')));
    await _pumpReader(tester);

    expect(controllers.audio.currentAyah.value?.numberInSurah, 2);
    expect(controllers.player.playedUrls.single, endsWith('/2.mp3'));
    expect(Get.currentRoute, routeBeforeTap);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mushaf swipes RTL through all 604 pages and saves boundaries', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        initialRoute: AppRoutes.surahPath(1),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await _pumpReader(tester);

    await tester.drag(
      find.byKey(const Key('mushaf-page-view')),
      const Offset(320, 0),
    );
    await _pumpReader(tester);
    expect(find.text('2 / 604'), findsOneWidget);
    expect(controllers.quran.lastReadingPosition.value?.surahNumber, 2);
    expect(controllers.quran.lastReadingPosition.value?.ayahNumber, 1);

    final pageView = tester.widget<PageView>(
      find.byKey(const Key('mushaf-page-view')),
    );
    pageView.controller!.jumpToPage(603);
    await _pumpReader(tester);
    expect(find.text('604 / 604'), findsOneWidget);
    expect(controllers.quran.lastReadingPosition.value?.surahNumber, 112);
    expect(controllers.quran.lastReadingPosition.value?.ayahNumber, 1);

    pageView.controller!.jumpToPage(0);
    await _pumpReader(tester);
    expect(find.text('1 / 604'), findsOneWidget);
    expect(controllers.quran.lastReadingPosition.value?.surahNumber, 1);
    expect(controllers.quran.lastReadingPosition.value?.ayahNumber, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Memorization mode preserves Ayah cards without refetching', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        initialRoute: AppRoutes.surahPath(1),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await _pumpReader(tester);
    expect(repository.surahRequests, 1);

    await tester.tap(find.text('Memorization'));
    await _pumpReader(tester);

    expect(find.byType(QuranReadingView), findsNothing);
    expect(find.byType(AyahCard), findsWidgets);
    await tester.tap(find.text('بِسْمِ ٱللَّهِ'));
    await tester.pump();
    expect(controllers.audio.currentAyah.value?.numberInSurah, 1);
    expect(controllers.player.playedUrls.single, endsWith('/1.mp3'));

    controllers.reader.setReadingMode(QuranReadingMode.reading);
    await _pumpReader(tester);
    expect(repository.surahRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quran font controls remain within 20 to 42', (tester) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        initialRoute: AppRoutes.surahPath(1),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await _pumpReader(tester);

    expect(find.byTooltip('Increase Quran font size'), findsNothing);

    controllers.reader.setReadingMode(QuranReadingMode.memorization);
    await _pumpReader(tester);
    expect(find.byType(AyahCard), findsWidgets);
    for (var index = 0; index < 7; index++) {
      await tester.tap(find.byTooltip('Increase Quran font size'));
      await tester.pump();
    }
    expect(controllers.reader.fontSize.value, 42);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byTooltip('Decrease Quran font size'));
    await _pumpReader(tester);
    for (var index = 0; index < 11; index++) {
      await tester.tap(find.byTooltip('Decrease Quran font size'));
      await tester.pump();
    }
    expect(controllers.reader.fontSize.value, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Continue reading restores the saved Ayah in the lazy list', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Get.toNamed<dynamic>(
                  AppRoutes.surahPath(1),
                  arguments: <String, dynamic>{'ayah': 7},
                ),
                child: const Text('open saved position'),
              ),
            ),
          ),
        ),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await tester.tap(find.text('open saved position'));
    await _pumpReader(tester);

    expect(controllers.quran.lastReadingPosition.value?.ayahNumber, 7);
    expect(find.byType(QuranReadingView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Last Ayah restores page 604 without losing the bookmark', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () => Get.toNamed<dynamic>(
              AppRoutes.surahPath(114),
              arguments: <String, dynamic>{'ayah': 6},
            ),
            child: const Text('open final Ayah'),
          ),
        ),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await tester.tap(find.text('open final Ayah'));
    await _pumpReader(tester);

    expect(find.text('604 / 604'), findsOneWidget);
    expect(controllers.quran.lastReadingPosition.value?.surahNumber, 114);
    expect(controllers.quran.lastReadingPosition.value?.ayahNumber, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quran reader is constraint-safe on small and large screens', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        initialRoute: AppRoutes.surahPath(1),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await _pumpReader(tester);

    final smallPageSize = tester.getSize(
      find.byKey(const Key('mushaf-page-1')),
    );
    expect(smallPageSize.width, lessThanOrEqualTo(320));
    expect(
      smallPageSize.width / smallPageSize.height,
      moreOrLessEquals(345 / 550),
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(900, 1200);
    await _pumpReader(tester);
    expect(
      tester.getSize(find.byKey(const Key('mushaf-page-1'))).width,
      lessThanOrEqualTo(AppConstants.maxContentWidth),
    );

    controllers.reader.setReadingMode(QuranReadingMode.memorization);
    await _pumpReader(tester);
    expect(find.byType(AyahCard), findsWidgets);
    expect(
      tester.getSize(find.byType(AyahCard).first).width,
      lessThanOrEqualTo(AppConstants.maxContentWidth),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar and system back return to the existing Quran route', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(
      _testApp(
        home: const QuranPage(),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
      ),
    );
    await _pumpReader(tester);
    await tester.enterText(find.byType(TextField), 'Faatiha');
    await tester.pump();

    await tester.tap(find.text('Al-Faatiha'));
    await _pumpReader(tester);
    expect(Get.currentRoute, AppRoutes.surahPath(1));
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await _pumpReader(tester);
    expect(find.byType(QuranPage), findsOneWidget);
    expect(controllers.quran.searchQuery.value, 'Faatiha');
    expect(find.text('Al-Faatiha'), findsOneWidget);

    await tester.tap(find.text('Al-Faatiha'));
    await _pumpReader(tester);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await _pumpReader(tester);
    expect(find.byType(QuranPage), findsOneWidget);
    expect(find.byType(SurahPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Surah back affordance follows Arabic RTL direction', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    _registerControllers(_WidgetQuranRepository());

    await tester.pumpWidget(
      _testApp(
        home: const QuranPage(),
        pages: [GetPage(name: AppRoutes.quranSurah, page: SurahPage.new)],
        locale: const Locale('ar'),
      ),
    );
    await _pumpReader(tester);
    await tester.tap(find.text('Al-Faatiha'));
    await _pumpReader(tester);

    final backButton = find.byType(BackButton);
    expect(backButton, findsOneWidget);
    expect(Directionality.of(tester.element(backButton)), TextDirection.rtl);
    await tester.tap(backButton);
    await _pumpReader(tester);
    expect(find.byType(QuranPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

({
  QuranController quran,
  QuranAudioController audio,
  QuranReaderController reader,
  _WidgetAudioPlayer player,
})
_registerControllers(_WidgetQuranRepository repository) {
  final player = _WidgetAudioPlayer();
  final storage = _MemoryStorageService();
  final quran = Get.put(
    QuranController(
      GetQuranSurahs(repository),
      GetSurah(repository),
      repository,
    ),
  );
  final audio = Get.put(QuranAudioController(repository, player));
  final reader = Get.put(QuranReaderController(storage));
  Get.put<MushafPageSource>(_WidgetMushafPageSource());
  return (quran: quran, audio: audio, reader: reader, player: player);
}

Widget _testApp({
  Widget? home,
  String? initialRoute,
  List<GetPage<dynamic>> pages = const [],
  Locale locale = const Locale('en'),
}) => GetMaterialApp(
  home: home,
  initialRoute: initialRoute,
  getPages: pages,
  translations: AppTranslations(),
  locale: locale,
);

void _setNarrowScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpReader(WidgetTester tester) async {
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

class _WidgetQuranRepository implements QuranRepository {
  QuranReadingPosition? position;
  Reciter reciter = SupportedReciters.misharyAlafasy;
  int surahRequests = 0;

  @override
  Future<List<Surah>> getSurahs({bool forceRefresh = false}) async =>
      List<Surah>.generate(
        114,
        (index) => Surah(
          number: index + 1,
          arabicName: index == 0 ? 'سُورَةُ ٱلْفَاتِحَةِ' : 'سورة ${index + 1}',
          englishName: index == 0 ? 'Al-Faatiha' : 'Surah ${index + 1}',
          englishNameTranslation: index == 0 ? 'The Opening' : 'Translation',
          revelationType: index.isEven ? 'Meccan' : 'Medinan',
          numberOfAyahs: index == 0
              ? 7
              : index == 113
              ? 6
              : 1,
        ),
        growable: false,
      );

  @override
  Future<Surah> getSurah(int surahNumber, {bool forceRefresh = false}) async {
    surahRequests++;
    final isLastSurah = surahNumber == 114;
    final ayahCount = isLastSurah ? 6 : 7;
    return Surah(
      number: surahNumber,
      arabicName: isLastSurah ? 'النَّاس' : 'سُورَةُ ٱلْفَاتِحَةِ',
      englishName: isLastSurah ? 'An-Naas' : 'Al-Faatiha',
      englishNameTranslation: isLastSurah ? 'Mankind' : 'The Opening',
      revelationType: 'Meccan',
      numberOfAyahs: ayahCount,
      ayahs: List<Ayah>.generate(
        ayahCount,
        (index) => Ayah(
          number: isLastSurah ? 6231 + index : index + 1,
          numberInSurah: index + 1,
          text: index == 0
              ? 'بِسْمِ ٱللَّهِ'
              : List<String>.filled(12, 'آية ${index + 1}').join(' '),
          juz: 1,
          page: isLastSurah ? 604 : 1,
        ),
        growable: false,
      ),
    );
  }

  @override
  Future<Map<int, String>> getAyahAudioUrls({
    required int surahNumber,
    required Reciter reciter,
  }) async => <int, String>{
    for (var index = 1; index <= (surahNumber == 114 ? 6 : 7); index++)
      index: 'https://example.com/${reciter.audioIdentifier}/$index.mp3',
  };

  @override
  QuranReadingPosition? getLastReadingPosition() => position;

  @override
  Reciter getSelectedReciter() => reciter;

  @override
  Future<void> saveLastReadingPosition(QuranReadingPosition position) async {
    this.position = position;
  }

  @override
  Future<void> saveSelectedReciter(Reciter reciter) async {
    this.reciter = reciter;
  }
}

class _WidgetMushafPageSource implements MushafPageSource {
  static late MushafMetadata _metadata;

  static Future<void> prepare() async {
    _metadata = await AssetMushafPageSource().loadMetadata();
  }

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 345 550">
  <rect width="345" height="550" fill="#fffcf5"/>
  <path class="ayahPolygon" fill-opacity="0" d="M 0 0 L 1 0 Z"/>
</svg>
''';

  @override
  Future<MushafMetadata> loadMetadata() =>
      Future<MushafMetadata>.value(_metadata);

  @override
  Future<String> loadPageSvg(int pageNumber) async => _svg;

  @override
  void prefetchPage(int pageNumber) {}
}

class _WidgetAudioPlayer implements QuranAudioPlayer {
  final _completed = StreamController<void>.broadcast();
  final playedUrls = <String>[];

  @override
  Stream<void> get completedStream => _completed.stream;

  @override
  Stream<Object> get errorStream => const Stream<Object>.empty();

  @override
  Future<void> playUrl(String url) async => playedUrls.add(url);

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() => _completed.close();
}

class _MemoryStorageService extends StorageService {
  final Map<String, String> values = <String, String>{};

  @override
  String? readString(String key) => values[key];

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }
}
