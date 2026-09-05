import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sakinah/core/ads/ad_settings.dart';
import 'package:sakinah/core/ads/ads_controller.dart';

import 'support/fake_ads_gateway.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAdsGateway gateway;
  late AdsController controller;

  setUp(() {
    gateway = FakeAdsGateway();
    controller = AdsController(gateway);
  });
  tearDown(() => controller.onClose());

  void show({int width = 360, String orientation = 'portrait'}) => controller
      .updatePlacement(visible: true, width: width, orientation: orientation);
  void hide() => controller.updatePlacement(
    visible: false,
    width: 360,
    orientation: 'portrait',
  );

  test('ads default to Google test ID independently of release mode', () {
    expect(AdSettings.useProduction, isFalse);
    expect(AdSettings.bannerId, 'ca-app-pub-3940256099942544/6300978111');
    expect(AdSettings.request.nonPersonalizedAds, isTrue);
    expect(AdSettings.request.keywords, isNull);
    expect(AdSettings.request.contentUrl, isNull);
    expect(AdSettings.configuration.maxAdContentRating, MaxAdContentRating.g);
    expect(
      AdSettings.configuration.ageRestrictedTreatment,
      AgeRestrictedTreatment.unspecified,
    );
  });

  test(
    'no initialization or banner before consent update and form finish',
    () async {
      gateway.allowed = true;
      gateway.updateGate = Completer<void>();
      gateway.consentGate = Completer<void>();
      show();
      final startup = controller.start();
      await flush();
      expect(gateway.events, ['update']);
      gateway.updateGate!.complete();
      await flush();
      expect(gateway.events, ['update', 'consent-form']);
      gateway.consentGate!.complete();
      await startup;
      await flush();
      expect(
        gateway.events.indexOf('initialize'),
        greaterThan(gateway.events.indexOf('can-request')),
      );
      expect(gateway.banners, hasLength(1));
    },
  );

  test('denied consent never initializes or requests ads', () async {
    show();
    await controller.start();
    await flush();
    expect(controller.ready.value, isFalse);
    expect(gateway.events, isNot(contains('initialize')));
    expect(gateway.banners, isEmpty);
  });

  test('consent error with no prior permission fails closed', () async {
    gateway.failUpdate = true;
    show();
    await controller.start();
    expect(gateway.events, isNot(contains('consent-form')));
    expect(gateway.events, isNot(contains('initialize')));
  });

  test('consent error only uses previous consent when UMP permits', () async {
    gateway.failUpdate = true;
    gateway.allowed = true;
    show();
    await controller.start();
    await flush();
    expect(controller.ready.value, isTrue);
    expect(gateway.banners, hasLength(1));
  });

  test(
    'form failure preserves required privacy option without blocking app',
    () async {
      gateway.failConsentForm = true;
      gateway.privacyRequired = true;
      await controller.start();
      expect(controller.privacyRequired.value, isTrue);
      expect(controller.privacyBusy.value, isFalse);
      expect(controller.ready.value, isFalse);
    },
  );

  test(
    'duplicate startup and identical layout create only one banner',
    () async {
      gateway.allowed = true;
      show();
      await Future.wait([controller.start(), controller.start()]);
      show();
      show();
      await flush();
      expect(gateway.events.where((e) => e == 'update'), hasLength(1));
      expect(gateway.events.where((e) => e == 'initialize'), hasLength(1));
      expect(gateway.banners, hasLength(1));
      expect(gateway.banners.single.loads, 1);
    },
  );

  test('SDK failure does not escape or request a banner', () async {
    gateway.allowed = true;
    gateway.failInitialization = true;
    show();
    await controller.start();
    expect(controller.ready.value, isFalse);
    expect(gateway.banners, isEmpty);
  });

  test('no valid adaptive size means no banner', () async {
    gateway.allowed = true;
    gateway.noSize = true;
    show();
    await controller.start();
    await flush();
    expect(gateway.banners, isEmpty);
  });

  test('hidden page makes no banner request even with consent', () async {
    gateway.allowed = true;
    await controller.start();
    await flush();
    expect(gateway.banners, isEmpty);
  });

  test('hidden placement cancels pending adaptive size lookup', () async {
    gateway.allowed = true;
    gateway.sizeGate = Completer<AdSize?>();
    show();
    await controller.start();
    hide();
    gateway.sizeGate!.complete(const AdSize(width: 360, height: 60));
    await flush();
    expect(gateway.banners, isEmpty);
  });

  test(
    'failure disposes the ad, collapses placement and does not retry-loop',
    () async {
      gateway.allowed = true;
      show();
      await controller.start();
      await flush();
      final ad = gateway.banners.single;
      ad.failed();
      show();
      ad.loaded(); // Late native callbacks must not resurrect an ad.
      expect(controller.banner.value, isNull);
      expect(ad.disposals, 1);
      expect(gateway.banners, hasLength(1));
    },
  );

  test('load exception disposes the candidate', () async {
    gateway.allowed = true;
    gateway.failLoad = true;
    show();
    await controller.start();
    await flush();
    expect(controller.banner.value, isNull);
    expect(gateway.banners.single.disposals, 1);
  });

  test(
    'navigation/background/recitation hides and disposes loaded ad',
    () async {
      gateway.allowed = true;
      show();
      await controller.start();
      await flush();
      final ad = gateway.banners.single;
      ad.loaded();
      expect(controller.banner.value, same(ad));
      hide();
      ad.loaded();
      expect(controller.banner.value, isNull);
      expect(ad.disposals, 1);
    },
  );

  test('rotation disposes the old ad and loads the new width once', () async {
    gateway.allowed = true;
    show();
    await controller.start();
    await flush();
    final first = gateway.banners.single;
    show(width: 600, orientation: 'landscape');
    await flush();
    first.loaded();
    expect(first.disposals, 1);
    expect(controller.banner.value, isNull);
    expect(gateway.banners.last.size.width, 600);
    gateway.banners.last.loaded();
    expect(controller.banner.value, same(gateway.banners.last));
  });

  test(
    'privacy form immediately removes ads; revocation prevents future loads',
    () async {
      gateway.allowed = true;
      gateway.privacyRequired = true;
      gateway.privacyGate = Completer<void>();
      show();
      await controller.start();
      await flush();
      final ad = gateway.banners.single;
      ad.loaded();
      final form = controller.showPrivacyOptions();
      expect(controller.banner.value, isNull);
      expect(ad.disposals, 1);
      expect(controller.privacyBusy.value, isTrue);
      expect(await controller.showPrivacyOptions(), isFalse);
      gateway.allowed = false;
      gateway.privacyGate!.complete();
      expect(await form, isTrue);
      hide();
      show();
      await flush();
      expect(controller.ready.value, isFalse);
      expect(gateway.banners, hasLength(1));
    },
  );

  test(
    'privacy form error is nonblocking and does not initialize twice',
    () async {
      gateway.allowed = true;
      gateway.privacyRequired = true;
      gateway.failPrivacyForm = true;
      await controller.start();
      expect(await controller.showPrivacyOptions(), isFalse);
      expect(controller.privacyBusy.value, isFalse);
      expect(controller.privacyRequired.value, isTrue);
      expect(gateway.events.where((e) => e == 'initialize'), hasLength(1));
    },
  );

  test('closing during startup prevents late initialization', () async {
    gateway.allowed = true;
    gateway.updateGate = Completer<void>();
    final startup = controller.start();
    controller.onClose();
    gateway.updateGate!.complete();
    await startup;
    expect(gateway.events, isNot(contains('initialize')));
  });
}
