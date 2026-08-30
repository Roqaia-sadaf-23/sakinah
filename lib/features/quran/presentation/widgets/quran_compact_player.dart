import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../controllers/quran_audio_controller.dart';
import 'reciter_selector.dart';

class QuranCompactPlayer extends StatelessWidget {
  const QuranCompactPlayer({required this.controller, super.key});

  final QuranAudioController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final surah = controller.currentSurah.value;
    final ayah = controller.currentAyah.value;
    if (surah == null || ayah == null) return const SizedBox.shrink();
    final state = controller.playbackState.value;
    final reciter = controller.selectedReciter.value;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => showReciterSelector(context, controller),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${surah.englishName} • '
                                  '${'quran_ayah_number'.trParams({'number': '${ayah.numberInSurah}'})}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Get.locale?.languageCode == 'ar'
                                      ? reciter.arabicName
                                      : reciter.englishName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded),
                    ],
                  ),
                  if (state == QuranPlaybackState.error) ...[
                    const SizedBox(height: 6),
                    Text(
                      controller.errorKey.value.tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'quran_previous_ayah'.tr,
                        onPressed: ayah.numberInSurah > 1
                            ? () => unawaited(controller.playPreviousAyah())
                            : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                      ),
                      if (state == QuranPlaybackState.loading)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        )
                      else
                        IconButton.filled(
                          tooltip: state == QuranPlaybackState.playing
                              ? 'quran_pause'.tr
                              : 'quran_play'.tr,
                          onPressed: () => unawaited(
                            state == QuranPlaybackState.playing
                                ? controller.pause()
                                : state == QuranPlaybackState.paused
                                ? controller.resume()
                                : controller.playAyah(surah, ayah),
                          ),
                          icon: Icon(
                            state == QuranPlaybackState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      IconButton(
                        tooltip: 'quran_next_ayah'.tr,
                        onPressed: ayah.numberInSurah < surah.ayahs.length
                            ? () => unawaited(controller.playNextAyah())
                            : null,
                        icon: const Icon(Icons.skip_next_rounded),
                      ),
                      IconButton(
                        tooltip: 'quran_stop'.tr,
                        onPressed: state == QuranPlaybackState.stopped
                            ? null
                            : () => unawaited(controller.stop()),
                        icon: const Icon(Icons.stop_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  });
}
