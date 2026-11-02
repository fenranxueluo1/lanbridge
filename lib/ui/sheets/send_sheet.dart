import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/device.dart';
import '../../data/models/transfer.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/device_avatar.dart';
import '../widgets/gradient_button.dart';

Future<TransferMode?> showSendSheet(
  BuildContext context, {
  required List<TransferFile> files,
  required List<Device> targets,
}) {
  return showAppSheet<TransferMode>(
    context: context,
    builder: (_) => _SendSheet(files: files, targets: targets),
  );
}

class _SendSheet extends StatefulWidget {
  const _SendSheet({required this.files, required this.targets});

  final List<TransferFile> files;
  final List<Device> targets;

  @override
  State<_SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<_SendSheet> {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final total = widget.files.fold<int>(0, (sum, file) => sum + file.size);
    final targetNames = widget.targets.map((device) => device.name).join(' · ');
    final allSecure = widget.targets.every((device) => device.https);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!AppPlatform.isDesktop) const SheetHandle(),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppGradients.brandButton,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sendSheetTitle,
                      style: context.textStyles.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      targetNames,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CircleActionButton(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FilesSummary(files: widget.files, total: total, targets: widget.targets),
          const SizedBox(height: 22),
          Text(
            l10n.transferMode,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _ModeTile(
            icon: Icons.swap_horiz_rounded,
            title: l10n.modeStandard,
            subtitle: l10n.modeStandardHint,
            selected: true,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          Text(
            l10n.compatTransferNote,
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          GradientButton(
            label: l10n.startTransfer,
            icon: Icons.send_rounded,
            expanded: true,
            onPressed: () => Navigator.of(context).pop(TransferMode.standard),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                allSecure ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                size: 13,
                color: allSecure ? palette.textTertiary : AppColors.amber,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  allSecure ? l10n.connectionSecure : l10n.insecureTransferWarning,
                  textAlign: TextAlign.center,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: allSecure ? palette.textTertiary : AppColors.amber,
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

class _FilesSummary extends StatelessWidget {
  const _FilesSummary({
    required this.files,
    required this.total,
    required this.targets,
  });

  final List<TransferFile> files;
  final int total;
  final List<Device> targets;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final visible = files.take(3).toList();
    final hidden = files.length - visible.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.hairline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                l10n.filesCount(files.length),
                style: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                Formatters.bytes(total),
                style: context.textStyles.labelMedium?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Formatters.iconForFile(visible[i].name),
                  size: 17,
                  color: palette.brand,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    visible[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodySmall,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  Formatters.bytes(visible[i].size),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
          ],
          if (hidden > 0)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.andMore(hidden),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 13),
          Divider(color: palette.hairline, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final device in targets.take(4))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DeviceAvatar(
                    icon: device.kind.icon,
                    gradient: device.kind.gradient,
                    size: 26,
                  ),
                ),
              if (targets.length > 4)
                Text(
                  '+${targets.length - 4}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              const Spacer(),
              Icon(
                Icons.verified_user_outlined,
                size: 13,
                color: AppColors.green,
              ),
              const SizedBox(width: 4),
              Text(
                '${targets.length}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = palette.brand;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.55)
                : palette.hairline,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? accent : Colors.transparent,
                border: Border.all(
                  color: selected ? accent : palette.textTertiary,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
