import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../data/models/transfer.dart';
import '../../state/app_scope.dart';
import '../flows/open_transfer_folder.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/device_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_button.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/progress_ring.dart';
import '../widgets/toast.dart';
import '../widgets/transfer_status.dart';

class TransferDetailPage extends StatelessWidget {
  const TransferDetailPage({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final job = controller.jobById(jobId);

    if (job == null) {
      return AppPageScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.transferDetails,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: l10n.jobNotFound,
                  body: l10n.noActiveBody,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              title: l10n.transferDetails,
              subtitle: job.peerName,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroCard(job: job),
                        const SizedBox(height: 14),
                        _StatsCard(job: job),
                        const SizedBox(height: 22),
                        SectionHeader(
                          title: l10n.transferItemList,
                          count: job.files.length,
                        ),
                        const SizedBox(height: 10),
                        _FilesCard(job: job),
                        const SizedBox(height: 20),
                        _Actions(
                          job: job,
                          controller: controller,
                          onCancel: () => _confirmCancel(context, controller, job),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(
    BuildContext context,
    AppController controller,
    TransferJob job,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.cancelConfirmTitle),
          content: Text(l10n.cancelConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.keepGoing),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.cancelTransfer),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      controller.cancelJob(job.id);
      if (context.mounted) {
        showAppToast(
          context,
          context.l10n.transferCancelled,
          icon: Icons.block_rounded,
        );
      }
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.job});

  final TransferJob job;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final color = transferStatusColor(job.status);
    final directionText = job.direction == TransferDirection.send
        ? l10n.sendingTo(job.peerName)
        : l10n.receivingFrom(job.peerName);

    return GlassPanel(
      padding: const EdgeInsets.all(24),
      radius: 28,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.surfaceElevated,
          palette.surface,
        ],
      ),
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Text(
                transferStatusLabel(context, job.status),
                style: context.textStyles.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (job.isSmart) ...[
                const SizedBox(width: 8),
                CapabilityChip(
                  icon: Icons.bolt_rounded,
                  label: l10n.deltaBadge,
                  compact: true,
                  accent: AppColors.cyan,
                ),
              ],
              if (job.isResumed) ...[
                const SizedBox(width: 5),
                CapabilityChip(
                  icon: Icons.restart_alt_rounded,
                  label: l10n.resumeBadge,
                  compact: true,
                  accent: AppColors.green,
                ),
              ],
            ],
          ),
          const SizedBox(height: 22),
          ProgressRing(
            progress: job.progress,
            size: 196,
            strokeWidth: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(job.progress * 100).round()}%',
                  style: context.textStyles.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.progressLabel,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.progressOf(
              Formatters.bytes(job.transferredBytes),
              Formatters.bytes(job.totalBytes),
            ),
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DeviceAvatar(
                icon: job.peerKind.icon,
                gradient: job.peerKind.gradient,
                size: 22,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  directionText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.job});

  final TransferJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final active = job.status == TransferStatus.transferring;
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      radius: 22,
      child: Row(
        children: [
          _Stat(
            icon: Icons.speed_rounded,
            value: active ? Formatters.speed(job.speed) : '—',
            label: l10n.speedLabel,
          ),
          _divider(palette),
          _Stat(
            icon: Icons.timer_outlined,
            value: Formatters.duration(job.eta, l10n),
            label: l10n.remainingLabel,
          ),
          _divider(palette),
          _Stat(
            icon: Icons.bolt_rounded,
            value: Formatters.bytes(job.savedBytes),
            label: l10n.savedLabel,
            accent: AppColors.cyan,
          ),
        ],
      ),
    );
  }

  Widget _divider(AppPalette palette) {
    return Container(
      width: 1,
      height: 34,
      color: palette.hairline,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 15, color: accent ?? palette.textTertiary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilesCard extends StatelessWidget {
  const _FilesCard({required this.job});

  final TransferJob job;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final completed = job.status == TransferStatus.completed;

    return GlassPanel(
      padding: const EdgeInsets.all(14),
      radius: 22,
      child: Column(
        children: [
          for (var i = 0; i < job.files.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Divider(color: palette.hairline, height: 1),
              ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: palette.brandSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    job.files[i].isDirectory
                        ? Icons.folder_rounded
                        : Formatters.iconForFile(job.files[i].name),
                    size: 17,
                    color: palette.brand,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.files[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: GradientProgressBar(
                              value: job.files[i].progress,
                              height: 4,
                              gradient: completed
                                  ? const LinearGradient(
                                      colors: [
                                        AppColors.green,
                                        AppColors.teal,
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            Formatters.bytes(job.files[i].size),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: palette.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  job.files[i].isComplete
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  size: 17,
                  color: job.files[i].isComplete
                      ? AppColors.green
                      : palette.textTertiary,
                ),
              ],
            ),
          ],
          if (job.error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.error!,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (completed) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.transferComplete,
                style: context.textStyles.labelSmall?.copyWith(
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.job,
    required this.controller,
    required this.onCancel,
  });

  final TransferJob job;
  final AppController controller;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (job.status.isActive) {
      return SoftButton(
        label: l10n.cancelTransfer,
        icon: Icons.close_rounded,
        danger: true,
        expanded: true,
        height: 52,
        onPressed: onCancel,
      );
    }

    if (job.direction == TransferDirection.send) {
      return GradientButton(
        label: l10n.sendAgain,
        icon: Icons.refresh_rounded,
        expanded: true,
        onPressed: () {
          Haptics.action();
          controller.retryJob(job.id);
        },
      );
    }

    if (job.status == TransferStatus.completed) {
      return Row(
        children: [
          Expanded(
            child: SoftButton(
              label: l10n.openLocation,
              icon: Icons.folder_open_rounded,
              expanded: true,
              height: 52,
              onPressed: () => openTransferFolder(context, job),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SoftButton(
              label: l10n.done,
              icon: Icons.check_rounded,
              expanded: true,
              height: 52,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      );
    }

    return SoftButton(
      label: l10n.done,
      icon: Icons.check_rounded,
      expanded: true,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}
