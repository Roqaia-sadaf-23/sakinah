import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sakinah/core/ads/ads_gateway.dart';

class FakeAdsGateway implements AdsGateway {
  final events = <String>[];
  final banners = <FakeBannerHandle>[];
  bool allowed = false;
  bool privacyRequired = false;
  bool failUpdate = false;
  bool failConsentForm = false;
  bool failPrivacyForm = false;
  bool failInitialization = false;
  bool failLoad = false;
  bool noSize = false;
  bool autoLoad = false;
  Completer<void>? updateGate;
  Completer<void>? consentGate;
  Completer<void>? privacyGate;
  Completer<AdSize?>? sizeGate;

  @override
  Future<void> updateConsent() async {
    events.add('update');
    await updateGate?.future;
    if (failUpdate) throw StateError('Offline');
  }

  @override
  Future<void> showConsentIfRequired() async {
    events.add('consent-form');
    await consentGate?.future;
    if (failConsentForm) throw StateError('Form unavailable');
  }

  @override
  Future<void> showPrivacyOptions() async {
    events.add('privacy-form');
    await privacyGate?.future;
    if (failPrivacyForm) throw StateError('Form unavailable');
  }

  @override
  Future<bool> canRequestAds() async {
    events.add('can-request');
    return allowed;
  }

  @override
  Future<bool> privacyOptionsRequired() async => privacyRequired;

  @override
  Future<void> initialize() async {
    events.add('initialize');
    if (failInitialization) throw StateError('SDK unavailable');
  }

  @override
  Future<AdSize?> adaptiveSize(int width) async {
    events.add('size:$width');
    if (sizeGate != null) return sizeGate!.future;
    return noSize ? null : AdSize(width: width, height: 60);
  }

  @override
  BannerHandle createBanner({
    required AdSize size,
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) {
    events.add('create');
    final banner = FakeBannerHandle(
      size,
      onLoaded,
      onFailed,
      autoLoad: autoLoad,
      failLoad: failLoad,
    );
    banners.add(banner);
    return banner;
  }
}

class FakeBannerHandle implements BannerHandle {
  FakeBannerHandle(
    this.size,
    this.loaded,
    this.failed, {
    this.autoLoad = false,
    this.failLoad = false,
  });

  @override
  final AdSize size;
  final VoidCallback loaded;
  final VoidCallback failed;
  final bool autoLoad;
  final bool failLoad;
  int loads = 0;
  int disposals = 0;

  @override
  Widget buildWidget() => const SizedBox(key: Key('fake-banner'));

  @override
  Future<void> load() async {
    loads++;
    if (failLoad) throw StateError('Load failed');
    if (autoLoad) loaded();
  }

  @override
  Future<void> dispose() async => disposals++;
}
