import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

EdgeInsets _toastMargin(BuildContext context) {
  if (MediaQuery.sizeOf(context).width < 720) {
    return EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.paddingOf(context).bottom + 96,
    );
  }
  return const EdgeInsets.fromLTRB(20, 0, 20, 20);
}

void showAppToast(BuildContext context, String message, {IconData? icon}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: _toastMargin(context),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: context.palette.brand),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
