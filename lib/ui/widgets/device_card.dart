import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/device.dart';
import 'device_avatar.dart';
import 'status_pill.dart';

class DeviceCard extends StatefulWidget {
  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onSend,
    this.onToggleFavorite,
    this.compact = false,
  });

  final Device device;
  final VoidCallback? onTap;
  final VoidCallback? onSend;
  final VoidCallback? onToggleFavorite;
  final bool compact;

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final palette = context.palette;
    final l10n = context.l10n;
    final active = _hover && device.isOnline;

    return MouseRegion(
      cursor: device.isOnline
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onToggleFavorite,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(widget.compact ? 14 : 16),
          decoration: BoxDecoration(
            color: active ? palette.surfaceElevated : palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active
                  ? palette.brand.withValues(alpha: 0.45)
                  : palette.hairline,
            ),
            boxShadow: [
              BoxShadow(
                color: active
                    ? palette.brand.withValues(alpha: 0.14)
                    : palette.shadow,
                blurRadius: active ? 30 : 24,
                spreadRadius: active ? 0 : -16,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  DeviceAvatar(
                    icon: device.kind.icon,
                    gradient: device.kind.gradient,
                    size: widget.compact ? 42 : 48,
                    glow: device.isOnline && !widget.compact,
                    opacity: device.isOnline ? 1 : 0.55,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                device.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textStyles.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (device.isFavorite)
                              const Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: AppColors.amber,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${device.model} · ${device.ip}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    status: device.status,
                    showLabel: !widget.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (device.supportsDelta)
                    CapabilityChip(
                      icon: Icons.bolt_rounded,
                      label: l10n.capDelta,
                      compact: true,
                    ),
                  if (device.supportsResume) ...[
                    const SizedBox(width: 6),
                    CapabilityChip(
                      icon: Icons.restart_alt_rounded,
                      label: l10n.capResume,
                      compact: true,
                      accent: AppColors.cyan,
                    ),
                  ],
                  const Spacer(),
                  if (device.isOnline && widget.onSend != null)
                    _SendAction(onTap: widget.onSend!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendAction extends StatelessWidget {
  const _SendAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: palette.brandSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.arrow_upward_rounded,
                size: 13,
                color: palette.brand,
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.send,
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
