import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/ads/ads_controller.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_route_observer.dart';
import '../../../quran/presentation/controllers/quran_audio_controller.dart';

class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key});

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner>
    with RouteAware, WidgetsBindingObserver {
  ModalRoute<dynamic>? _route;
  bool _foreground = true;
  bool _routeVisible = true;
  int _layoutRevision = 0;

  AdsController? get _ads =>
      Get.isRegistered<AdsController>() ? Get.find<AdsController>() : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
    _routeVisible = route?.isCurrent ?? true;
  }

  void _hide() {
    _layoutRevision++;
    _ads?.updatePlacement(visible: false, width: 0, orientation: 'hidden');
  }

  @override
  void didPushNext() {
    _hide();
    setState(() => _routeVisible = false);
  }

  @override
  void didPopNext() => setState(() => _routeVisible = true);

  @override
  void didPop() => _hide();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (!foreground) _hide();
    if (mounted) setState(() => _foreground = foreground);
  }

  @override
  Widget build(BuildContext context) {
    final ads = _ads;
    if (ads == null) return const SizedBox.shrink();
    final orientation = MediaQuery.orientationOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    return Obx(() {
      final ad = ads.banner.value;
      final audio = Get.isRegistered<QuranAudioController>()
          ? Get.find<QuranAudioController>()
          : null;
      final playback = audio?.playbackState.value;
      final recitationActive =
          playback == QuranPlaybackState.playing ||
          playback == QuranPlaybackState.loading ||
          playback == QuranPlaybackState.paused;
      final visible = _foreground && _routeVisible && !recitationActive;
      return LayoutBuilder(
        builder: (context, constraints) {
          final width =
              (constraints.maxWidth -
                      math.max(16, safePadding.left) -
                      math.max(16, safePadding.right))
                  .clamp(0, AppConstants.maxContentWidth)
                  .floor();
          final revision = ++_layoutRevision;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || revision != _layoutRevision) return;
            ads.updatePlacement(
              visible: visible,
              width: width,
              orientation: orientation,
            );
          });
          if (!visible || ad == null || ad.size.width > width) {
            return const SizedBox.shrink();
          }
          return ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              // A separate, non-clickable buffer above the ad keeps scrolling
              // prayer / Quran / Qibla actions away from the banner hit target.
              minimum: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'advertisement'.tr,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: ad.size.width.toDouble(),
                    height: ad.size.height.toDouble(),
                    child: ad.buildWidget(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _hide();
    super.dispose();
  }
}
