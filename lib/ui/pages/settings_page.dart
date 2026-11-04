import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/app_controller.dart';
import '../../state/app_scope.dart';
import '../dialogs/text_prompt_dialog.dart';
import '../widgets/brand_mark.dart';
import '../widgets/page_header.dart';
import '../widgets/segmented_control.dart';
import '../widgets/settings_tile.dart';
import '../widgets/toast.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final settings = controller.settings;
    final l10n = context.l10n;
    final palette = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 860;

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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(
                  eyebrow: l10n.securedBy,
                  title: l10n.settingsTitle,
                  subtitle: l10n.settingsSubtitle,
                  compact: compact,
                ),
                SizedBox(height: compact ? 20 : 26),
                SettingsGroup(
                  title: l10n.sectionDevice,
                  children: [
                    SettingsTile(
                      icon: Icons.badge_outlined,
                      title: l10n.deviceName,
                      subtitle: settings.deviceName,
                      trailing: _chevron(palette),
                      onTap: () async {
                        final value = await _promptText(
                          context,
                          title: l10n.deviceNameDialogTitle,
                          initial: settings.deviceName,
                          hint: l10n.deviceNameHint,
                        );
                        if (value != null && value.trim().isNotEmpty) {
                          controller.setDeviceName(value);
                        }
                      },
                    ),
                    SettingsTile(
                      icon: Icons.science_outlined,
                      title: l10n.autoDeviceName,
                      subtitle: l10n.autoDeviceNameHint,
                      trailing: Switch.adaptive(
                        value: settings.autoDeviceName,
                        onChanged: controller.setAutoDeviceName,
                      ),
                    ),
                    // 鸿蒙端提供两个固定保存位置：应用沙箱 / 公共下载目录
                    // （Download/<包名>，持久化授权，文件管理可见）。
                    if (AppPlatform.isHarmony)
                      const _HarmonySaveLocationTile()
                    else
                      SettingsTile(
                        icon: Icons.folder_outlined,
                        title: l10n.saveLocation,
                        subtitle: Formatters.shortenPath(settings.savePath),
                        trailing: _chevron(palette),
                        onTap: () async {
                          try {
                            final directory =
                                await FilePicker.getDirectoryPath();
                            if (directory != null && directory.isNotEmpty) {
                              controller.setSavePath(directory);
                              return;
                            }
                          } catch (_) {
                            // Fall back to manual entry below.
                          }
                          if (!context.mounted) return;
                          final value = await _promptText(
                            context,
                            title: l10n.saveLocation,
                            initial: settings.savePath,
                            hint: '/Downloads/LANBridge',
                          );
                          if (value != null && value.trim().isNotEmpty) {
                            controller.setSavePath(value.trim());
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                SettingsGroup(
                  title: l10n.sectionNetwork,
                  children: [
                    SettingsTile(
                      icon: Icons.radar_rounded,
                      title: l10n.discovery,
                      subtitle: l10n.discoveryHint,
                      trailing: Switch.adaptive(
                        value: settings.discoveryEnabled,
                        onChanged: controller.setDiscoveryEnabled,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.download_for_offline_outlined,
                      title: l10n.allowReceiving,
                      subtitle: l10n.allowReceivingHint,
                      trailing: Switch.adaptive(
                        value: settings.receiveEnabled,
                        onChanged: controller.setReceiveEnabled,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.pin_outlined,
                      title: l10n.pinProtection,
                      subtitle: l10n.pinProtectionHint,
                      trailing: Switch.adaptive(
                        value: settings.pinEnabled,
                        onChanged: controller.setPinEnabled,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.lan_outlined,
                      title: l10n.port,
                      subtitle: '${settings.port}',
                      trailing: _chevron(palette),
                      onTap: () async {
                        final value = await _promptText(
                          context,
                          title: l10n.portDialogTitle,
                          initial: '${settings.port}',
                          keyboardType: TextInputType.number,
                        );
                        if (value == null) return;
                        final port = int.tryParse(value.trim());
                        if (port == null || port < 1024 || port > 65535) {
                          if (context.mounted) {
                            showAppToast(context, l10n.portInvalid,
                                icon: Icons.error_outline_rounded);
                          }
                          return;
                        }
                        controller.setPort(port);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: l10n.httpsEncryption,
                      subtitle: l10n.httpsEncryptionHint,
                      trailing: Switch.adaptive(
                        value: settings.httpsEnabled,
                        onChanged: controller.setHttpsEnabled,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.public_rounded,
                      title: l10n.shareWeb,
                      subtitle: l10n.shareWebHint,
                      trailing: Text(
                        l10n.comingSoon,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SettingsGroup(
                  title: l10n.sectionAppearance,
                  children: [
                    _ThemeTile(controller: controller),
                    _LanguageTile(controller: controller),
                  ],
                ),
                const SizedBox(height: 22),
                SettingsGroup(
                  title: l10n.sectionGeneral,
                  children: [
                    SettingsTile(
                      icon: Icons.star_outline_rounded,
                      title: l10n.autoAcceptFavorites,
                      subtitle: l10n.autoAcceptFavoritesHint,
                      trailing: Switch.adaptive(
                        value: settings.autoAcceptFavorites,
                        onChanged: controller.setAutoAcceptFavorites,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SettingsGroup(
                  title: l10n.sectionAbout,
                  children: [
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: l10n.version,
                      subtitle: AppInfo.version,
                    ),
                    SettingsTile(
                      icon: Icons.handshake_outlined,
                      title: l10n.protocol,
                      subtitle: l10n.protocolValue,
                    ),
                    SettingsTile(
                      icon: Icons.balance_outlined,
                      title: l10n.openSource,
                      trailing: _chevron(palette),
                      onTap: () => _showLongDialog(
                        context,
                        title: l10n.openSource,
                        body: l10n.licensesBody,
                      ),
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: l10n.privacy,
                      trailing: _chevron(palette),
                      onTap: () => _showLongDialog(
                        context,
                        title: l10n.privacy,
                        body: l10n.privacyBody,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                SettingsGroup(
                  title: l10n.sectionDiagnostics,
                  children: [
                    SettingsTile(
                      icon: Icons.description_outlined,
                      title: l10n.exportDiagnostics,
                      subtitle: l10n.exportDiagnosticsHint,
                      trailing: _chevron(palette),
                      onTap: () => showAppToast(
                        context,
                        l10n.exportDone,
                        icon: Icons.check_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      const BrandMark(size: 30),
                      const SizedBox(height: 10),
                      Text(
                        l10n.appName,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.tagline,
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

  Widget _chevron(AppPalette palette) => Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: palette.textTertiary,
      );

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String initial,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return showTextPromptDialog(
      context,
      title: title,
      hint: hint ?? '',
      initialText: initial,
      confirmLabel: context.l10n.save,
      keyboardType: keyboardType,
    );
  }

  Future<void> _showLongDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            body,
            style: dialogContext.textStyles.bodyMedium?.copyWith(
              height: 1.6,
              color: dialogContext.palette.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.done),
            ),
          ],
        );
      },
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(context, Icons.brightness_6_outlined),
              const SizedBox(width: 13),
              Text(
                l10n.theme,
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                switch (controller.settings.themeMode) {
                  ThemeMode.system => l10n.themeSystem,
                  ThemeMode.light => l10n.themeLight,
                  ThemeMode.dark => l10n.themeDark,
                },
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedControl<ThemeMode>(
            value: controller.settings.themeMode == ThemeMode.system
                ? null
                : controller.settings.themeMode,
            onChanged: controller.setThemeMode,
            height: 42,
            options: [
              SegmentOption(
                value: ThemeMode.light,
                label: l10n.themeLight,
                icon: Icons.light_mode_rounded,
              ),
              SegmentOption(
                value: ThemeMode.dark,
                label: l10n.themeDark,
                icon: Icons.dark_mode_rounded,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.themeSystemHint,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ),
              if (controller.settings.themeMode != ThemeMode.system)
                TextButton(
                  onPressed: () => controller.setThemeMode(ThemeMode.system),
                  child: Text(l10n.themeSystem),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(context, Icons.translate_rounded),
              const SizedBox(width: 13),
              Text(
                l10n.language,
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedControl<String>(
            value: controller.settings.locale.languageCode,
            onChanged: (value) => controller.setLocale(Locale(value)),
            height: 42,
            options: [
              SegmentOption(value: 'zh', label: l10n.chinese),
              SegmentOption(value: 'en', label: l10n.english),
            ],
          ),
        ],
      ),
    );
  }
}

/// HarmonyOS save-location picker: app sandbox or the public downloads folder
/// (`Download/<bundleName>`, visible in Files). Works on phones, tablets and
/// HarmonyOS PCs alike.
class _HarmonySaveLocationTile extends StatelessWidget {
  const _HarmonySaveLocationTile();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final palette = context.palette;
    final toDownloads = controller.settings.saveToDownloads;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(context, Icons.folder_outlined),
              const SizedBox(width: 13),
              Text(
                l10n.saveLocation,
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                toDownloads
                    ? l10n.saveLocationDownloads
                    : l10n.saveLocationApp,
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedControl<bool>(
            value: toDownloads,
            onChanged: (value) => _apply(context, value),
            height: 42,
            options: [
              SegmentOption(
                value: false,
                label: l10n.saveLocationApp,
                icon: Icons.folder_outlined,
              ),
              SegmentOption(
                value: true,
                label: l10n.saveLocationDownloads,
                icon: Icons.download_outlined,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            toDownloads
                ? l10n.saveLocationDownloadsHint
                : l10n.saveLocationAppHint,
            style: context.textStyles.labelSmall?.copyWith(
              color: palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apply(BuildContext context, bool value) async {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final ok = await controller.setSaveToDownloads(value);
    if (!ok && context.mounted) {
      showAppToast(
        context,
        l10n.saveLocationUnavailable,
        icon: Icons.error_outline_rounded,
      );
    }
  }
}

Widget _iconBox(BuildContext context, IconData icon) {
  final palette = context.palette;
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: palette.brand.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, size: 18, color: palette.brand),
  );
}
