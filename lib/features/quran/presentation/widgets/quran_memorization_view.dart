import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/surah.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';
import '../controllers/quran_reader_controller.dart';
import 'ayah_card.dart';

class QuranMemorizationView extends StatelessWidget {
  const QuranMemorizationView({
    required this.surah,
    required this.quranController,
    required this.audioController,
    required this.readerController,
    required this.ayahKeyFor,
    super.key,
  });

  final Surah surah;
  final QuranController quranController;
  final QuranAudioController audioController;
  final QuranReaderController readerController;
  final GlobalKey Function(int number) ayahKeyFor;

  @override
  Widget build(BuildContext context) => SliverPadding(
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
              readerController: readerController,
            ),
          ),
        );
      },
    ),
  );
}
