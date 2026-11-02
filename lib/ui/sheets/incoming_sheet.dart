import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../data/models/transfer.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/device_avatar.dart';
import '../widgets/gradient_button.dart';
import '../widgets/toast.dart';

Future<bool?> showIncomingSheet(
  BuildContext context,
  AppController controller,
  TransferJob job,
) async {
  final result = await showAppSheet<bool>(
    context: context,
    builder: (_) => _IncomingSheet(job: job),
  );
  if (!context.mounted) return result;
  if (result == true) {
    controller.acceptIncoming(job);
    Haptics.success();
    showAppToast(
      context,
      context.l10n.acceptedToast,
      icon: Icons.south_rounded,
    );
  } else if (result == false) {
    controller.declineIncoming(job);
    showAppToast(
      context,
      context.l10n.declinedToast,
      icon: Icons.block_rounded,
    );
  }
  return result;
}

class _IncomingSheet extends StatefulWidget {
  const _IncomingSheet({required this.job});

  final TransferJob job;

  @override
  State<_IncomingSheet> createState() => _IncomingSheetState();
}

class _IncomingSheetState extends State<_IncomingSheet> {
  final TextEditingController _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _accept() {
    final job = widget.job;
    if (job.requiredPin != null) {
      final value = _pinController.text.trim();
      if (value.length != 6) {
        Haptics.action();
        setState(() => _error = context.l10n.pinError);
        return;
      }
    }
    Haptics.action();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final job = widget.job;
    final visible = job.files.take(4).toList();
    final hidden = job.files.length - visible.length;

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
                  gradient: AppGradients.aurora,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.south_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.incomingTitle,
                      style: context.textStyles.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.filesCount(job.files.length),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.hairline),
            ),
            child: Row(
              children: [
                DeviceAvatar(
                  icon: job.peerKind.icon,
                  gradient: job.peerKind.gradient,
                  size: 46,
                  glow: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.peerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 13,
                            color: palette.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              job.peerId.isEmpty
                                  ? (job.peerIp ?? '')
                                  : Formatters.fingerprint(job.peerId),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelSmall?.copyWith(
                                color: palette.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              job.peerIp ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelSmall?.copyWith(
                                color: palette.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.hairline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(height: 11),
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: palette.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Formatters.iconForFile(visible[i].name),
                          size: 16,
                          color: palette.brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          visible[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.bytes(visible[i].size),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (hidden > 0) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.andMore(hidden),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Divider(color: palette.hairline, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      l10n.totalSizeOf(Formatters.bytes(job.totalBytes)),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (job.mode == TransferMode.smart)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: AppColors.cyan,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            l10n.deltaBadge,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: AppColors.cyan,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (job.requiredPin != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.pin_rounded, size: 16, color: palette.brand),
                const SizedBox(width: 6),
                Text(
                  l10n.pinRequired,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Spacer(),
                Flexible(
                  child: Text(
                    l10n.pinHintDemo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              style: context.textStyles.titleLarge?.copyWith(
                letterSpacing: 8,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: l10n.pinLabel,
                counterText: '',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SoftButton(
                  label: l10n.decline,
                  icon: Icons.close_rounded,
                  expanded: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: GradientButton(
                  label: l10n.accept,
                  icon: Icons.south_rounded,
                  expanded: true,
                  onPressed: _accept,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.connectionSecure,
              style: context.textStyles.labelSmall?.copyWith(
                color: palette.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
