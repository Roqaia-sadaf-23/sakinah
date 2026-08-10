import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.featureKey, super.key});

  final String featureKey;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(featureKey.tr)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 20),
            Text(
              'coming_soon'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('coming_soon_message'.tr, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text('back_home'.tr),
            ),
          ],
        ),
      ),
    ),
  );
}
