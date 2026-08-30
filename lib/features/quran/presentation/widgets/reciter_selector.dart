import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/reciter.dart';
import '../controllers/quran_audio_controller.dart';

class ReciterSelectorButton extends StatelessWidget {
  const ReciterSelectorButton({
    required this.controller,
    this.iconOnly = false,
    super.key,
  });

  final QuranAudioController controller;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) => Obx(() {
    final reciter = controller.selectedReciter.value;
    if (iconOnly) {
      return IconButton(
        tooltip: 'quran_select_reciter'.tr,
        onPressed: () => showReciterSelector(context, controller),
        icon: const Icon(Icons.record_voice_over_rounded),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => showReciterSelector(context, controller),
      icon: const Icon(Icons.record_voice_over_rounded),
      label: Text(
        _localizedName(reciter),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  });
}

Future<void> showReciterSelector(
  BuildContext context,
  QuranAudioController controller,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 8),
                child: Text(
                  'quran_select_reciter'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...controller.reciters.map(
                (reciter) => Obx(
                  () => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Icon(
                      controller.selectedReciter.value.id == reciter.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                    ),
                    title: Text(_localizedName(reciter)),
                    subtitle: Text(
                      Get.locale?.languageCode == 'ar'
                          ? reciter.englishName
                          : reciter.arabicName,
                      textDirection: Get.locale?.languageCode == 'ar'
                          ? TextDirection.ltr
                          : TextDirection.rtl,
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await controller.selectReciter(reciter);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

String _localizedName(Reciter reciter) =>
    Get.locale?.languageCode == 'ar' ? reciter.arabicName : reciter.englishName;
