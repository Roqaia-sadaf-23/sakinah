import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_reader_controller.dart';
import 'reciter_selector.dart';

class QuranReaderToolbar extends StatelessWidget {
  const QuranReaderToolbar({
    required this.readerController,
    required this.audioController,
    super.key,
  });

  final QuranReaderController readerController;
  final QuranAudioController audioController;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Obx(() {
        final mode = readerController.readingMode.value;
        final fontSize = readerController.fontSize.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                SegmentedButton<QuranReadingMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: QuranReadingMode.reading,
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text('quran_reading_mode'.tr),
                    ),
                    ButtonSegment(
                      value: QuranReadingMode.memorization,
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text('quran_memorization_mode'.tr),
                    ),
                  ],
                  selected: <QuranReadingMode>{mode},
                  onSelectionChanged: (selection) {
                    readerController.setReadingMode(selection.first);
                  },
                ),
                Semantics(
                  label: 'quran_font_size'.tr,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'quran_font_decrease'.tr,
                          onPressed: readerController.canDecreaseFont
                              ? readerController.decreaseFontSize
                              : null,
                          icon: const Icon(Icons.text_decrease_rounded),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '${fontSize.round()}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'quran_font_increase'.tr,
                          onPressed: readerController.canIncreaseFont
                              ? readerController.increaseFontSize
                              : null,
                          icon: const Icon(Icons.text_increase_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ReciterSelectorButton(controller: audioController),
            ),
          ],
        );
      }),
    ),
  );
}
