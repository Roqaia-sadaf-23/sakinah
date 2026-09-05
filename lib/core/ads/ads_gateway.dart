import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_settings.dart';

/// The only boundary that contacts UMP / Mobile Ads; tests replace it entirely.
abstract class AdsGateway {
  Future<void> updateConsent();
  Future<void> showConsentIfRequired();
  Future<void> showPrivacyOptions();
  Future<bool> canRequestAds();
  Future<bool> privacyOptionsRequired();
  Future<void> initialize();
  Future<AdSize?> adaptiveSize(int width);
  BannerHandle createBanner({
    required AdSize size,
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  });
}

abstract class BannerHandle {
  AdSize get size;
  Widget buildWidget();
  Future<void> load();
  Future<void> dispose();
}

class GoogleAdsGateway implements AdsGateway {
  @override
  Future<void> updateConsent() {
    final result = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      // No age, geography, consent-sync ID or debug override is supplied.
      ConsentRequestParameters(),
      () => result.complete(),
      (error) => result.completeError(error),
    );
    return result.future;
  }

  @override
  Future<void> showConsentIfRequired() async {
    FormError? failure;
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      failure = error;
    });
    if (failure != null) throw failure!;
  }

  @override
  Future<void> showPrivacyOptions() async {
    FormError? failure;
    await ConsentForm.showPrivacyOptionsForm((error) {
      failure = error;
    });
    if (failure != null) throw failure!;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> privacyOptionsRequired() async =>
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
      PrivacyOptionsRequirementStatus.required;

  @override
  Future<void> initialize() async {
    await MobileAds.instance.updateRequestConfiguration(
      AdSettings.configuration,
    );
    await MobileAds.instance.initialize();
  }

  @override
  Future<AdSize?> adaptiveSize(int width) =>
      AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

  @override
  BannerHandle createBanner({
    required AdSize size,
    required VoidCallback onLoaded,
    required VoidCallback onFailed,
  }) => _GoogleBannerHandle(
    BannerAd(
      adUnitId: AdSettings.bannerId,
      request: AdSettings.request,
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (_, _) => onFailed(),
      ),
    ),
  );
}

class _GoogleBannerHandle implements BannerHandle {
  _GoogleBannerHandle(this._ad);

  final BannerAd _ad;
  bool _disposed = false;

  @override
  AdSize get size => _ad.size;

  @override
  Widget buildWidget() => AdWidget(key: ObjectKey(this), ad: _ad);

  @override
  Future<void> load() => _ad.load();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _ad.dispose();
  }
}
