import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';

/// Bottom sheet on phones, centered dialog on desktop.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  if (AppPlatform.isDesktop) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: SheetSurface(desktop: true, child: builder(dialogContext)),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SheetSurface(child: builder(sheetContext)),
      );
    },
  );
}

class SheetSurface extends StatelessWidget {
  const SheetSurface({
    super.key,
    required this.child,
    this.desktop = false,
  });

  final Widget child;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: desktop
            ? BorderRadius.circular(28)
            : const BorderRadius.vertical(top: Radius.circular(30)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            border: Border.all(color: palette.hairline),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4.5,
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        decoration: BoxDecoration(
          color: context.palette.textTertiary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
