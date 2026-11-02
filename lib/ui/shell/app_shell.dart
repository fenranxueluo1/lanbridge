import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_info.dart';
import '../../core/platform/app_platform.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../data/models/transfer.dart';
import '../../state/app_scope.dart';
import '../pages/device_detail_page.dart';
import '../pages/nearby_page.dart';
import '../pages/send_page.dart';
import '../pages/settings_page.dart';
import '../pages/transfer_detail_page.dart';
import '../pages/transfers_page.dart';
import '../flows/open_transfer_folder.dart';
import '../sheets/incoming_sheet.dart';
import '../widgets/ambient_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/device_avatar.dart';
import '../widgets/desktop_drop_target.dart';
import '../widgets/frosted_surface.dart';
import '../widgets/toast.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _showingIncoming = false;
  bool _statusesInitialized = false;
  final Map<String, TransferStatus> _knownStatuses = {};

  void _maybeShowIncoming(AppController controller) {
    final incoming = controller.pendingIncoming;
    if (incoming == null || _showingIncoming) return;
    _showingIncoming = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _showingIncoming = false;
        return;
      }
      await showIncomingSheet(context, controller, incoming.job);
      _showingIncoming = false;
    });
  }

  void _trackTransfers(BuildContext context, AppController controller) {
    final jobs = <TransferJob>[
      ...controller.activeJobs,
      ...controller.historyJobs,
    ];
    if (!_statusesInitialized) {
      for (final job in jobs) {
        _knownStatuses[job.id] = job.status;
      }
      _statusesInitialized = true;
      return;
    }

    final finished = <TransferJob>[];
    for (final job in jobs) {
      final previous = _knownStatuses[job.id];
      if (previous != null && previous.isActive && job.status.isFinished) {
        finished.add(job);
      }
      _knownStatuses[job.id] = job.status;
    }

    for (final job in finished) {
      if (job.status == TransferStatus.cancelled) continue;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final l10n = context.l10n;
        if (job.status == TransferStatus.completed) {
          if (job.direction == TransferDirection.receive) {
            showAppToastWithAction(
              context,
              l10n.transferComplete,
              actionLabel: l10n.openLocation,
              onAction: () => openTransferFolder(context, job),
              icon: Icons.check_circle_rounded,
            );
          } else {
            showAppToast(
              context,
              l10n.transferComplete,
              icon: Icons.check_circle_rounded,
            );
          }
        } else if (job.status == TransferStatus.failed) {
          showAppToast(
            context,
            job.error ?? l10n.transferFailed,
            icon: Icons.error_outline_rounded,
          );
        }
      });
    }
  }

  void _select(int index) {
    if (index == _index) return;
    Haptics.tap();
    setState(() => _index = index);
  }

  void _openDevice(Device device) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeviceDetailPage(deviceId: device.id),
      ),
    );
  }

  void _openTransfer(String jobId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransferDetailPage(jobId: jobId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    _maybeShowIncoming(controller);
    _trackTransfers(context, controller);
    final activeJobs = controller.activeJobs;

    final pages = <Widget>[
      TickerMode(
        enabled: _index == 0,
        child: NearbyPage(onOpenDevice: _openDevice),
      ),
      TickerMode(enabled: _index == 1, child: const SendPage()),
      TickerMode(
        enabled: _index == 2,
        child: TransfersPage(onOpenJob: _openTransfer),
      ),
      TickerMode(enabled: _index == 3, child: const SettingsPage()),
    ];

    final shortcuts = <ShortcutActivator, VoidCallback>{};
    for (var i = 0; i < 4; i++) {
      final digit = [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
      ][i];
      shortcuts[SingleActivator(digit, control: true)] = () => _select(i);
      shortcuts[SingleActivator(digit, meta: true)] = () => _select(i);
    }

    Widget shellContent = LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= 1080;
        final rail = constraints.maxWidth >= 720;
        final content = IndexedStack(index: _index, children: pages);

        if (!rail) {
          return Stack(
            children: [
              Positioned.fill(
                child: SafeArea(bottom: false, child: content),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (activeJobs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _ActiveTransferBanner(
                            jobs: activeJobs,
                            onTap: () => _select(2),
                          ),
                        ),
                      _MobileNav(
                        index: _index,
                        onSelect: _select,
                        activeCount: activeJobs.length,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            if (expanded)
              _Sidebar(
                controller: controller,
                index: _index,
                onSelect: _select,
              )
            else
              _Rail(
                controller: controller,
                index: _index,
                onSelect: _select,
              ),
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    Positioned.fill(child: content),
                    if (activeJobs.isNotEmpty)
                      Positioned(
                        right: 24,
                        bottom: 24,
                        child: _ActiveTransferBanner(
                          jobs: activeJobs,
                          onTap: () => _select(2),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (AppPlatform.isDesktop) {
      shellContent = DesktopDropTarget(
        onFiles: (files) {
          controller.addPendingSendFiles(files);
          _select(1);
          showAppToast(
            context,
            context.l10n.droppedFiles(files.length),
            icon: Icons.attach_file_rounded,
          );
        },
        child: shellContent,
      );
    }

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: AmbientBackground(child: shellContent),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}

List<_Destination> _destinations(BuildContext context) {
  final l10n = context.l10n;
  return [
    _Destination(l10n.navNearby, Icons.radar_rounded),
    _Destination(l10n.navSend, Icons.arrow_upward_rounded),
    _Destination(l10n.navTransfers, Icons.swap_vert_rounded),
    _Destination(l10n.navSettings, Icons.tune_rounded),
  ];
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.controller,
    required this.index,
    required this.onSelect,
  });

  final AppController controller;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final items = _destinations(context);

    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: palette.bgSecondary.withValues(alpha: 0.72),
        border: Border(right: BorderSide(color: palette.hairline)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Row(
                children: [
                  const BrandMark(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appName,
                          style: context.textStyles.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.tagline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
            for (var i = 0; i < items.length; i++)
              _SidebarItem(
                destination: items[i],
                selected: i == index,
                badgeCount: i == 2 ? controller.activeJobs.length : 0,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _LocalDeviceCard(
                controller: controller,
                onTap: () => onSelect(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: palette.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.engineReady
                          ? '${controller.settings.httpsEnabled ? 'HTTPS' : 'HTTP'} · ${controller.localPort ?? controller.settings.port}'
                          : l10n.engineNotReady,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppInfo.version,
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
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = widget.selected;
    final iconColor = selected
        ? palette.brand
        : (_hover ? palette.textPrimary : palette.textSecondary);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: _hover && !selected
                ? palette.surface.withValues(alpha: 0.8)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(widget.destination.icon, size: 19, color: iconColor),
              const SizedBox(width: 12),
              Text(
                widget.destination.label,
                style: context.textStyles.titleSmall?.copyWith(
                  color: selected
                      ? palette.brand
                      : (_hover ? palette.textPrimary : palette.textSecondary),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (widget.badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (selected)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalDeviceCard extends StatelessWidget {
  const _LocalDeviceCard({required this.controller, required this.onTap});

  final AppController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.hairline),
        ),
        child: Row(
          children: [
            const LocalDeviceAvatar(size: 38, glow: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.settings.deviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          '${l10n.on} · ${controller.settings.port}',
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
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.controller,
    required this.index,
    required this.onSelect,
  });

  final AppController controller;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = _destinations(context);
    return Container(
      width: 86,
      decoration: BoxDecoration(
        color: palette.bgSecondary.withValues(alpha: 0.72),
        border: Border(right: BorderSide(color: palette.hairline)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: BrandMark(size: 38),
            ),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Tooltip(
                  message: items[i].label,
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: i == index
                                ? palette.brandSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: i == index
                                  ? palette.brand.withValues(alpha: 0.24)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Icon(
                            items[i].icon,
                            size: 21,
                            color: i == index
                                ? palette.brand
                                : palette.textSecondary,
                          ),
                        ),
                        if (i == 2 && controller.activeJobs.isNotEmpty)
                          Positioned(
                            right: -3,
                            top: -3,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: palette.bgSecondary,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  controller.activeJobs.length > 9
                                      ? '9+'
                                      : '${controller.activeJobs.length}',
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Tooltip(
                message: controller.settings.deviceName,
                child: const LocalDeviceAvatar(size: 36, glow: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav({
    required this.index,
    required this.onSelect,
    this.activeCount = 0,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final items = _destinations(context);
    return FrostedSurface(
      radius: 33,
      opacity: 0.72,
      blur: 0,
      backdrop: false,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        height: 66,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _MobileNavItem(
                  destination: items[i],
                  selected: i == index,
                  badgeCount: i == 2 ? activeCount : 0,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.brand : palette.textTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(destination.icon, size: 20, color: color),
                  if (badgeCount > 0)
                    Positioned(
                      right: -8,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeCount > 9 ? '9+' : '$badgeCount',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                decoration: TextDecoration.none,
                decorationColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTransferBanner extends StatelessWidget {
  const _ActiveTransferBanner({required this.jobs, required this.onTap});

  final List<TransferJob> jobs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final total = jobs.fold<int>(0, (sum, job) => sum + job.totalBytes);
    final transferred =
        jobs.fold<int>(0, (sum, job) => sum + job.transferredBytes);
    final progress = total == 0 ? 0.0 : transferred / total;
    final speed = jobs.fold<double>(0, (sum, job) => sum + job.speed);
    final first = jobs.first;
    final label = jobs.length > 1
        ? l10n.activeItems(jobs.length)
        : (first.direction == TransferDirection.send
            ? l10n.sendingTo(first.peerName)
            : l10n.receivingFrom(first.peerName));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: FrostedSurface(
          radius: 999,
          opacity: 0.74,
          blur: 0,
          backdrop: false,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      backgroundColor: palette.hairline,
                      color: palette.brand,
                    ),
                    Icon(
                      first.direction == TransferDirection.send
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13,
                      color: palette.brand,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 230),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(progress * 100).round()}% · ${Formatters.speed(speed)}',
                      style: context.textStyles.labelSmall?.copyWith(
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: palette.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
