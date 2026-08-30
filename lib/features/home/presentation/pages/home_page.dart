import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';
import '../../../prayer_tracker/presentation/controllers/prayer_tracker_controller.dart';
import '../widgets/home_header.dart';
import '../widgets/home_loading.dart';
import '../widgets/next_prayer_card.dart';
import '../widgets/prayer_times_section.dart';
import '../widgets/prayer_tracker_card.dart';
import '../widgets/quick_actions_section.dart';

class HomePage extends GetView<PrayerTimesController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final trackerController = Get.find<PrayerTrackerController>();
    final prayerTimesController = controller;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: prayerTimesController.refreshPrayerTimes,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppConstants.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.horizontalPadding,
                        18,
                        AppConstants.horizontalPadding,
                        40,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          HomeHeader(controller: prayerTimesController),
                          const SizedBox(height: 24),
                          Obx(
                            () => _PrayerContent(
                              controller: prayerTimesController,
                              status: prayerTimesController.status.value,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const QuickActionsSection(),
                          const SizedBox(height: 28),
                          PrayerTrackerCard(controller: trackerController),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerContent extends StatelessWidget {
  const _PrayerContent({required this.controller, required this.status});

  final PrayerTimesController controller;
  final PrayerTimesViewStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      PrayerTimesViewStatus.loading => const HomePrayerLoading(),
      PrayerTimesViewStatus.error => _HomeError(controller: controller),
      PrayerTimesViewStatus.success => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (controller.isUsingCache) ...[
            _CacheNotice(onRefresh: controller.refreshPrayerTimes),
            const SizedBox(height: 12),
          ],
          NextPrayerCard(controller: controller),
          const SizedBox(height: 28),
          PrayerTimesSection(controller: controller),
        ],
      ),
    };
  }
}

class _CacheNotice extends StatelessWidget {
  const _CacheNotice({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 19),
        const SizedBox(width: 10),
        Expanded(child: Text('cached_data'.tr)),
        IconButton(
          onPressed: onRefresh,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
  );
}

class _HomeError extends StatelessWidget {
  const _HomeError({required this.controller});

  final PrayerTimesController controller;

  @override
  Widget build(BuildContext context) => Card(
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
              Icons.location_off_rounded,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            controller.errorKey.value.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: controller.refreshPrayerTimes,
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
  );
}
