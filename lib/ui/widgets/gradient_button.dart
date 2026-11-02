import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.expanded = false,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expanded;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null;
    final activeGradient = gradient ?? AppGradients.brandButton;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Ink(
            decoration: BoxDecoration(
              gradient: enabled
                  ? activeGradient
                  : LinearGradient(
                      colors: [
                        palette.textTertiary.withValues(alpha: 0.22),
                        palette.textTertiary.withValues(alpha: 0.16),
                      ],
                    ),
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.brand.withValues(alpha: 0.32),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            child: SizedBox(
              height: height,
              width: expanded ? double.infinity : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 19,
                        color: enabled
                            ? Colors.white
                            : palette.textTertiary,
                      ),
                      const SizedBox(width: 9),
                    ],
                    Text(
                      label,
                      style: context.textStyles.labelLarge?.copyWith(
                        color:
                            enabled ? Colors.white : palette.textTertiary,
                        fontWeight: FontWeight.w700,
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
  }
}

class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
    this.expanded = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool expanded;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = danger ? AppColors.red : palette.textPrimary;
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Ink(
            decoration: BoxDecoration(
              color: danger
                  ? AppColors.red.withValues(alpha: 0.10)
                  : palette.surfaceElevated,
              borderRadius: BorderRadius.circular(height / 2),
              border: Border.all(
                color: danger
                    ? AppColors.red.withValues(alpha: 0.35)
                    : palette.hairline,
              ),
            ),
            child: SizedBox(
              height: height,
              width: expanded ? double.infinity : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: accent),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: accent,
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
  }
}
