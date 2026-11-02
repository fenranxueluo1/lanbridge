import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Surface container used across the app. Keeps radii, hairline borders and
/// shadow depth consistent between desktop and mobile.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color,
    this.gradient,
    this.borderColor,
    this.shadow = true,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final bool shadow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? palette.surface) : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? palette.hairline),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 36,
                spreadRadius: -18,
                offset: const Offset(0, 18),
              ),
            ]
          : null,
    );

    final content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (onTap == null && onLongPress == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: content,
    );
  }
}
