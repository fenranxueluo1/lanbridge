import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/app_controller.dart';
import '../../data/models/transfer.dart';
import '../../state/app_scope.dart';
import '../flows/open_transfer_folder.dart';
import '../widgets/device_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/page_header.dart';
import '../widgets/progress_ring.dart';
import '../widgets/segmented_control.dart';
import '../widgets/transfer_status.dart';

class TransfersPage extends StatefulWidget {
  const TransfersPage({super.key, required this.onOpenJob});

  final ValueChanged<String> onOpenJob;

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _TransfersPageState extends State<TransfersPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final palette = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 860;
    final active = controller.activeJobs;
    final history = controller.historyJobs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? 20 : 32,
          compact ? 14 : 28,
          compact ? 20 : 32,
          compact ? 128 : 48,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: l10n.securedBy,
                  title: l10n.transfersTitle,
                  subtitle: l10n.transfersSubtitle,
                  compact: compact,
                ),
                SizedBox(height: compact ? 18 : 24),
                if (compact)
                  SegmentedControl<int>(
                    value: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                    options: [
                      SegmentOption(
                        value: 0,
                        label: l10n.tabActive,
                        icon: Icons.bolt_rounded,
                        count: active.length,
                      ),
                      SegmentOption(
                        value: 1,
                        label: l10n.tabHistory,
                        icon: Icons.history_rounded,
                        count: history.length,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      SizedBox(
                        width: 380,
                        child: SegmentedControl<int>(
                          value: _tab,
                          onChanged: (value) => setState(() => _tab = value),
                          options: [
                            SegmentOption(
                              value: 0,
                              label: l10n.tabActive,
                              icon: Icons.bolt_rounded,
                              count: active.length,
                            ),
                            SegmentOption(
                              value: 1,
                              label: l10n.tabHistory,
                              icon: Icons.history_rounded,
                              count: history.length,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_tab == 1 && history.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            controller.clearHistory();
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline_rounded, size: 17),
                          label: Text(l10n.clearHistory),
                        ),
                    ],
                  ),
                SizedBox(height: compact ? 18 : 24),
                if (_tab == 0)
                  _ActiveSection(
                    jobs: active,
                    controller: controller,
                    onOpenJob: widget.onOpenJob,
                  )
                else
                  _HistorySection(
                    jobs: history,
                    controller: controller,
                    onOpenJob: widget.onOpenJob,
                  ),
                const SizedBox(height: 26),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 12,
                        color: palette.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.footerNote,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveSection extends StatelessWidget {
  const _ActiveSection({
    required this.jobs,
    required this.controller,
    required this.onOpenJob,
  });

  final List<TransferJob> jobs;
  final AppController controller;
  final ValueChanged<String> onOpenJob;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;

    if (jobs.isEmpty) {
      return GlassPanel(
        child: EmptyState(
          icon: Icons.swap_vert_rounded,
          title: l10n.noActiveTitle,
          body: l10n.noActiveBody,
        ),
      );
    }

    final speed = jobs.fold<double>(0, (sum, job) => sum + job.speed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          radius: 20,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              palette.brandSoft,
              palette.surface.withValues(alpha: 0.9),
            ],
          ),
          borderColor: palette.brand.withValues(alpha: 0.22),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: AppGradients.aurora,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.activeItems(jobs.length),
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.speed_rounded,
                size: 15,
                color: palette.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                Formatters.speed(speed),
                style: context.textStyles.labelMedium?.copyWith(
                  color: palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final job in jobs) ...[
          _ActiveCard(
            job: job,
            onTap: () => onOpenJob(job.id),
            onCancel: () => controller.cancelJob(job.id),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({
    required this.job,
    required this.onTap,
    required this.onCancel,
  });

  final TransferJob job;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final directionText = job.direction == TransferDirection.send
        ? l10n.sendingTo(job.peerName)
        : l10n.receivingFrom(job.peerName);

    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(15),
      radius: 22,
      child: Row(
        children: [
          ProgressRing(
            progress: job.progress,
            size: 62,
            strokeWidth: 6,
            child: Text(
              '${(job.progress * 100).round()}%',
              style: context.textStyles.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        directionText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.filesCount(job.files.length)} · ${Formatters.bytes(job.totalBytes)}',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                if (job.isSmart || job.isResumed) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      if (job.isSmart)
                        CapabilityChip(
                          icon: Icons.bolt_rounded,
                          label: l10n.deltaBadge,
                          compact: true,
                          accent: AppColors.cyan,
                        ),
                      if (job.isResumed)
                        CapabilityChip(
                          icon: Icons.restart_alt_rounded,
                          label: l10n.resumeBadge,
                          compact: true,
                          accent: AppColors.green,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 9),
                GradientProgressBar(
                  value: job.progress,
                  height: 5,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 12,
                      color: palette.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.speed(job.speed),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: palette.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.duration(job.eta, l10n),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: l10n.cancelTransfer,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 19,
              color: palette.textTertiary,
            ),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.jobs,
    required this.controller,
    required this.onOpenJob,
  });

  final List<TransferJob> jobs;
  final AppController controller;
  final ValueChanged<String> onOpenJob;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (jobs.isEmpty) {
      return GlassPanel(
        child: EmptyState(
          icon: Icons.history_rounded,
          title: l10n.noHistoryTitle,
          body: l10n.noHistoryBody,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final job in jobs) ...[
          _HistoryTile(
            job: job,
            onTap: () => onOpenJob(job.id),
            onRetry: job.direction == TransferDirection.send
                ? () {
                    Haptics.tap();
                    controller.retryJob(job.id);
                  }
                : null,
            onOpenFolder:
                job.direction == TransferDirection.receive &&
                        job.status == TransferStatus.completed
                    ? () => openTransferFolder(context, job)
                    : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.job,
    required this.onTap,
    this.onRetry,
    this.onOpenFolder,
  });

  final TransferJob job;
  final VoidCallback onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final color = transferStatusColor(job.status);
    final title = job.direction == TransferDirection.send
        ? l10n.sendingTo(job.peerName)
        : l10n.receivingFrom(job.peerName);

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 20,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              transferStatusIcon(job.status),
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${l10n.filesCount(job.files.length)} · ${Formatters.bytes(job.totalBytes)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transferStatusLabel(context, job.status),
                style: context.textStyles.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.relative(job.startedAt, l10n),
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ],
          ),
          if (onOpenFolder != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.openLocation,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.folder_open_rounded,
                size: 18,
                color: palette.textTertiary,
              ),
              onPressed: onOpenFolder,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: l10n.sendAgain,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.refresh_rounded,
                size: 18,
                color: palette.textTertiary,
              ),
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
