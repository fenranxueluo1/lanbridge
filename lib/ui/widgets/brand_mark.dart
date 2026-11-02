import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// In-app brand mark: the Flutter default logo on a light app-icon tile, so it
/// matches the launcher icon shipped with this build.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: palette.hairline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.35 : 0.10,
            ),
            blurRadius: size * 0.45,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: FlutterLogo(size: size * 0.88),
    );
  }
}
