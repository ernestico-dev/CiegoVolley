import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Un trozo del diagrama de pastel.
class DonutSlice {
  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;
}

/// Diagrama de pastel en forma de dona, animado al aparecer.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 118,
    this.centerLabel,
    this.centerValue,
  });

  final List<DonutSlice> slices;
  final double size;
  final String? centerLabel;
  final String? centerValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.value);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) {
        return SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _DonutPainter(
                  slices: slices,
                  total: total,
                  progress: progress,
                  trackColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              if (centerValue != null || centerLabel != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (centerValue != null)
                      Text(
                        centerValue!,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    if (centerLabel != null)
                      Text(
                        centerLabel!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.progress,
    required this.trackColor,
  });

  final List<DonutSlice> slices;
  final int total;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.19;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (total <= 0) return;

    const gap = 0.035;
    var start = -math.pi / 2;

    for (final slice in slices) {
      if (slice.value <= 0) continue;

      final sweep = (slice.value / total) * math.pi * 2 * progress;
      final painted = math.max(0.0, sweep - gap);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = slice.color;

      canvas.drawArc(rect, start, painted, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.total != total ||
        oldDelegate.slices != slices ||
        oldDelegate.trackColor != trackColor;
  }
}
