import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuranStateView extends StatelessWidget {
  const QuranStateView({
    required this.messageKey,
    required this.onRetry,
    this.icon = Icons.cloud_off_rounded,
    super.key,
  });

  final String messageKey;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              messageKey.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('retry'.tr),
            ),
          ],
        ),
      ),
    ),
  );
}

class QuranLoadingView extends StatelessWidget {
  const QuranLoadingView({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        5,
        (index) => Container(
          height: 82,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ),
  );
}
