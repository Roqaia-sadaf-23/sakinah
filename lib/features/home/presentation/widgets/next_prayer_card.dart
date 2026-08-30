import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_extensions.dart';
import '../../../prayer_times/domain/entities/prayer.dart';
import '../../../prayer_times/presentation/controllers/prayer_times_controller.dart';

class NextPrayerCard extends StatelessWidget {
  const NextPrayerCard({required this.controller, super.key});

  final PrayerTimesController controller;

  @override
  Widget build(BuildContext context) {
    final prayer = controller.nextPrayer.value;
    return Container(
      constraints: const BoxConstraints(minHeight: 250),
      decoration: BoxDecoration(
        color: AppColors.deepEmerald,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepEmerald.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: const _IslamicPatternPainter(),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide =
                  constraints.hasBoundedWidth && constraints.maxWidth >= 540;
              final prayerInfo = _PrayerInfo(
                name: prayer?.name.key.tr ?? '—',
                time: prayer == null ? '—' : controller.formatTime(prayer.time),
              );
              final countdown = _Countdown(
                value: controller.remaining.value.clock,
              );
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: prayerInfo),
                    Container(
                      width: 1,
                      height: 110,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    const SizedBox(width: 30),
                    Expanded(child: countdown),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [prayerInfo, const SizedBox(height: 28), countdown],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrayerInfo extends StatelessWidget {
  const _PrayerInfo({required this.name, required this.time});

  final String name;
  final String time;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(
            Icons.brightness_3_rounded,
            size: 18,
            color: AppColors.sand.withValues(alpha: 0.95),
          ),
          const SizedBox(width: 8),
          Text(
            'next_prayer'.tr.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
      const SizedBox(height: 13),
      Text(
        name,
        style: Theme.of(
          context,
        ).textTheme.displaySmall?.copyWith(color: Colors.white, fontSize: 38),
      ),
      const SizedBox(height: 3),
      Text(
        time,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.sand,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'next_prayer_in'.tr,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
      ),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          value,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}

class _IslamicPatternPainter extends CustomPainter {
  const _IslamicPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = AppColors.sand.withValues(alpha: 0.09);
    canvas.drawCircle(Offset(size.width * 0.9, -6), size.width * 0.3, glow);
    canvas.drawCircle(Offset(size.width * 0.98, size.height), 74, glow);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const spacing = 34.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + spacing / 2, size.height - spacing / 2)
        ..lineTo(x + spacing, size.height);
      canvas.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
