import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.gradient,
    this.trackColor,
  });

  final double value;
  final double height;
  final Gradient? gradient;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: trackColor ?? palette.hairline),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient ?? AppGradients.aurora,
                    borderRadius: BorderRadius.circular(height),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
