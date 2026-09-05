import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sakinah/core/ads/ads_controller.dart';
import 'package:sakinah/core/localization/app_translations.dart';
import 'package:sakinah/core/routing/app_route_observer.dart';
import 'package:sakinah/core/theme/app_theme.dart';
import 'package:sakinah/features/home/presentation/widgets/home_banner.dart';
import 'package:sakinah/features/home/presentation/widgets/privacy_options_setting.dart';
import 'package:sakinah/features/quran/domain/repositories/quran_repository.dart';
import 'package:sakinah/features/quran/domain/entities/reciter.dart';
import 'package:sakinah/features/quran/domain/services/quran_audio_player.dart';
import 'package:sakinah/features/quran/presentation/controllers/quran_audio_controller.dart';

import 'support/fake_ads_gateway.dart';

void main() {
  late FakeAdsGateway gateway;
  late AdsController ads;

  setUp(() async {
    Get.testMode = true;
    gateway = FakeAdsGateway()..allowed = true;
    ads = Get.put(AdsController(gateway));
    await ads.start();
  });

  tearDown(Get.reset);

  Widget app({bool arabicDark = false}) => GetMaterialApp(
    translations: AppTranslations(),
    locale: Locale(arabicDark ? 'ar' : 'en'),
    theme: arabicDark ? AppTheme.dark : AppTheme.light,
    navigatorObservers: [appRouteObserver],
    home: Scaffold(
      body: Column(
        children: [
          const PrivacyOptionsSetting(),
          TextButton(onPressed: () {}, child: const Text('Prayer action')),
        ],
      ),
      bottomNavigationBar: const HomeBanner(),
    ),
  );

  Future<void> mount(WidgetTester tester, {bool arabicDark = false}) async {
    await tester.pumpWidget(app(arabicDark: arabicDark));
    await tester.pumpAndSettle();
  }

  testWidgets('loading/failure reserve no empty ad space', (tester) async {
    await mount(tester);
    expect(gateway.banners, hasLength(1));
    expect(tester.getSize(find.byType(HomeBanner)).height, 0);
    gateway.banners.single.failed();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(HomeBanner)).height, 0);
    expect(find.text('Advertisement'), findsNothing);
    expect(gateway.banners.single.disposals, 1);
  });

  for (final arabicDark in [false, true]) {
    testWidgets(
      'one safe banner in ${arabicDark ? 'Arabic dark' : 'English light'} layout',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 640);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        gateway.autoLoad = true;
        await mount(tester, arabicDark: arabicDark);
        expect(find.byKey(const Key('fake-banner')), findsOneWidget);
        expect(
          find.text(arabicDark ? 'إعلان' : 'Advertisement'),
          findsOneWidget,
        );
        final bannerRect = tester.getRect(find.byKey(const Key('fake-banner')));
        final actionRect = tester.getRect(find.text('Prayer action'));
        expect(bannerRect.top - actionRect.bottom, greaterThanOrEqualTo(24));
        expect(bannerRect.bottom, lessThanOrEqualTo(640 - 12));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(gateway.banners.single.disposals, 1);
      },
    );
  }

  testWidgets(
    'route push removes/disposes ad; return creates only one replacement',
    (tester) async {
      gateway.autoLoad = true;
      await mount(tester);
      final first = gateway.banners.single;
      Get.to<void>(() => const Scaffold(body: Text('Quran / Qibla route')));
      await tester.pumpAndSettle();
      expect(first.disposals, 1);
      expect(
        find.byKey(const Key('fake-banner'), skipOffstage: false),
        findsNothing,
      );
      expect(ads.banner.value, isNull);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-banner')), findsOneWidget);
      expect(gateway.banners, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('loading, playing and paused recitation suppress ads on home', (
    tester,
  ) async {
    final audio = Get.put<QuranAudioController>(
      QuranAudioController(_UnusedRepository(), _UnusedPlayer()),
    );
    gateway.autoLoad = true;
    await mount(tester);
    for (final state in [
      QuranPlaybackState.loading,
      QuranPlaybackState.playing,
      QuranPlaybackState.paused,
    ]) {
      audio.playbackState.value = state;
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-banner')), findsNothing);
      expect(tester.getSize(find.byType(HomeBanner)).height, 0);
    }
    expect(gateway.banners, hasLength(1));
    expect(gateway.banners.single.disposals, 1);
    audio.playbackState.value = QuranPlaybackState.stopped;
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fake-banner')), findsOneWidget);
    expect(gateway.banners, hasLength(2));
  });

  testWidgets(
    'background disposes ads and resume restores eligible placement',
    (tester) async {
      gateway.autoLoad = true;
      await mount(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      expect(gateway.banners.single.disposals, 1);
      expect(ads.banner.value, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fake-banner')), findsOneWidget);
      expect(gateway.banners, hasLength(2));
    },
  );

  testWidgets(
    'privacy option appears only when required and reports form failure',
    (tester) async {
      await mount(tester);
      expect(find.text('Privacy options'), findsNothing);
      gateway.privacyRequired = true;
      ads.privacyRequired.value = true;
      gateway.failPrivacyForm = true;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Privacy options'));
      await tester.pumpAndSettle();
      expect(gateway.events, contains('privacy-form'));
      expect(
        find.text('Privacy options are unavailable. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Prayer action'), findsOneWidget);
      expect(ads.privacyBusy.value, isFalse);
    },
  );
}

class _UnusedRepository implements QuranRepository {
  @override
  Reciter getSelectedReciter() => SupportedReciters.misharyAlafasy;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedPlayer implements QuranAudioPlayer {
  @override
  Stream<void> get completedStream => const Stream.empty();
  @override
  Stream<Object> get errorStream => const Stream.empty();
  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
