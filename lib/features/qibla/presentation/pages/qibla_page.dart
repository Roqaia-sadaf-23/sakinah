import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../controllers/qibla_controller.dart';
import '../widgets/qibla_compass.dart';

class QiblaPage extends GetView<QiblaController> {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('qibla_direction'.tr),
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
    ),
    body: Obx(
      () => switch (controller.status.value) {
        QiblaViewStatus.loading => const _QiblaLoading(),
        QiblaViewStatus.error => _QiblaError(controller: controller),
        QiblaViewStatus.ready => _QiblaReady(controller: controller),
      },
    ),
  );
}

class _QiblaReady extends StatelessWidget {
  const _QiblaReady({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      AppConstants.horizontalPadding,
      8,
      AppConstants.horizontalPadding,
      36,
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 5),
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
            const SizedBox(height: 12),
            Text(
              'compass_guidance'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 26),
            QiblaCompass(controller: controller),
            const SizedBox(height: 26),
            _AlignmentCard(controller: controller),
            const SizedBox(height: 16),
            _DirectionMetrics(controller: controller),
          ],
        ),
      ),
    ),
  );
}

class _AlignmentCard extends StatelessWidget {
  const _AlignmentCard({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final aligned = controller.isAligned;
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: aligned
            ? colors.primaryContainer
            : colors.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: aligned
              ? colors.primary.withValues(alpha: 0.35)
              : colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            aligned
                ? Icons.check_circle_rounded
                : controller.shouldTurnRight
                ? Icons.rotate_right_rounded
                : Icons.rotate_left_rounded,
            color: colors.primary,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              aligned
                  ? 'facing_qibla'.tr
                  : controller.shouldTurnRight
                  ? 'turn_slightly_right'.tr
                  : 'turn_slightly_left'.tr,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  });
}

class _DirectionMetrics extends StatelessWidget {
  const _DirectionMetrics({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.screen_rotation_rounded,
            label: 'current_heading'.tr,
            value: '${controller.heading.value.round()}\u00B0',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.mosque_rounded,
            label: 'qibla_bearing'.tr,
            value: '${controller.qiblaBearing.value.round()}\u00B0',
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      child: Column(
        children: [
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    ),
  );
}

class _QiblaLoading extends StatelessWidget {
  const _QiblaLoading();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text('loading_qibla_screen'.tr, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _QiblaError extends StatelessWidget {
  const _QiblaError({required this.controller});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppConstants.horizontalPadding),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.explore_off_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  controller.errorKey.value.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (controller.location.value != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${'qibla_bearing'.tr}: '
                    '${controller.qiblaBearing.value.round()}\u00B0',
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: controller.load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('retry'.tr),
                    ),
                    if (controller.canOpenSettings)
                      OutlinedButton.icon(
                        onPressed: controller.openRelevantSettings,
                        icon: const Icon(Icons.settings_rounded),
                        label: Text('open_settings'.tr),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
