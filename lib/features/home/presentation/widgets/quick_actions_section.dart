import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  static const _actions = [
    _QuickAction('quran', AppRoutes.quran, Icons.menu_book_rounded),
    _QuickAction('qibla', AppRoutes.qibla, Icons.explore_rounded),
    _QuickAction('azkar', AppRoutes.azkar, Icons.auto_awesome_rounded),
    _QuickAction(
      'tasbih',
      AppRoutes.tasbih,
      Icons.radio_button_checked_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('quick_actions'.tr, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 540 ? 4 : 2;
          const gap = 12.0;
          final totalSpacing = gap * (columns - 1);
          if (!constraints.hasBoundedWidth ||
              constraints.maxWidth <= totalSpacing) {
            return const SizedBox.shrink();
          }
          final width = (constraints.maxWidth - totalSpacing) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: _actions
                .map(
                  (action) => SizedBox(
                    width: width,
                    child: _QuickActionCard(action: action),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    ],
  );
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => Get.toNamed<dynamic>(action.route),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                action.icon,
                color: Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                action.labelKey.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.mutedInk,
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuickAction {
  const _QuickAction(this.labelKey, this.route, this.icon);

  final String labelKey;
  final String route;
  final IconData icon;
}
