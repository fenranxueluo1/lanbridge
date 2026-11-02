import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.child,
    this.showGlow = true,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Widget? child;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return CustomPaint(
            painter: _RingPainter(
              value: value,
              strokeWidth: strokeWidth,
              trackColor: palette.hairline.withValues(alpha: 0.6),
              showGlow: showGlow,
            ),
            child: Center(child: child),
          );
        },
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.showGlow,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final bool showGlow;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (value <= 0.001) return;

    final shader = SweepGradient(
      colors: AppGradients.aurora.colors,
      stops: AppGradients.aurora.stops,
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    final arc = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * value,
      false,
      arc,
    );

    if (showGlow) {
      final angle = -math.pi / 2 + 2 * math.pi * value;
      final head = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final glowPaint = Paint()
        ..color = const Color(0xFF9BDDFF).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(head, strokeWidth * 0.6, glowPaint);
      canvas.drawCircle(
        head,
        strokeWidth * 0.32,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}
