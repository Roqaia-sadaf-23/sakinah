import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/surah.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';
import '../widgets/ayah_card.dart';
import '../widgets/quran_compact_player.dart';
import '../widgets/quran_state_view.dart';
import '../widgets/reciter_selector.dart';

class SurahPage extends StatefulWidget {
  const SurahPage({super.key});

  @override
  State<SurahPage> createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  late final QuranController _quranController;
  late final QuranAudioController _audioController;
  late final int _surahNumber;
  late final int _initialAyahNumber;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _quranController = Get.find<QuranController>();
    _audioController = Get.find<QuranAudioController>();
    _surahNumber = int.tryParse(Get.parameters['id'] ?? '') ?? 0;
    final arguments = Get.arguments;
    _initialAyahNumber = arguments is Map && arguments['ayah'] is int
        ? arguments['ayah'] as int
        : 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadSurah());
    });
  }

  Future<void> _loadSurah({bool forceRefresh = false}) async {
    await _quranController.loadSurah(_surahNumber, forceRefresh: forceRefresh);
    final surah = _quranController.currentSurah.value;
    if (surah != null &&
        _initialAyahNumber >= 1 &&
        _initialAyahNumber <= surah.numberOfAyahs) {
      await _quranController.markReadingPosition(
        surah.number,
        _initialAyahNumber,
      );
      if (_initialAyahNumber > 1) {
        _ayahKeys.putIfAbsent(_initialAyahNumber, GlobalKey.new);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          unawaited(_restoreReadingPosition(surah));
        });
      }
    }
  }

  Future<void> _restoreReadingPosition(Surah surah) async {
    if (_initialAyahNumber > surah.ayahs.length) return;
    final targetKey = _ayahKeys[_initialAyahNumber]!;

    for (var attempt = 0; attempt < 48 && mounted; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) continue;

      final targetContext = targetKey.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.12,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
        return;
      }

      final position = _scrollController.position;
      final visibleNumbers = _ayahKeys.entries
          .where((entry) => entry.value.currentContext != null)
          .map((entry) => entry.key)
          .toList(growable: false);
      final double nextOffset;
      if (attempt == 0) {
        final fraction = (_initialAyahNumber - 1) / (surah.ayahs.length - 1);
        nextOffset = position.maxScrollExtent * fraction;
      } else if (visibleNumbers.isNotEmpty &&
          visibleNumbers.every((number) => number > _initialAyahNumber)) {
        nextOffset = position.pixels - position.viewportDimension * 0.8;
      } else {
        nextOffset = position.pixels + position.viewportDimension * 0.8;
      }
      final clampedOffset = nextOffset.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((clampedOffset - position.pixels).abs() < 1) return;
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<QuranAudioController>()) {
      unawaited(_audioController.stop());
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('quran_surah'.tr),
      actions: [
        ReciterSelectorButton(controller: _audioController, iconOnly: true),
        const SizedBox(width: 6),
      ],
    ),
    bottomNavigationBar: QuranCompactPlayer(controller: _audioController),
    body: SafeArea(top: false, child: Obx(() => _buildBody(context))),
  );

  Widget _buildBody(BuildContext context) =>
      switch (_quranController.surahStatus.value) {
        QuranViewStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        QuranViewStatus.error => QuranStateView(
          messageKey: _quranController.surahErrorKey.value,
          onRetry: () => _loadSurah(forceRefresh: true),
          icon: Icons.menu_book_rounded,
        ),
        QuranViewStatus.success => _SurahReader(
          surah: _quranController.currentSurah.value!,
          initialAyahNumber: _initialAyahNumber,
          quranController: _quranController,
          audioController: _audioController,
          scrollController: _scrollController,
          ayahKeyFor: (number) => _ayahKeys.putIfAbsent(number, GlobalKey.new),
        ),
      };
}

class _SurahReader extends StatelessWidget {
  const _SurahReader({
    required this.surah,
    required this.initialAyahNumber,
    required this.quranController,
    required this.audioController,
    required this.scrollController,
    required this.ayahKeyFor,
  });

  final Surah surah;
  final int initialAyahNumber;
  final QuranController quranController;
  final QuranAudioController audioController;
  final ScrollController scrollController;
  final GlobalKey Function(int number) ayahKeyFor;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: scrollController,
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: _SurahHeader(
                surah: surah,
                initialAyahNumber: initialAyahNumber,
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
        sliver: SliverList.builder(
          itemCount: surah.ayahs.length * 2 - 1,
          itemBuilder: (context, index) {
            if (index.isOdd) return const SizedBox(height: 12);
            final ayah = surah.ayahs[index ~/ 2];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppConstants.maxContentWidth,
                ),
                child: AyahCard(
                  key: ayahKeyFor(ayah.numberInSurah),
                  surah: surah,
                  ayah: ayah,
                  quranController: quranController,
                  audioController: audioController,
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah, required this.initialAyahNumber});

  final Surah surah;
  final int initialAyahNumber;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.deepEmerald, AppColors.emerald],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          surah.arabicName,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 28,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${surah.number}. ${surah.englishName}',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            _HeaderChip(label: surah.isMeccan ? 'meccan'.tr : 'medinan'.tr),
            _HeaderChip(
              label: 'quran_ayah_count'.trParams({
                'count': '${surah.numberOfAyahs}',
              }),
            ),
            if (initialAyahNumber > 1)
              _HeaderChip(
                icon: Icons.bookmark_rounded,
                label: 'quran_last_read_ayah'.trParams({
                  'number': '$initialAyahNumber',
                }),
              ),
          ],
        ),
      ],
    ),
  );
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.white),
        ),
      ],
    ),
  );
}
