import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import 'frosted_surface.dart';

class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? count;
}

class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.height = 46,
    this.expand = true,
  });

  final List<SegmentOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final children = options.map((option) {
      final selected = option.value == value;
      return _Segment(
        option: option,
        selected: selected,
        height: height,
        expand: expand,
        onTap: () {
          if (selected) return;
          Haptics.tap();
          onChanged(option.value);
        },
      );
    }).toList();

    return FrostedSurface(
      radius: 16,
      opacity: 0.42,
      blur: 0,
      backdrop: false,
      shadow: false,
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            if (expand) Expanded(child: children[i]) else children[i],
          ],
        ],
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.height,
    required this.expand,
    required this.onTap,
  });

  final SegmentOption<T> option;
  final bool selected;
  final double height;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = selected ? palette.brand : palette.textSecondary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.white.withValues(
                    alpha: context.isDark ? 0.26 : 0.65,
                  )
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, size: 16, color: foreground),
              const SizedBox(width: 7),
            ],
            Text(
              option.label,
              style: context.textStyles.labelLarge?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (option.count != null) ...[
              const SizedBox(width: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.55)
                        : palette.hairline,
                  ),
                ),
                child: Text(
                  '${option.count}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: selected ? palette.brand : palette.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
