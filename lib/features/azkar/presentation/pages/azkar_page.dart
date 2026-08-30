import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/azkar_category.dart';
import '../controllers/azkar_controller.dart';
import '../widgets/azkar_category_card.dart';

class AzkarPage extends GetView<AzkarController> {
  const AzkarPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('azkar'.tr)),
    body: SafeArea(top: false, child: Obx(() => _buildBody(context))),
  );

  Widget _buildBody(BuildContext context) => switch (controller.status.value) {
    AzkarViewStatus.loading => const Center(
      child: CircularProgressIndicator.adaptive(),
    ),
    AzkarViewStatus.error => _AzkarLoadError(
      messageKey: controller.errorKey.value,
      onRetry: controller.loadCategories,
    ),
    AzkarViewStatus.success => _buildSuccess(context),
  };

  Widget _buildSuccess(BuildContext context) {
    final favorites = controller.categoryById('favorites')!;
    final cards = <AzkarCategory>[favorites, ...controller.categories];
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppConstants.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _AzkarWelcomeCard(controller: controller),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          sliver: SliverList.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = cards[index];
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppConstants.maxContentWidth,
                  ),
                  child: AzkarCategoryCard(
                    category: category,
                    completedCount: controller.completedCount(category),
                    onTap: () => controller.openCategory(category.id),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AzkarWelcomeCard extends StatelessWidget {
  const _AzkarWelcomeCard({required this.controller});

  final AzkarController controller;

  @override
  Widget build(BuildContext context) {
    final saved = controller.lastPosition.value;
    final savedCategory = saved == null
        ? null
        : controller.categoryById(saved.categoryId);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepEmerald, AppColors.emerald],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'azkar_welcome'.tr,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 7),
          Text(
            'azkar_welcome_message'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          if (savedCategory != null && savedCategory.items.isNotEmpty) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.deepEmerald,
              ),
              onPressed: controller.continueAzkar,
              icon: const Icon(Icons.bookmark_rounded),
              label: Text(
                '${'continue_azkar'.tr}: ${savedCategory.titleKey.tr}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AzkarLoadError extends StatelessWidget {
  const _AzkarLoadError({required this.messageKey, required this.onRetry});

  final String messageKey;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 80),
      Icon(
        Icons.menu_book_outlined,
        size: 60,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 18),
      Text(
        messageKey.tr,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 20),
      Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('retry'.tr),
        ),
      ),
    ],
  );
}
