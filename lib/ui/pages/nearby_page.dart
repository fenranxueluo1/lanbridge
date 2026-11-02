import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../state/app_scope.dart';
import '../dialogs/nearby_dialogs.dart';
import '../flows/quick_send.dart';
import '../widgets/ambient_background.dart';
import '../widgets/device_card.dart';
import '../widgets/device_radar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_header.dart';

class NearbyPage extends StatelessWidget {
  const NearbyPage({super.key, required this.onOpenDevice});

  final ValueChanged<Device> onOpenDevice;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final palette = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 860;
    final horizontal = compact ? 20.0 : 32.0;
    final favorites = controller.favoriteDevices;
    final nearby = controller.nearbyDevices;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: controller.refreshDiscovery,
        color: palette.brand,
        backgroundColor: palette.surfaceElevated,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontal,
            compact ? 14 : 28,
            horizontal,
            compact ? 128 : 48,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    child: PageHeader(
                      eyebrow: l10n.tagline,
                      title: l10n.navNearby,
                      subtitle: l10n.nearbySubtitle,
                      compact: compact,
                      actions: [
                        ScanAction(
                          scanning: controller.isScanning,
                          onTap: controller.refreshDiscovery,
                          tooltip: l10n.scanAgain,
                        ),
                        const _MoreMenu(),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 26),
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    child: _NearbyHero(
                      controller: controller,
                      compact: compact,
                      onOpenDevice: onOpenDevice,
                    ),
                  ),
                  SizedBox(height: compact ? 14 : 18),
                  Reveal(
                    delay: const Duration(milliseconds: 110),
                    child: _ReceiveCard(controller: controller),
                  ),
                  SizedBox(height: compact ? 24 : 30),
                  if (favorites.isNotEmpty) ...[
                    Reveal(
                      delay: const Duration(milliseconds: 150),
                      child: SectionHeader(
                        title: l10n.favorites,
                        count: favorites.length,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DeviceGrid(
                      devices: favorites,
                      controller: controller,
                      compact: compact,
                      onOpenDevice: onOpenDevice,
                    ),
                    SizedBox(height: compact ? 24 : 30),
                  ],
                  Reveal(
                    delay: const Duration(milliseconds: 190),
                    child: SectionHeader(
                      title: l10n.nearbyDevices,
                      count: nearby.length,
                      trailing: Text(
                        controller.isScanning
                            ? l10n.discovering
                            : l10n.onlineCount(controller.onlineCount),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (nearby.isEmpty)
                    GlassPanel(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: EmptyState(
                        icon: Icons.wifi_find_rounded,
                        title: l10n.noDevicesTitle,
                        body: controller.engineError ?? l10n.noDevicesBody,
                        action: SoftButton(
                          label: l10n.scanAgain,
                          icon: Icons.refresh_rounded,
                          onPressed: controller.refreshDiscovery,
                        ),
                      ),
                    )
                  else
                    _DeviceGrid(
                      devices: nearby,
                      controller: controller,
                      compact: compact,
                      onOpenDevice: onOpenDevice,
                    ),
                  SizedBox(height: compact ? 26 : 34),
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
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      tooltip: l10n.manualConnect,
      icon: Icon(Icons.more_horiz_rounded, color: palette.textSecondary),
      onSelected: (value) async {
        if (value == 'manual') {
          // Let the popup menu route finish closing before opening the dialog.
          await Future<void>.delayed(const Duration(milliseconds: 220));
          if (!context.mounted) return;
          await showManualConnectDialog(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'manual',
          child: _menuRow(context, Icons.link_rounded, l10n.manualConnect),
        ),
      ],
    );
  }

  Widget _menuRow(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.palette.textSecondary),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _NearbyHero extends StatelessWidget {
  const _NearbyHero({
    required this.controller,
    required this.compact,
    required this.onOpenDevice,
  });

  final AppController controller;
  final bool compact;
  final ValueChanged<Device> onOpenDevice;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final onlineDevices =
        controller.devices.where((device) => device.isOnline).toList();

    final radar = SizedBox(
      height: compact ? 268 : 320,
      child: Center(
        child: DeviceRadar(
          devices: onlineDevices,
          onSelect: onOpenDevice,
          localName: controller.settings.deviceName,
          scanning: controller.isScanning,
        ),
      ),
    );

    final info = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LiveDot(active: !controller.isScanning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                controller.isScanning
                    ? l10n.scanning
                    : l10n.devicesFoundCount(controller.onlineCount),
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.compatibilityNotice,
          style: context.textStyles.bodySmall?.copyWith(
            color: palette.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _Stat(
              value: '${controller.onlineCount}',
              label: l10n.quickStatsDevices,
            ),
            _StatDivider(),
            _Stat(
              value: '${controller.activeJobs.length}',
              label: l10n.quickStatsActive,
            ),
            _StatDivider(),
            _Stat(
              value: Formatters.bytes(controller.savedBytes, decimals: 1),
              label: l10n.quickStatsSaved,
              accent: AppColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            SoftButton(
              label: l10n.manualConnect,
              icon: Icons.link_rounded,
              height: 44,
              onPressed: () => showManualConnectDialog(context),
            ),
            SoftButton(
              label: l10n.scanAgain,
              icon: Icons.refresh_rounded,
              height: 44,
              onPressed: controller.refreshDiscovery,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 13,
              color: AppColors.green,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.securedBy,
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return GlassPanel(
      padding: EdgeInsets.all(compact ? 18 : 26),
      radius: 30,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.surfaceElevated.withValues(alpha: 0.95),
          palette.surface.withValues(alpha: 0.92),
        ],
      ),
      borderColor: palette.brand.withValues(alpha: 0.16),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [radar, const SizedBox(height: 8), info],
            )
          : Row(
              children: [
                Expanded(flex: 6, child: radar),
                const SizedBox(width: 22),
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: info,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReceiveCard extends StatelessWidget {
  const _ReceiveCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final enabled = controller.settings.receiveEnabled;

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      radius: 22,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: enabled
                  ? AppGradients.aurora
                  : LinearGradient(
                      colors: [
                        palette.textTertiary.withValues(alpha: 0.35),
                        palette.textTertiary.withValues(alpha: 0.2),
                      ],
                    ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.download_for_offline_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.receiveCardTitle,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled ? l10n.receiveCardHint : l10n.receiveOffHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: enabled,
            onChanged: controller.setReceiveEnabled,
          ),
        ],
      ),
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({
    required this.devices,
    required this.controller,
    required this.compact,
    required this.onOpenDevice,
  });

  final List<Device> devices;
  final AppController controller;
  final bool compact;
  final ValueChanged<Device> onOpenDevice;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 620
                ? 2
                : 1;
        const gap = 14.0;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final device in devices)
              SizedBox(
                width: itemWidth,
                child: DeviceCard(
                  device: device,
                  compact: compact,
                  onTap: () => onOpenDevice(device),
                  onSend: () => openQuickSend(context, controller, [device]),
                  onToggleFavorite: () =>
                      controller.toggleFavorite(device.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent ?? palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: context.palette.hairline,
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.green : AppColors.amber;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 9,
          ),
        ],
      ),
    );
  }
}
