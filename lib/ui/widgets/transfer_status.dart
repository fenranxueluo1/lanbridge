import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/transfer.dart';

String transferStatusLabel(BuildContext context, TransferStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    TransferStatus.waiting => l10n.statusWaiting,
    TransferStatus.preparing => l10n.statusWaiting,
    TransferStatus.transferring => l10n.statusTransferring,
    TransferStatus.verifying => l10n.statusVerifying,
    TransferStatus.paused => l10n.statusPaused,
    TransferStatus.completed => l10n.statusCompleted,
    TransferStatus.failed => l10n.statusFailed,
    TransferStatus.cancelled => l10n.statusCancelled,
  };
}

Color transferStatusColor(TransferStatus status) => switch (status) {
      TransferStatus.waiting => AppColors.amber,
      TransferStatus.preparing => AppColors.cyan,
      TransferStatus.transferring => AppColors.brand,
      TransferStatus.verifying => AppColors.cyan,
      TransferStatus.paused => AppColors.amber,
      TransferStatus.completed => AppColors.green,
      TransferStatus.failed => AppColors.red,
      TransferStatus.cancelled => const Color(0xFF7C8496),
    };

IconData transferStatusIcon(TransferStatus status) => switch (status) {
      TransferStatus.waiting => Icons.schedule_rounded,
      TransferStatus.preparing => Icons.settings_rounded,
      TransferStatus.transferring => Icons.swap_vert_rounded,
      TransferStatus.verifying => Icons.verified_rounded,
      TransferStatus.paused => Icons.pause_rounded,
      TransferStatus.completed => Icons.check_rounded,
      TransferStatus.failed => Icons.priority_high_rounded,
      TransferStatus.cancelled => Icons.block_rounded,
    };
