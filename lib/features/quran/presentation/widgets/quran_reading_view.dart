import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/surah.dart';
import '../controllers/quran_audio_controller.dart';
import '../controllers/quran_controller.dart';
import '../controllers/quran_reader_controller.dart';

class QuranReadingView extends StatefulWidget {
  const QuranReadingView({
    required this.surah,
    required this.quranController,
    required this.audioController,
    required this.readerController,
    super.key,
  });

  final Surah surah;
  final QuranController quranController;
  final QuranAudioController audioController;
  final QuranReaderController readerController;

  @override
  State<QuranReadingView> createState() => QuranReadingViewState();
}

class QuranReadingViewState extends State<QuranReadingView> {
  final GlobalKey _textKey = GlobalKey();
  final Map<int, TextRange> _ayahRanges = <int, TextRange>{};
  late List<TapGestureRecognizer> _recognizers;

  @override
  void initState() {
    super.initState();
    _createRecognizers();
  }

  @override
  void didUpdateWidget(QuranReadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surah.number != widget.surah.number ||
        oldWidget.surah.ayahs.length != widget.surah.ayahs.length) {
      _disposeRecognizers();
      _createRecognizers();
    }
  }

  void _createRecognizers() {
    _recognizers = widget.surah.ayahs
        .map((ayah) {
          return TapGestureRecognizer()
            ..onTap = () {
              unawaited(
                widget.quranController.markReadingPosition(
                  widget.surah.number,
                  ayah.numberInSurah,
                ),
              );
              unawaited(widget.audioController.playAyah(widget.surah, ayah));
            };
        })
        .toList(growable: false);
  }

  Future<void> scrollAyahIntoView(
    int ayahNumber,
    ScrollController scrollController, {
    bool animate = true,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !scrollController.hasClients) return;
    final range = _ayahRanges[ayahNumber];
    final renderObject = _textKey.currentContext?.findRenderObject();
    if (range == null || renderObject is! RenderParagraph) return;

    final boxes = renderObject.getBoxesForSelection(
      TextSelection(
        baseOffset: range.start,
        extentOffset: math.min(range.start + 1, range.end),
      ),
    );
    if (boxes.isEmpty) return;

    final viewport = RenderAbstractViewport.of(renderObject);
    final paragraphOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
    final target = (paragraphOffset + boxes.first.top - 96).clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );
    if (animate) {
      await scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final currentAyah = widget.audioController.currentAyah.value;
    final fontSize = widget.readerController.fontSize.value;
    final colorScheme = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];
    _ayahRanges.clear();
    var characterOffset = 0;

    for (var index = 0; index < widget.surah.ayahs.length; index++) {
      final ayah = widget.surah.ayahs[index];
      final value =
          '${ayah.text}\u00A0﴿${_arabicIndic(ayah.numberInSurah)}﴾'
          '${index == widget.surah.ayahs.length - 1 ? '' : '\u00A0'}';
      final isCurrent =
          currentAyah?.numberInSurah == ayah.numberInSurah &&
          widget.audioController.isCurrent(
            widget.surah.number,
            ayah.numberInSurah,
          );
      _ayahRanges[ayah.numberInSurah] = TextRange(
        start: characterOffset,
        end: characterOffset + value.length,
      );
      characterOffset += value.length;

      spans.add(
        TextSpan(
          text: value,
          recognizer: _recognizers[index],
          semanticsLabel:
              '${ayah.text}، ${'quran_ayah_number'.trParams({'number': '${ayah.numberInSurah}'})}',
          style: TextStyle(
            color: isCurrent
                ? colorScheme.primary
                : Theme.of(context).brightness == Brightness.light
                ? AppColors.ink
                : colorScheme.onSurface,
            backgroundColor: isCurrent
                ? colorScheme.primaryContainer.withValues(alpha: 0.42)
                : null,
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppConstants.maxContentWidth,
        ),
        child: Container(
          key: const Key('quran-continuous-text'),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: RichText(
            key: _textKey,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            softWrap: true,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                height: 2,
              ),
              children: spans,
            ),
          ),
        ),
      ),
    );
  });

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
  }
}

String _arabicIndic(int value) {
  const western = '0123456789';
  const arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((digit) {
    final index = western.indexOf(digit);
    return index < 0 ? digit : arabicIndic[index];
  }).join();
}
