import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import 'frosted_surface.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FrostedSurface(
          radius: 22,
          opacity: 0.46,
          blur: 0,
          backdrop: false,
          shadow: false,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 16,
                    color: palette.hairline,
                  ),
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 9, right: 6),
            child: Text(
              footer!,
              style: context.textStyles.bodySmall?.copyWith(
                color: palette.textTertiary,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = danger ? AppColors.red : palette.brand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: danger
                            ? AppColors.red
                            : palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ValueText extends StatelessWidget {
  const ValueText({super.key, required this.value, this.maxWidth = 160});

  final String value;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        value,
        textAlign: TextAlign.end,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.bodySmall?.copyWith(
          color: context.palette.textSecondary,
        ),
      ),
    );
  }
}
