import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePrayerLoading extends StatelessWidget {
  const HomePrayerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text('loading_prayer_times'.tr),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            const totalSpacing = 20.0;
            if (constraints.maxWidth <= totalSpacing) {
              return const SizedBox.shrink();
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                6,
                (_) => Container(
                  width: (constraints.maxWidth - totalSpacing) / 3,
                  height: 92,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
