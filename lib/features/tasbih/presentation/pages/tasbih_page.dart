import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/tasbih_controller.dart';
import '../widgets/tasbih_completion_view.dart';
import '../widgets/tasbih_counter_button.dart';
import '../widgets/tasbih_progress.dart';

class TasbihPage extends GetView<TasbihController> {
  const TasbihPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('tasbih'.tr),
      actions: [
        Obx(
          () => controller.hasProgress
              ? IconButton(
                  onPressed: () => _confirmReset(context),
                  tooltip: 'reset_tasbih'.tr,
                  icon: const Icon(Icons.refresh_rounded),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Obx(
        () => controller.isCompleted.value
            ? TasbihCompletionView(
                onRestart: controller.reset,
                onBackHome: () => Get.offAllNamed<dynamic>(AppRoutes.home),
              )
            : _buildCounter(context),
      ),
    ),
  );

  Widget _buildCounter(BuildContext context) => CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppConstants.maxContentWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TasbihProgress(
                    counts: controller.completedCounts,
                    currentIndex: controller.currentIndex.value,
                    totalCompleted: controller.totalCompleted,
                    totalTarget: TasbihController.totalTarget,
                    progress: controller.progress,
                    sessionCompleted: controller.isCompleted.value,
                  ),
                  const SizedBox(height: 18),
                  _CurrentDhikrCard(controller: controller),
                  const SizedBox(height: 22),
                  TasbihCounterButton(
                    count: controller.currentCount.value,
                    target: controller.currentTarget,
                    enabled: !controller.isTransitioning.value,
                    transitioning: controller.isTransitioning.value,
                    onTap: _incrementWithFeedback,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );

  void _incrementWithFeedback() {
    final result = controller.increment();
    switch (result) {
      case TasbihTapResult.incremented:
        HapticFeedback.lightImpact();
      case TasbihTapResult.dhikrCompleted:
      case TasbihTapResult.sessionCompleted:
        HapticFeedback.mediumImpact();
      case TasbihTapResult.ignored:
        break;
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('reset_tasbih'.tr),
        content: Text('reset_confirmation'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('reset'.tr),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.reset();
  }
}

class _CurrentDhikrCard extends StatelessWidget {
  const _CurrentDhikrCard({required this.controller});

  final TasbihController controller;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: Column(
          key: ValueKey(controller.currentIndex.value),
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                controller.currentDhikr.text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: controller.currentIndex.value == 3 ? 26 : 34,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${controller.currentCount.value} / ${controller.currentTarget}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (controller.isTransitioning.value) ...[
              const SizedBox(height: 8),
              Text(
                'completed'.tr,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
