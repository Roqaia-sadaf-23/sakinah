import 'dart:async';

import 'package:get/get.dart';

import 'ads_gateway.dart';

class AdsController extends GetxController {
  AdsController(this._gateway);

  final AdsGateway _gateway;
  final ready = false.obs;
  final privacyRequired = false.obs;
  final privacyBusy = false.obs;
  final banner = Rxn<BannerHandle>();

  Future<void>? _startup;
  bool _initialized = false;
  bool _closed = false;
  bool _visible = false;
  int _width = 0;
  Object? _orientation;
  int _revision = 0;
  BannerHandle? _pending;

  @override
  void onReady() {
    super.onReady();
    unawaited(start());
  }

  Future<void> start() => _startup ??= _start();

  Future<void> _start() async {
    privacyBusy.value = true;
    try {
      await _gateway.updateConsent();
      if (_closed) return;
      // Discover the privacy entry point even if loading the form later fails.
      await _refreshPrivacyRequirement();
      await _gateway.showConsentIfRequired();
    } catch (_) {
      // UMP may still allow ads using a valid consent from a previous session.
      // Never replace its decision with a locally stored consent flag.
    } finally {
      if (!_closed) {
        await _applyConsent();
        privacyBusy.value = false;
      }
    }
  }

  /// Returns false on errors so the settings UI can offer a non-blocking retry.
  Future<bool> showPrivacyOptions() async {
    if (_closed || privacyBusy.value || !privacyRequired.value) return false;
    privacyBusy.value = true;
    ready.value = false;
    _clearBanner();
    var succeeded = true;
    try {
      await _gateway.showPrivacyOptions();
    } catch (_) {
      succeeded = false;
    } finally {
      if (!_closed) {
        await _applyConsent();
        privacyBusy.value = false;
      }
    }
    return succeeded;
  }

  Future<void> _refreshPrivacyRequirement() async {
    try {
      final required = await _gateway.privacyOptionsRequired();
      if (!_closed) privacyRequired.value = required;
    } catch (_) {
      // Preserve an already-required entry point if a later status read fails.
    }
  }

  Future<void> _applyConsent() async {
    await _refreshPrivacyRequirement();
    try {
      if (_closed || !await _gateway.canRequestAds()) return;
      if (_closed) return;
      if (!_initialized) {
        await _gateway.initialize();
        _initialized = true;
      }
      if (_closed) return;
      // Recheck after asynchronous initialization before permitting any load.
      final allowed = await _gateway.canRequestAds();
      if (_closed) return;
      ready.value = allowed;
      if (allowed) unawaited(_loadBanner());
    } catch (_) {
      if (!_closed) ready.value = false;
    }
  }

  /// One placement, owned by the home page; hidden routes/audio/backgrounds
  /// invalidate pending async work and dispose any loaded or loading banner.
  void updatePlacement({
    required bool visible,
    required int width,
    required Object orientation,
  }) {
    if (_closed) return;
    if (_visible == visible && _width == width && _orientation == orientation) {
      return;
    }
    _visible = visible;
    _width = width;
    _orientation = orientation;
    _clearBanner();
    if (visible) unawaited(_loadBanner());
  }

  Future<void> _loadBanner() async {
    if (_closed || !ready.value || !_visible || _width <= 0) return;
    final revision = ++_revision;
    try {
      final size = await _gateway.adaptiveSize(_width);
      if (!_isCurrent(revision) || size == null) return;
      if (!await _gateway.canRequestAds() || !_isCurrent(revision)) return;
      final ad = _gateway.createBanner(
        size: size,
        onLoaded: () {
          if (_isCurrent(revision)) banner.value = _pending;
        },
        onFailed: () {
          if (_isCurrent(revision)) _clearBanner();
        },
      );
      _pending = ad;
      await ad.load();
    } catch (_) {
      if (_isCurrent(revision)) _clearBanner();
    }
  }

  bool _isCurrent(int revision) =>
      !_closed && ready.value && _visible && revision == _revision;

  void _clearBanner() {
    _revision++;
    final ad = _pending;
    _pending = null;
    banner.value = null;
    if (ad != null) unawaited(ad.dispose().catchError((_) {}));
  }

  @override
  void onClose() {
    _closed = true;
    _clearBanner();
    super.onClose();
  }
}
