import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/device.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.showLabel = true});

  final DeviceStatus status;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final label = statusLabel(context, status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showLabel ? 9 : 6,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: color),
          if (showLabel) ...[
            const SizedBox(width: 5),
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.status, this.size = 8});

  final DeviceStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _Dot(color: statusColor(status), size: size);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
        ],
      ),
    );
  }
}

Color statusColor(DeviceStatus status) => switch (status) {
      DeviceStatus.online => AppColors.green,
      DeviceStatus.busy => AppColors.amber,
      DeviceStatus.offline => const Color(0xFF7C8496),
    };

String statusLabel(BuildContext context, DeviceStatus status) {
  final l10n = context.l10n;
  return switch (status) {
    DeviceStatus.online => l10n.statusOnline,
    DeviceStatus.busy => l10n.statusBusy,
    DeviceStatus.offline => l10n.statusOffline,
  };
}
