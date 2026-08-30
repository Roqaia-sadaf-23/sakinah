import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/routing/app_routes.dart';
import 'package:sakinah/features/quran/domain/entities/ayah.dart';
import 'package:sakinah/features/quran/domain/entities/quran_reading_position.dart';
import 'package:sakinah/features/quran/domain/entities/reciter.dart';
import 'package:sakinah/features/quran/domain/entities/surah.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/domain/services/quran_audio_player.dart';
import 'package:sakinah/features/quran/domain/usecases/get_quran_surahs.dart';
import 'package:sakinah/features/quran/domain/usecases/get_surah.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_audio_controller.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_controller.dart';
import 'package:sakinah/features/quran/presentation/pages/quran_page.dart';
import 'package:sakinah/features/quran/presentation/pages/surah_page.dart';
import 'package:sakinah/features/quran/presentation/widgets/ayah_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('QuranPage renders 114 searchable Surahs on a narrow screen', (
    tester,
  ) async {
    _setNarrowScreen(tester);
    final repository = _WidgetQuranRepository();
    final controllers = _registerControllers(repository);

    await tester.pumpWidget(_testApp(home: const QuranPage()));
    await tester.pumpAndSettle();

    expect(controllers.quran.surahs, hasLength(114));
    expect(find.text('Al-Faatiha'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '114');
    await tester.pump();
    expect(controllers.quran.filteredSurahs, hasLength(1));
    expect(find.text('Surah 114'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SurahPage displays RTL Ayahs and plays a tapped Ayah', (
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
    await tester.pumpAndSettle();

    expect(controllers.quran.currentSurah.value?.ayahs, hasLength(7));
    expect(find.byType(AyahCard), findsWidgets);
    expect(find.text('بِسْمِ ٱللَّهِ'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('بِسْمِ ٱللَّهِ'));
    await tester.pump();

    expect(controllers.audio.currentAyah.value?.numberInSurah, 1);
    expect(controllers.player.playedUrls.single, endsWith('/1.mp3'));
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
    await tester.pumpAndSettle();

    expect(controllers.quran.lastReadingPosition.value?.ayahNumber, 7);
    expect(find.text('آية 7'), findsOneWidget);
    final scrollView = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    expect(scrollView.controller?.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}

({QuranController quran, QuranAudioController audio, _WidgetAudioPlayer player})
_registerControllers(_WidgetQuranRepository repository) {
  final player = _WidgetAudioPlayer();
  final quran = Get.put(
    QuranController(
      GetQuranSurahs(repository),
      GetSurah(repository),
      repository,
    ),
  );
  final audio = Get.put(QuranAudioController(repository, player));
  return (quran: quran, audio: audio, player: player);
}

Widget _testApp({
  Widget? home,
  String? initialRoute,
  List<GetPage<dynamic>> pages = const [],
}) => GetMaterialApp(
  home: home,
  initialRoute: initialRoute,
  getPages: pages,
  translations: AppTranslations(),
  locale: const Locale('en'),
);

void _setNarrowScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

class _WidgetQuranRepository implements QuranRepository {
  QuranReadingPosition? position;
  Reciter reciter = SupportedReciters.misharyAlafasy;

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
          numberOfAyahs: index == 0 ? 7 : 1,
        ),
        growable: false,
      );

  @override
  Future<Surah> getSurah(int surahNumber, {bool forceRefresh = false}) async =>
      Surah(
        number: 1,
        arabicName: 'سُورَةُ ٱلْفَاتِحَةِ',
        englishName: 'Al-Faatiha',
        englishNameTranslation: 'The Opening',
        revelationType: 'Meccan',
        numberOfAyahs: 7,
        ayahs: List<Ayah>.generate(
          7,
          (index) => Ayah(
            number: index + 1,
            numberInSurah: index + 1,
            text: index == 0 ? 'بِسْمِ ٱللَّهِ' : 'آية ${index + 1}',
            juz: 1,
            page: 1,
          ),
          growable: false,
        ),
      );

  @override
  Future<Map<int, String>> getAyahAudioUrls({
    required int surahNumber,
    required Reciter reciter,
  }) async => <int, String>{
    for (var index = 1; index <= 7; index++)
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
