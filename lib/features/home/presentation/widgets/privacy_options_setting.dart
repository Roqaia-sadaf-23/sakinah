import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/ads/ads_controller.dart';

class PrivacyOptionsSetting extends StatelessWidget {
  const PrivacyOptionsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdsController>()) return const SizedBox.shrink();
    final ads = Get.find<AdsController>();
    return Obx(() {
      if (!ads.privacyRequired.value) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.privacy_tip_outlined),
            label: Text('privacy_options'.tr),
            onPressed: ads.privacyBusy.value
                ? null
                : () async {
                    final succeeded = await ads.showPrivacyOptions();
                    if (!succeeded && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('privacy_options_error'.tr)),
                      );
                    }
                  },
          ),
        ),
      );
    });
  }
}
