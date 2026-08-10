import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_tracker/presentation/controllers/prayer_tracker_controller.dart';

class PrayerTrackerCard extends StatelessWidget {
  const PrayerTrackerCard({required this.controller, super.key});

  final PrayerTrackerController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.fact_check_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'prayer_tracker'.tr,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'completed_count'.trParams({
                          'done': '${controller.completedCount}',
                          'total': '${PrayerTrackerController.prayers.length}',
                        }),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${controller.completedCount}/${PrayerTrackerController.prayers.length}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value:
                    controller.completedCount /
                    PrayerTrackerController.prayers.length,
                minHeight: 7,
                color: AppColors.emerald,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = constraints.maxWidth < 390 ? 5.0 : 8.0;
                final width =
                    (constraints.maxWidth - spacing * 4) /
                    PrayerTrackerController.prayers.length;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: PrayerTrackerController.prayers
                      .map(
                        (prayer) => SizedBox(
                          width: width,
                          child: _PrayerCheck(
                            label: prayer.key.tr,
                            checked: controller.isCompleted(prayer),
                            onTap: () => controller.toggle(prayer),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _PrayerCheck extends StatelessWidget {
  const _PrayerCheck({
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: checked,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: checked
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: checked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
