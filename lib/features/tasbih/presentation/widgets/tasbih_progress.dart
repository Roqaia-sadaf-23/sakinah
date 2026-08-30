import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tasbih_item.dart';

class TasbihProgress extends StatelessWidget {
  const TasbihProgress({
    required this.counts,
    required this.currentIndex,
    required this.totalCompleted,
    required this.totalTarget,
    required this.progress,
    required this.sessionCompleted,
    super.key,
  });

  final List<int> counts;
  final int currentIndex;
  final int totalCompleted;
  final int totalTarget;
  final double progress;
  final bool sessionCompleted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'total_progress'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$totalCompleted / $totalTarget',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: colors.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
            for (var index = 0; index < tasbihSequence.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              _ProgressRow(
                item: tasbihSequence[index],
                count: counts[index],
                active: !sessionCompleted && index == currentIndex,
                completed: counts[index] >= tasbihSequence[index].target,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.item,
    required this.count,
    required this.active,
    required this.completed,
  });

  final TasbihItem item;
  final int count;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? colors.primary
                : active
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            border: Border.all(
              color: active ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: completed
              ? Icon(Icons.check_rounded, size: 17, color: colors.onPrimary)
              : active
              ? Icon(Icons.circle, size: 9, color: colors.primary)
              : null,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              item.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count/${item.target}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: active ? colors.primary : null,
          ),
        ),
      ],
    );
  }
}
