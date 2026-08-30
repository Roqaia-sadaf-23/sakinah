import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';
import '../controllers/quran_reader_controller.dart';

class AyahCard extends StatelessWidget {
  const AyahCard({
    required this.surah,
    required this.ayah,
    required this.quranController,
    required this.audioController,
    required this.readerController,
    super.key,
  });

  final Surah surah;
  final Ayah ayah;
  final QuranController quranController;
  final QuranAudioController audioController;
  final QuranReaderController readerController;

  @override
  Widget build(BuildContext context) => Obx(() {
    final isCurrent = audioController.isCurrent(
      surah.number,
      ayah.numberInSurah,
    );
    final isLastRead =
        quranController.lastReadingPosition.value?.surahNumber ==
            surah.number &&
        quranController.lastReadingPosition.value?.ayahNumber ==
            ayah.numberInSurah;
    final colorScheme = Theme.of(context).colorScheme;
    final fontSize = readerController.fontSize.value;

    return Semantics(
      button: true,
      label: 'quran_play_ayah'.trParams({'number': '${ayah.numberInSurah}'}),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: isCurrent
              ? colorScheme.primaryContainer.withValues(alpha: 0.72)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isCurrent
                ? colorScheme.primary
                : isLastRead
                ? AppColors.sand
                : colorScheme.outlineVariant.withValues(alpha: 0.55),
            width: isCurrent || isLastRead ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            unawaited(
              quranController.markReadingPosition(
                surah.number,
                ayah.numberInSurah,
              ),
            );
            unawaited(audioController.playAyah(surah, ayah));
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _AyahMarker(number: ayah.numberInSurah),
                    const SizedBox(width: 10),
                    if (isLastRead)
                      Icon(
                        Icons.bookmark_rounded,
                        size: 19,
                        color: isCurrent ? colorScheme.primary : AppColors.sand,
                      ),
                    const Expanded(child: SizedBox()),
                    _PlaybackIcon(
                      isCurrent: isCurrent,
                      state: audioController.playbackState.value,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    ayah.text,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      height: 2,
                      color: Theme.of(context).brightness == Brightness.light
                          ? AppColors.ink
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });
}

class _AyahMarker extends StatelessWidget {
  const _AyahMarker({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$number',
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
  );
}

class _PlaybackIcon extends StatelessWidget {
  const _PlaybackIcon({required this.isCurrent, required this.state});

  final bool isCurrent;
  final QuranPlaybackState state;

  @override
  Widget build(BuildContext context) {
    if (isCurrent && state == QuranPlaybackState.loading) {
      return const SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    final icon = switch (state) {
      QuranPlaybackState.playing when isCurrent => Icons.volume_up_rounded,
      QuranPlaybackState.paused when isCurrent => Icons.pause_circle_rounded,
      _ => Icons.play_circle_outline_rounded,
    };
    return Icon(
      icon,
      color: isCurrent
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
