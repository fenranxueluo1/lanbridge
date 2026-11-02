import 'package:flutter/material.dart';

import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';

class DeviceAvatar extends StatelessWidget {
  const DeviceAvatar({
    super.key,
    required this.icon,
    required this.gradient,
    this.size = 48,
    this.glow = false,
    this.opacity = 1,
  });

  final IconData icon;
  final LinearGradient gradient;
  final double size;
  final bool glow;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: gradient.colors.first.withValues(alpha: 0.35),
                    blurRadius: size * 0.55,
                    offset: Offset(0, size * 0.16),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, size: size * 0.46, color: Colors.white),
      ),
    );
  }
}

class LocalDeviceAvatar extends StatelessWidget {
  const LocalDeviceAvatar({super.key, this.size = 52, this.glow = true});

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return DeviceAvatar(
      icon: _platformIcon,
      gradient: _platformGradient,
      size: size,
      glow: glow,
    );
  }

  static IconData get _platformIcon {
    if (AppPlatform.isWindows) return Icons.desktop_windows_rounded;
    if (AppPlatform.isLinux) return Icons.terminal_rounded;
    if (AppPlatform.isAndroid) return Icons.smartphone_rounded;
    if (AppPlatform.isIOS) return Icons.phone_iphone_rounded;
    if (AppPlatform.isHarmony) return Icons.auto_awesome_rounded;
    if (AppPlatform.isMacOS) return Icons.laptop_mac_rounded;
    return Icons.devices_other_rounded;
  }

  static LinearGradient get _platformGradient {
    if (AppPlatform.isIOS) return AppGradients.phone;
    if (AppPlatform.isAndroid) return AppGradients.phone;
    if (AppPlatform.isHarmony) return AppGradients.tablet;
    if (AppPlatform.isLinux) return AppGradients.teal;
    return AppGradients.desktop;
  }
}

/// Small capability chip: icon + label.
class CapabilityChip extends StatelessWidget {
  const CapabilityChip({
    super.key,
    required this.icon,
    required this.label,
    this.accent,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Color? accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = accent ?? palette.brand;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 11 : 13, color: color),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
