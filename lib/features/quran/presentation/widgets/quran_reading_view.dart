import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/mushaf_page_source.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';

class QuranReadingView extends StatefulWidget {
  const QuranReadingView({
    required this.surah,
    required this.initialAyahNumber,
    required this.quranController,
    required this.audioController,
    required this.pageSource,
    super.key,
  });

  final Surah surah;
  final int initialAyahNumber;
  final QuranController quranController;
  final QuranAudioController audioController;
  final MushafPageSource pageSource;

  @override
  State<QuranReadingView> createState() => QuranReadingViewState();
}

class QuranReadingViewState extends State<QuranReadingView> {
  late Future<MushafMetadata> _metadataFuture;
  final Map<int, Future<String>> _pageFutures = <int, Future<String>>{};
  PageController? _pageController;
  MushafMetadata? _metadata;
  int? _currentPage;
  int? _initialPage;
  bool _hasHandledInitialPageCallback = false;

  @override
  void initState() {
    super.initState();
    _metadataFuture = widget.pageSource.loadMetadata();
  }

  Future<void> showAyah(int ayahNumber, {bool animate = true}) async {
    final metadata = _metadata ?? await _metadataFuture;
    if (!mounted) return;
    final page = metadata
        .referenceFor(widget.surah.number, ayahNumber)
        .pageNumber;
    final controller = _pageController;
    if (controller == null) return;
    if (animate) {
      await controller.animateToPage(
        page - 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      controller.jumpToPage(page - 1);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<MushafMetadata>(
    future: _metadataFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _MushafLoadError(onRetry: _reloadMetadata);
      }
      final metadata = snapshot.data;
      if (metadata == null) {
        return const Center(child: CircularProgressIndicator());
      }
      _metadata = metadata;
      final initialReference = metadata.referenceFor(
        widget.surah.number,
        widget.initialAyahNumber,
      );
      _pageController ??= PageController(
        initialPage: initialReference.pageNumber - 1,
      );
      _initialPage ??= initialReference.pageNumber;
      _currentPage ??= initialReference.pageNumber;

      return Column(
        children: [
          _MushafPageHeader(metadata: metadata.page(_currentPage!)),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PageView.builder(
                key: const Key('mushaf-page-view'),
                controller: _pageController,
                itemCount: MushafMetadata.totalPages,
                allowImplicitScrolling: true,
                onPageChanged: (index) => _onPageChanged(index + 1),
                itemBuilder: (context, index) {
                  final pageNumber = index + 1;
                  return _buildPage(metadata.page(pageNumber));
                },
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _buildPage(MushafPageMetadata page) => FutureBuilder<String>(
    future: _pageFutures.putIfAbsent(
      page.pageNumber,
      () => widget.pageSource.loadPageSvg(page.pageNumber),
    ),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _MushafLoadError(
          pageNumber: page.pageNumber,
          onRetry: () => _reloadPage(page.pageNumber),
        );
      }
      final svg = snapshot.data;
      if (svg == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return _MushafPageCanvas(
        page: page,
        svg: svg,
        audioController: widget.audioController,
        onAyahTap: _playAyah,
      );
    },
  );

  void _onPageChanged(int pageNumber) {
    setState(() => _currentPage = pageNumber);
    if (!_hasHandledInitialPageCallback) {
      _hasHandledInitialPageCallback = true;
      if (pageNumber == _initialPage) return;
    }
    final firstAyah = _metadata!.page(pageNumber).firstAyah;
    unawaited(
      widget.quranController.markReadingPosition(
        firstAyah.surahNumber,
        firstAyah.ayahNumber,
      ),
    );
    widget.pageSource.prefetchPage(pageNumber - 1);
    widget.pageSource.prefetchPage(pageNumber + 1);
  }

  Future<void> _playAyah(MushafAyahReference reference) async {
    await widget.quranController.markReadingPosition(
      reference.surahNumber,
      reference.ayahNumber,
    );
    final surah = await widget.quranController.getSurahForReader(
      reference.surahNumber,
    );
    if (!mounted || reference.ayahNumber > surah.ayahs.length) return;
    await widget.audioController.playAyah(
      surah,
      surah.ayahs[reference.ayahNumber - 1],
    );
  }

  void _reloadPage(int pageNumber) {
    setState(() {
      _pageFutures[pageNumber] = widget.pageSource.loadPageSvg(pageNumber);
    });
  }

  void _reloadMetadata() {
    setState(() => _metadataFuture = widget.pageSource.loadMetadata());
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }
}

class _MushafPageHeader extends StatelessWidget {
  const _MushafPageHeader({required this.metadata});

  final MushafPageMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final names = metadata.surahs.map((surah) => surah.arabicName).join(' • ');
    return Semantics(
      container: true,
      label:
          '$names, ${'quran_juz_number'.trParams({'number': '${metadata.juzNumber}'})}, '
          '${'quran_page_number'.trParams({'number': '${metadata.pageNumber}'})}',
      child: Container(
        key: const Key('mushaf-page-header'),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                names,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontFamily: 'NotoNaskhArabic',
                  color: AppColors.deepEmerald,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${'quran_juz_short'.tr} ${metadata.juzNumber}',
              key: const Key('mushaf-juz-number'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 12),
            Text(
              '${metadata.pageNumber} / ${MushafMetadata.totalPages}',
              key: const Key('mushaf-page-number'),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPageCanvas extends StatelessWidget {
  const _MushafPageCanvas({
    required this.page,
    required this.svg,
    required this.audioController,
    required this.onAyahTap,
  });

  static const _pageAspectRatio = 345 / 550;

  final MushafPageMetadata page;
  final String svg;
  final QuranAudioController audioController;
  final ValueChanged<MushafAyahReference> onAyahTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
    child: Center(
      child: AspectRatio(
        aspectRatio: _pageAspectRatio,
        child: RepaintBoundary(
          key: Key('mushaf-page-${page.pageNumber}'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF5),
              border: Border.all(color: const Color(0xFFE2D8C3)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                fit: StackFit.expand,
                children: [
                  SvgPicture.string(
                    svg,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    semanticsLabel: 'quran_page_number'.trParams({
                      'number': '${page.pageNumber}',
                    }),
                  ),
                  ...page.ayahs.map(
                    (ayah) => _AyahMarkerTarget(
                      reference: ayah,
                      canvasSize: constraints.biggest,
                      audioController: audioController,
                      onTap: () => onAyahTap(ayah),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AyahMarkerTarget extends StatelessWidget {
  const _AyahMarkerTarget({
    required this.reference,
    required this.canvasSize,
    required this.audioController,
    required this.onTap,
  });

  final MushafAyahReference reference;
  final Size canvasSize;
  final QuranAudioController audioController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const targetSize = 30.0;
    if (canvasSize.width < targetSize || canvasSize.height < targetSize) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: (reference.markerX / 345 * canvasSize.width - targetSize / 2).clamp(
        0,
        canvasSize.width - targetSize,
      ),
      top: (reference.markerY / 550 * canvasSize.height - targetSize / 2).clamp(
        0,
        canvasSize.height - targetSize,
      ),
      child: Obx(() {
        final selected = audioController.isCurrent(
          reference.surahNumber,
          reference.ayahNumber,
        );
        return Semantics(
          button: true,
          label: 'quran_play_ayah'.trParams({
            'number': '${reference.ayahNumber}',
          }),
          child: GestureDetector(
            key: Key(
              'mushaf-ayah-${reference.surahNumber}-${reference.ayahNumber}',
            ),
            behavior: HitTestBehavior.translucent,
            onTap: onTap,
            child: Container(
              width: targetSize,
              height: targetSize,
              decoration: selected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _MushafLoadError extends StatelessWidget {
  const _MushafLoadError({required this.onRetry, this.pageNumber});

  final VoidCallback onRetry;
  final int? pageNumber;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12),
          Text(
            'quran_mushaf_page_error'.trParams({
              'number': '${pageNumber ?? ''}',
            }),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('retry'.tr),
          ),
        ],
      ),
    ),
  );
}
