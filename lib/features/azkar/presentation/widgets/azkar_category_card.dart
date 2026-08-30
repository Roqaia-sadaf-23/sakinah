import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/azkar_category.dart';

class AzkarCategoryCard extends StatelessWidget {
  const AzkarCategoryCard({
    required this.category,
    required this.completedCount,
    required this.onTap,
    super.key,
  });

  final AzkarCategory category;
  final int completedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = category.items.length;
    final progress = total == 0 ? 0.0 : completedCount / total;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconFor(category.id),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.titleKey.tr,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'azkar_item_count'.trParams({'count': '$total'}),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'azkar_category_progress'.trParams({
                        'done': '$completedCount',
                        'total': '$total',
                      }),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
    'morning' => Icons.wb_sunny_outlined,
    'evening' => Icons.nights_stay_outlined,
    'after_prayer' => Icons.mosque_outlined,
    'sleep' => Icons.bedtime_outlined,
    'waking' => Icons.wb_twilight_outlined,
    'mosque' => Icons.account_balance_outlined,
    'home' => Icons.home_outlined,
    'food' => Icons.restaurant_outlined,
    'travel' => Icons.flight_takeoff_outlined,
    'favorites' => Icons.favorite_outline_rounded,
    _ => Icons.auto_awesome_outlined,
  };
}
