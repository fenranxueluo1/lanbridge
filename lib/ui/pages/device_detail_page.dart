import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../state/app_scope.dart';
import '../flows/quick_send.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/device_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_panel.dart';
import '../widgets/gradient_button.dart';
import '../widgets/page_header.dart';
import '../widgets/settings_tile.dart';
import '../widgets/status_pill.dart';
import '../widgets/toast.dart';

class DeviceDetailPage extends StatelessWidget {
  const DeviceDetailPage({super.key, required this.deviceId});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final device = controller.deviceById(deviceId);

    if (device == null) {
      return AppPageScaffold(
        child: SafeArea(
          child: Column(
            children: [
              AppTopBar(
                title: l10n.deviceDetails,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: EmptyState(
                  icon: Icons.devices_other_rounded,
                  title: l10n.noDevicesTitle,
                  body: l10n.forgetConfirmBody,
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
              title: l10n.deviceDetails,
              subtitle: device.model,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                CircleActionButton(
                  icon: device.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  tooltip: l10n.favoriteDevice,
                  highlight: device.isFavorite,
                  foreground:
                      device.isFavorite ? AppColors.amber : null,
                  onTap: () => controller.toggleFavorite(device.id),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeroCard(device: device),
                        const SizedBox(height: 20),
                        SettingsGroup(
                          title: l10n.connectionInfo,
                          children: [
                            SettingsTile(
                              icon: Icons.lan_outlined,
                              title: l10n.ipAddress,
                              subtitle: device.ip,
                              trailing: IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.copy_rounded, size: 17),
                                onPressed: () => _copy(context, device.ip),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.fingerprint_rounded,
                              title: l10n.fingerprint,
                              subtitle: Formatters.fingerprint(device.fingerprint),
                              trailing: IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.copy_rounded, size: 17),
                                onPressed: () =>
                                    _copy(context, device.fingerprint),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.schedule_rounded,
                              title: l10n.lastSeen,
                              subtitle: device.lastSeen == null
                                  ? l10n.connectedVia
                                  : Formatters.relative(
                                      device.lastSeen!,
                                      l10n,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _CapabilityWrap(device: device),
                        const SizedBox(height: 20),
                        SettingsGroup(
                          title: l10n.sectionDevice,
                          children: [
                            SettingsTile(
                              icon: Icons.star_outline_rounded,
                              title: l10n.favoriteDevice,
                              subtitle: l10n.favoriteHint,
                              trailing: Switch.adaptive(
                                value: device.isFavorite,
                                onChanged: (_) =>
                                    controller.toggleFavorite(device.id),
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.download_done_rounded,
                              title: l10n.autoAccept,
                              subtitle: l10n.autoAcceptHint,
                              trailing: Switch.adaptive(
                                value: controller.settings.autoAcceptFavorites,
                                onChanged: device.isFavorite
                                    ? controller.setAutoAcceptFavorites
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        GradientButton(
                          label: l10n.sendFiles,
                          icon: Icons.arrow_upward_rounded,
                          expanded: true,
                          onPressed: device.isOnline
                              ? () => openQuickSend(context, controller, [device])
                              : null,
                        ),
                        const SizedBox(height: 10),
                        SoftButton(
                          label: l10n.forgetDevice,
                          icon: Icons.delete_outline_rounded,
                          danger: true,
                          expanded: true,
                          height: 50,
                          onPressed: () => _forget(context, controller, device),
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

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      showAppToast(context, context.l10n.copied, icon: Icons.check_rounded);
    }
  }

  Future<void> _forget(
    BuildContext context,
    AppController controller,
    Device device,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.forgetConfirmTitle),
          content: Text(l10n.forgetConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      controller.forgetDevice(device.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return GlassPanel(
      padding: const EdgeInsets.all(24),
      radius: 28,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [palette.surfaceElevated, palette.surface],
      ),
      borderColor: device.kind.gradient.colors.first.withValues(alpha: 0.2),
      child: Column(
        children: [
          DeviceAvatar(
            icon: device.kind.icon,
            gradient: device.kind.gradient,
            size: 86,
            glow: device.isOnline,
            opacity: device.isOnline ? 1 : 0.6,
          ),
          const SizedBox(height: 16),
          Text(
            device.name,
            textAlign: TextAlign.center,
            style: context.textStyles.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            device.model,
            textAlign: TextAlign.center,
            style: context.textStyles.bodySmall?.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              StatusPill(status: device.status),
              CapabilityChip(
                icon: device.isCompatibleOnly
                    ? Icons.handshake_outlined
                    : Icons.verified_rounded,
                label: device.isCompatibleOnly
                    ? l10n.compatibleMode
                    : l10n.fullMode,
                accent: device.isCompatibleOnly
                    ? AppColors.amber
                    : AppColors.green,
              ),
              if (!device.https)
                CapabilityChip(
                  icon: Icons.lock_open_rounded,
                  label: l10n.unencrypted,
                  accent: AppColors.red,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityWrap extends StatelessWidget {
  const _CapabilityWrap({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chips = <Widget>[
      if (device.supportsResume)
        CapabilityChip(
          icon: Icons.restart_alt_rounded,
          label: l10n.capResume,
          accent: AppColors.cyan,
        ),
      if (device.supportsDelta)
        CapabilityChip(
          icon: Icons.bolt_rounded,
          label: l10n.capDelta,
          accent: AppColors.sky,
        ),
      if (device.supportsManifest)
        CapabilityChip(
          icon: Icons.folder_copy_outlined,
          label: l10n.capManifest,
          accent: AppColors.green,
        ),
      CapabilityChip(
        icon: Icons.password_rounded,
        label: l10n.capPin,
        accent: AppColors.amber,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.capabilitiesLabel),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}
