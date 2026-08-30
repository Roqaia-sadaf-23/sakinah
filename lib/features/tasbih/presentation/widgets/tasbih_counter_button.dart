import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';

class TasbihCounterButton extends StatefulWidget {
  const TasbihCounterButton({
    required this.count,
    required this.target,
    required this.enabled,
    required this.transitioning,
    required this.onTap,
    super.key,
  });

  final int count;
  final int target;
  final bool enabled;
  final bool transitioning;
  final VoidCallback onTap;

  @override
  State<TasbihCounterButton> createState() => _TasbihCounterButtonState();
}

class _TasbihCounterButtonState extends State<TasbihCounterButton> {
  var _highlighted = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available =
          constraints.hasBoundedWidth &&
              constraints.maxWidth.isFinite &&
              constraints.maxWidth > 0
          ? constraints.maxWidth
          : 280.0;
      final diameter = math.min(available, 286.0);
      if (diameter <= 0) return const SizedBox.shrink();
      return Center(
        child: AnimatedScale(
          scale: _highlighted ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: Container(
            width: diameter,
            height: diameter,
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.sand, AppColors.mint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Material(
              color: widget.enabled
                  ? AppColors.emerald
                  : AppColors.emerald.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Semantics(
                button: true,
                enabled: widget.enabled,
                label: 'tap_to_count'.tr,
                value: '${widget.count} / ${widget.target}',
                child: InkWell(
                  key: const Key('tasbih-counter-button'),
                  customBorder: const CircleBorder(),
                  onTap: widget.enabled ? widget.onTap : null,
                  onHighlightChanged: (value) {
                    if (_highlighted == value) return;
                    setState(() => _highlighted = value);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${widget.count}',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: diameter < 220 ? 44 : 58,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.transitioning
                            ? 'tasbih_next_dhikr'.tr
                            : 'tap_to_count'.tr,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
