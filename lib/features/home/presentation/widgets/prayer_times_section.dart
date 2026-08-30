import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';

class PrayerTimesSection extends StatelessWidget {
  const PrayerTimesSection({required this.controller, super.key});

  final PrayerTimesController controller;

  @override
  Widget build(BuildContext context) {
    final prayers = controller.todaySchedule.value?.prayers ?? const <Prayer>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(title: 'prayer_times'.tr, icon: Icons.schedule_rounded),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 600 ? 6 : 3;
            const gap = 10.0;
            final totalSpacing = gap * (columns - 1);
            if (constraints.maxWidth <= totalSpacing) {
              return const SizedBox.shrink();
            }
            final itemWidth = (constraints.maxWidth - totalSpacing) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: prayers
                  .map(
                    (prayer) => SizedBox(
                      width: itemWidth,
                      child: _PrayerTimeTile(
                        prayer: prayer,
                        formattedTime: controller.formatTime(prayer.time),
                        isNext:
                            controller.nextPrayer.value?.name == prayer.name,
                      ),
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _PrayerTimeTile extends StatelessWidget {
  const _PrayerTimeTile({
    required this.prayer,
    required this.formattedTime,
    required this.isNext,
  });

  final Prayer prayer;
  final String formattedTime;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 15),
      decoration: BoxDecoration(
        color: isNext ? colors.primary : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNext
              ? colors.primary
              : colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _iconFor(prayer.name),
            size: 19,
            color: isNext ? AppColors.sand : colors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            prayer.name.key.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isNext ? Colors.white : null,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedTime,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                color: isNext
                    ? Colors.white.withValues(alpha: 0.84)
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PrayerName name) => switch (name) {
    PrayerName.fajr => Icons.wb_twilight_rounded,
    PrayerName.sunrise => Icons.wb_sunny_outlined,
    PrayerName.dhuhr => Icons.light_mode_outlined,
    PrayerName.asr => Icons.sunny_snowing,
    PrayerName.maghrib => Icons.brightness_4_outlined,
    PrayerName.isha => Icons.dark_mode_outlined,
  };
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 9),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
