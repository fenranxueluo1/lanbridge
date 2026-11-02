import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.eyebrow,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final String? eyebrow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  eyebrow!.toUpperCase(),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textSecondary,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (compact
                            ? context.textStyles.headlineLarge
                            : context.textStyles.displaySmall)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        subtitle!,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: palette.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Wrap(spacing: 8, children: actions),
              ),
          ],
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.count,
  });

  final String title;
  final Widget? trailing;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              gradient: AppGradients.aurora,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
