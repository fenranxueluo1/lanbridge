import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: compact ? 28 : 44,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 60 : 72,
              height: compact ? 60 : 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    palette.brand.withValues(alpha: 0.18),
                    AppColors.cyan.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(compact ? 20 : 24),
                border: Border.all(color: palette.hairline),
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 30,
                color: palette.brand,
              ),
            ),
            SizedBox(height: compact ? 16 : 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(
                  color: palette.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            if (action != null) ...[
              SizedBox(height: compact ? 16 : 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
