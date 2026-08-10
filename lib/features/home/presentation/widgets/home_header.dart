import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.controller, super.key});

  final PrayerTimesController controller;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<ThemeController>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.emerald,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.nights_stay_rounded,
            color: AppColors.sand,
            size: 25,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'assalamu_alaikum'.tr,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        controller.locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${controller.gregorianDate}  •  ${controller.hijriDate}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        _HeaderAction(
          tooltip: 'language'.tr,
          onTap: settings.toggleLocale,
          child: Obx(
            () => Text(
              settings.isArabic ? 'EN' : 'ع',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Obx(
          () => _HeaderAction(
            tooltip: 'theme'.tr,
            onTap: settings.toggleTheme,
            child: Icon(
              settings.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    ),
  );
}
