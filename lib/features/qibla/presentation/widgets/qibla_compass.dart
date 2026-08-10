import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/qibla_controller.dart';

class QiblaCompass extends StatelessWidget {
  const QiblaCompass({required this.controller, super.key});

  final QiblaController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.maxWidth.clamp(260.0, 360.0);
      return Obx(() {
        final aligned = controller.isAligned;
        final colors = Theme.of(context).colorScheme;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          width: size,
          height: size,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: aligned
                ? colors.primary.withValues(alpha: 0.11)
                : colors.surface,
            border: Border.all(
              width: aligned ? 3 : 1,
              color: aligned
                  ? colors.primary
                  : colors.outlineVariant.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.09),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: controller.continuousHeading.value),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (context, value, child) => Transform.rotate(
                  angle: -value * math.pi / 180,
                  child: child,
                ),
                child: CustomPaint(
                  size: Size.square(size - 22),
                  painter: _CompassPainter(
                    qiblaBearing: controller.qiblaBearing.value,
                    dialColor: colors.onSurface,
                    mutedColor: colors.onSurfaceVariant,
                    accentColor: AppColors.sand,
                    cardinalLabels: [
                      'north_short'.tr,
                      'east_short'.tr,
                      'south_short'.tr,
                      'west_short'.tr,
                    ],
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(width: 5, color: colors.surface),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              Positioned(
                top: -4,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 42,
                  color: aligned ? colors.primary : AppColors.sand,
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter({
    required this.qiblaBearing,
    required this.dialColor,
    required this.mutedColor,
    required this.accentColor,
    required this.cardinalLabels,
  });

  final double qiblaBearing;
  final Color dialColor;
  final Color mutedColor;
  final Color accentColor;
  final List<String> cardinalLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = mutedColor.withValues(alpha: 0.2);
    canvas.drawCircle(center, radius - 7, ringPaint);
    canvas.drawCircle(center, radius * 0.72, ringPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    for (var degree = 0; degree < 360; degree += 5) {
      final major = degree % 30 == 0;
      final cardinal = degree % 90 == 0;
      final tickPaint = Paint()
        ..color = cardinal
            ? dialColor
            : mutedColor.withValues(alpha: major ? 0.65 : 0.3)
        ..strokeWidth = cardinal ? 2.6 : (major ? 1.7 : 1);
      canvas.drawLine(
        Offset(0, -radius + 12),
        Offset(0, -radius + (cardinal ? 28 : major ? 23 : 18)),
        tickPaint,
      );
      canvas.rotate(5 * math.pi / 180);
    }
    canvas.restore();

    for (var index = 0; index < cardinalLabels.length; index++) {
      final angle = index * math.pi / 2 - math.pi / 2;
      final point = Offset(
        center.dx + math.cos(angle) * radius * 0.61,
        center.dy + math.sin(angle) * radius * 0.61,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: cardinalLabels[index],
          style: TextStyle(
            color: index == 0 ? accentColor : dialColor,
            fontSize: index == 0 ? 21 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        point - Offset(painter.width / 2, painter.height / 2),
      );
    }

    _paintKaabaIndicator(canvas, center, radius);
  }

  void _paintKaabaIndicator(Canvas canvas, Offset center, double radius) {
    final angle = qiblaBearing * math.pi / 180 - math.pi / 2;
    final lineStart = Offset(
      center.dx + math.cos(angle) * radius * 0.73,
      center.dy + math.sin(angle) * radius * 0.73,
    );
    final lineEnd = Offset(
      center.dx + math.cos(angle) * radius * 0.88,
      center.dy + math.sin(angle) * radius * 0.88,
    );
    canvas.drawLine(
      lineStart,
      lineEnd,
      Paint()
        ..color = accentColor
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    canvas.save();
    canvas.translate(lineStart.dx, lineStart.dy);
    canvas.rotate(angle + math.pi / 2);
    final kaaba = RRect.fromRectAndRadius(
      const Rect.fromCenter(center: Offset.zero, width: 27, height: 24),
      const Radius.circular(3),
    );
    canvas.drawRRect(kaaba, Paint()..color = const Color(0xFF191A18));
    canvas.drawRect(
      const Rect.fromLTWH(-13.5, -5, 27, 4),
      Paint()..color = accentColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-2.5, 1, 5, 9),
        const Radius.circular(1),
      ),
      Paint()..color = accentColor.withValues(alpha: 0.72),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) =>
      oldDelegate.qiblaBearing != qiblaBearing ||
      oldDelegate.dialColor != dialColor ||
      oldDelegate.mutedColor != mutedColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.cardinalLabels.join() != cardinalLabels.join();
}
