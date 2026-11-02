import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../data/models/transfer.dart';
import '../sheets/send_sheet.dart';
import '../widgets/toast.dart';
import 'file_picking.dart';

Future<bool> openQuickSend(
  BuildContext context,
  AppController controller,
  List<Device> targets,
) async {
  if (targets.isEmpty) return false;
  if (!controller.engineReady) {
    showAppToast(context, context.l10n.engineNotReady,
        icon: Icons.hourglass_top_rounded);
    return false;
  }

  List<TransferFile> files;
  try {
    files = await pickTransferFiles(FileType.any);
  } catch (_) {
    if (context.mounted) {
      showAppToast(context, context.l10n.pickerFailed,
          icon: Icons.error_outline_rounded);
    }
    return false;
  }
  if (files.isEmpty || !context.mounted) return false;

  final mode = await showSendSheet(
    context,
    files: files,
    targets: targets,
  );
  if (mode == null) return false;

  final jobs = await controller.startTransfers(
    targets: targets,
    files: files,
    mode: mode,
  );
  if (!context.mounted) return jobs.isNotEmpty;
  showAppToast(
    context,
    jobs.isEmpty ? context.l10n.sendFailed : context.l10n.transferStarted,
    icon: jobs.isEmpty
        ? Icons.error_outline_rounded
        : Icons.arrow_upward_rounded,
  );
  return jobs.isNotEmpty;
}
