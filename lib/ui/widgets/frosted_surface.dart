import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// A floating neutral glass surface: backdrop blur, white specular highlights
/// and a white glass rim, with no colored fill or tint.
class FrostedSurface extends StatelessWidget {
  const FrostedSurface({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = EdgeInsets.zero,
    this.opacity = 0.14,
    this.blur = 28,
    this.borderColor,
    this.shadow = true,
    this.backdrop = true,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double blur;
  final Color? borderColor;
  final bool shadow;
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = context.isDark;
    final shape = BorderRadius.circular(radius);
    final glass = Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: palette.surface.withValues(alpha: opacity),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.08 : 0.18),
                  Colors.white.withValues(alpha: dark ? 0.02 : 0.04),
                  Colors.white.withValues(alpha: dark ? 0.02 : 0.06),
                ],
                stops: const [0, 0.52, 1],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1.3, -1.3),
                end: const Alignment(1.3, 1.3),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: dark ? 0.06 : 0.10),
                  Colors.transparent,
                ],
                stops: const [0.16, 0.38, 0.62],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.75, -0.9),
                radius: 1.15,
                colors: [
                  Colors.white.withValues(alpha: dark ? 0.10 : 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(padding: padding, child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GlassRimPainter(
                radius: radius,
                dark: dark,
                overrideColor: borderColor,
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: [
          if (shadow)
            BoxShadow(
              color: palette.shadow,
              blurRadius: 34,
              spreadRadius: -16,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: backdrop
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: glass,
              )
            : glass,
      ),
    );
  }
}

class _GlassRimPainter extends CustomPainter {
  const _GlassRimPainter({
    required this.radius,
    required this.dark,
    this.overrideColor,
  });

  final double radius;
  final bool dark;
  final Color? overrideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.7),
      Radius.circular(radius),
    );
    final rimRect = rect.deflate(0.7);
    final shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: overrideColor != null
          ? [
              overrideColor!,
              overrideColor!.withValues(alpha: 0.35),
              overrideColor!.withValues(alpha: 0.7),
            ]
          : [
              Colors.white.withValues(alpha: dark ? 0.45 : 0.95),
              Colors.white.withValues(alpha: dark ? 0.08 : 0.20),
              Colors.white.withValues(alpha: dark ? 0.30 : 0.55),
            ],
      stops: const [0, 0.5, 1],
    ).createShader(rimRect);

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = shader,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(2.4),
        Radius.circular(radius - 1.7),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(alpha: dark ? 0.10 : 0.30),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassRimPainter oldDelegate) {
    return oldDelegate.radius != radius ||
        oldDelegate.dark != dark ||
        oldDelegate.overrideColor != overrideColor;
  }
}
