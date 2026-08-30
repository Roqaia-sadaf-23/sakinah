import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/dhikr.dart';
import '../controllers/azkar_controller.dart';

class AzkarCategoryPage extends StatefulWidget {
  const AzkarCategoryPage({super.key});

  @override
  State<AzkarCategoryPage> createState() => _AzkarCategoryPageState();
}

class _AzkarCategoryPageState extends State<AzkarCategoryPage> {
  late final AzkarController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AzkarController>();
    _scrollController = ScrollController();
    final id = Get.parameters['id'] ?? '';
    Future<void>.microtask(() => _controller.selectCategory(id));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Obx(() {
        final category = _controller.currentCategory.value;
        return Text(category?.titleKey.tr ?? 'azkar'.tr);
      }),
    ),
    body: SafeArea(top: false, child: Obx(() => _buildBody(context))),
  );

  Widget _buildBody(BuildContext context) {
    if (_controller.status.value == AzkarViewStatus.loading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    final category = _controller.currentCategory.value;
    final item = _controller.currentDhikr;
    if (category == null || item == null) {
      return _EmptyCategory(messageKey: _controller.errorKey.value);
    }
    final count = _controller.countFor(item);
    final completed = count >= item.repeatCount;
    return CustomScrollView(
      controller: _scrollController,
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
                    _ReaderToolbar(controller: _controller),
                    const SizedBox(height: 14),
                    _CategoryProgress(
                      current: _controller.currentIndex.value + 1,
                      total: category.items.length,
                      completed: _controller.completedCount(category),
                    ),
                    const SizedBox(height: 14),
                    _DhikrCard(
                      item: item,
                      count: count,
                      completed: completed,
                      fontSize: _controller.fontSize.value,
                      favorite: _controller.isFavorite(item),
                      onFavorite: _controller.toggleFavoriteCurrent,
                      onCopy: () => _copyDhikr(context, item),
                      onCount: _controller.incrementCurrent,
                    ),
                    const SizedBox(height: 14),
                    _NavigationControls(
                      hasPrevious: _controller.hasPrevious,
                      hasNext: _controller.hasNext,
                      onPrevious: () => _navigate(_controller.showPrevious),
                      onReset: _controller.resetCurrent,
                      onNext: () => _navigate(_controller.showNext),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigate(VoidCallback action) {
    action();
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _copyDhikr(BuildContext context, Dhikr item) async {
    final reference = item.reference.isEmpty ? '' : '\n\n${item.reference}';
    await Clipboard.setData(
      ClipboardData(text: '${item.arabicText}$reference'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('azkar_copied'.tr)));
  }
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({required this.controller});

  final AzkarController controller;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: controller.fontSize.value > AzkarController.minFontSize
                ? controller.decreaseFontSize
                : null,
            tooltip: 'azkar_font_decrease'.tr,
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 54),
            child: Text(
              controller.fontSize.value.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: controller.fontSize.value < AzkarController.maxFontSize
                ? controller.increaseFontSize
                : null,
            tooltip: 'azkar_font_increase'.tr,
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      ),
    ),
  );
}

class _CategoryProgress extends StatelessWidget {
  const _CategoryProgress({
    required this.current,
    required this.total,
    required this.completed,
  });

  final int current;
  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'azkar_item_position'.trParams({
            'current': '$current',
            'total': '$total',
          }),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      Text(
        'azkar_category_progress'.trParams({
          'done': '$completed',
          'total': '$total',
        }),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    ],
  );
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({
    required this.item,
    required this.count,
    required this.completed,
    required this.fontSize,
    required this.favorite,
    required this.onFavorite,
    required this.onCopy,
    required this.onCount,
  });

  final Dhikr item;
  final int count;
  final bool completed;
  final double fontSize;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onCopy;
  final VoidCallback onCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: completed
            ? colors.primaryContainer.withValues(alpha: 0.42)
            : colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: completed ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                avatar: Icon(
                  completed ? Icons.check_circle_rounded : Icons.repeat_rounded,
                  size: 18,
                ),
                label: Text(
                  completed
                      ? 'azkar_completed'.tr
                      : 'azkar_repeat'.trParams({
                          'count': '${item.repeatCount}',
                        }),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onCopy,
                    tooltip: 'azkar_copy'.tr,
                    icon: const Icon(Icons.copy_rounded),
                  ),
                  IconButton(
                    onPressed: onFavorite,
                    tooltip: favorite
                        ? 'azkar_unfavorite'.tr
                        : 'azkar_favorite'.tr,
                    icon: Icon(
                      favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: favorite ? colors.error : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Directionality(
            textDirection: TextDirection.rtl,
            child: SelectableText(
              item.arabicText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.9,
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
          if (item.translation.isNotEmpty) ...[
            const SizedBox(height: 18),
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                item.translation,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ),
          ],
          if (item.reference.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'azkar_reference'.tr,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              item.reference,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: 'azkar_tap_to_count'.tr,
            value: 'azkar_item_progress'.trParams({
              'current': '$count',
              'target': '${item.repeatCount}',
            }),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: completed ? null : onCount,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(88),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'azkar_item_progress'.trParams({
                        'current': '$count',
                        'target': '${item.repeatCount}',
                      }),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: completed
                                ? colors.onSurfaceVariant
                                : colors.onPrimary,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      completed
                          ? 'azkar_completed'.tr
                          : 'azkar_tap_to_count'.tr,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationControls extends StatelessWidget {
  const _NavigationControls({
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onReset,
    required this.onNext,
  });

  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onReset;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 10,
    runSpacing: 10,
    children: [
      OutlinedButton.icon(
        onPressed: hasPrevious ? onPrevious : null,
        icon: const Icon(Icons.arrow_back_rounded),
        label: Text('azkar_previous'.tr),
      ),
      OutlinedButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.refresh_rounded),
        label: Text('azkar_reset'.tr),
      ),
      FilledButton.icon(
        onPressed: hasNext ? onNext : null,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: Text('azkar_next'.tr),
      ),
    ],
  );
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            messageKey.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}
