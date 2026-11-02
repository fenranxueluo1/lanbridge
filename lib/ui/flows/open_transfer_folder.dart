import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_palette.dart';
import '../../core/utils/folder_opener.dart';
import '../../data/models/transfer.dart';
import '../../state/app_scope.dart';
import '../widgets/toast.dart';

Future<void> openTransferFolder(BuildContext context, TransferJob job) async {
  final controller = AppScope.read(context);
  var folder = controller.saveRoot;
  if (job.savedFiles.isNotEmpty) {
    folder = p.dirname(job.savedFiles.first);
  }
  final opened = await openFolder(folder);
  if (!context.mounted) return;
  if (!opened) {
    showAppToast(
      context,
      '${context.l10n.openLocation}: $folder',
      icon: Icons.folder_off_rounded,
    );
  }
}
