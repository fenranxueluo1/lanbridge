import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 42,
    this.highlight = false,
    this.foreground,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final bool highlight;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: highlight ? palette.brandSoft : palette.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: highlight
                  ? palette.brand.withValues(alpha: 0.35)
                  : palette.hairline,
            ),
          ),
          child: Icon(
            icon,
            size: size * 0.44,
            color: foreground ??
                (highlight ? palette.brand : palette.textSecondary),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            if (onBack != null) ...[
              CircleActionButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack,
                tooltip: context.l10n.close,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 10),
              Wrap(spacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
