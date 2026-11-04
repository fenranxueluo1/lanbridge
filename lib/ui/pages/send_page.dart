import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/haptics.dart';
import '../../data/app_controller.dart';
import '../../data/models/device.dart';
import '../../data/models/transfer.dart';
import '../../state/app_scope.dart';
import '../dialogs/text_prompt_dialog.dart';
import '../flows/file_picking.dart';
import '../sheets/send_sheet.dart';
import '../widgets/device_avatar.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_surface.dart';
import '../widgets/glass_panel.dart';
import '../widgets/page_header.dart';
import '../widgets/toast.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final List<TransferFile> _selected = [];
  final Set<String> _targetIds = {};
  bool _picking = false;
  AppController? _controller;
  int _lastDropRevision = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onControllerChanged);
      _controller = controller;
      _lastDropRevision = -1;
      controller.addListener(_onControllerChanged);
    }
    _consumeDroppedFiles();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    _consumeDroppedFiles();
  }

  void _consumeDroppedFiles() {
    final controller = _controller;
    if (controller == null) return;
    final revision = controller.pendingSendRevision;
    if (revision == _lastDropRevision) return;
    _lastDropRevision = revision;
    final files = controller.takePendingSendFiles();
    if (files.isEmpty || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _selected.addAll(files));
    });
  }

  int get _totalBytes =>
      _selected.fold(0, (sum, file) => sum + file.size);

  Future<void> _pickContent(String kind) async {
    if (_picking) return;
    Haptics.tap();
    setState(() => _picking = true);
    try {
      List<TransferFile> files = const [];
      switch (kind) {
        case 'photos':
          files = await pickTransferFiles(FileType.image);
        case 'videos':
          files = await pickTransferFiles(FileType.video);
        case 'files':
          files = await pickTransferFiles(FileType.any);
        case 'text':
          final text = await _promptText();
          if (text != null) {
            final file = await createTextTransferFile(text);
            if (file != null) files = [file];
          }
      }
      if (!mounted) return;
      if (files.isNotEmpty) {
        setState(() => _selected.addAll(files));
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context, context.l10n.pickerFailed,
            icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<String?> _promptText() {
    final l10n = context.l10n;
    return showTextPromptDialog(
      context,
      title: l10n.textMessageTitle,
      hint: l10n.textMessageHint,
      confirmLabel: l10n.send,
      minLines: 3,
      maxLines: 6,
    );
  }

  void _toggleTarget(String deviceId) {
    Haptics.tap();
    setState(() {
      if (!_targetIds.remove(deviceId)) {
        _targetIds.add(deviceId);
      }
    });
  }

  Future<void> _start(AppController controller) async {
    if (!controller.engineReady) {
      showAppToast(context, context.l10n.engineNotReady,
          icon: Icons.hourglass_top_rounded);
      return;
    }
    if (_selected.isEmpty) {
      showAppToast(context, context.l10n.noSelectionHint,
          icon: Icons.info_outline_rounded);
      return;
    }
    final targets = controller.devices
        .where((device) => _targetIds.contains(device.id))
        .toList();
    if (targets.isEmpty) {
      showAppToast(context, context.l10n.noDeviceSelectedHint,
          icon: Icons.info_outline_rounded);
      return;
    }
    Haptics.action();
    final mode = await showSendSheet(
      context,
      files: List.of(_selected),
      targets: targets,
    );
    if (mode == null || !mounted) return;

    final jobs = await controller.startTransfers(
      targets: targets,
      files: List.of(_selected),
      mode: mode,
    );
    if (!mounted) return;
    showAppToast(
      context,
      jobs.isEmpty ? context.l10n.sendFailed : context.l10n.transferStarted,
      icon: jobs.isEmpty
          ? Icons.error_outline_rounded
          : Icons.arrow_upward_rounded,
    );
    if (jobs.isNotEmpty) {
      setState(() {
        _selected.clear();
        _targetIds.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final l10n = context.l10n;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 860;
    final mobileLayout = width < 720;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final activeTransfer = controller.activeJobs.isNotEmpty;
    final stickyOffset = bottomPadding + 96 + (activeTransfer ? 64 : 0.0);
    final devices =
        controller.devices.where((device) => device.isOnline).toList();

    final scroll = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 32,
        compact ? 14 : 28,
        compact ? 20 : 32,
        mobileLayout
            ? 240 + bottomPadding + (activeTransfer ? 64 : 0)
            : (compact ? 128 : 48),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                eyebrow: l10n.connectionSecure,
                title: l10n.sendTitle,
                subtitle: l10n.sendSubtitle,
                compact: compact,
                actions: [
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: Text(l10n.clear),
                    ),
                ],
              ),
              SizedBox(height: compact ? 20 : 26),
              SectionHeader(title: l10n.addContent),
              const SizedBox(height: 12),
              Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  _AddChip(
                    icon: Icons.photo_outlined,
                    label: l10n.pickPhotos,
                    onTap: () => _pickContent('photos'),
                  ),
                  _AddChip(
                    icon: Icons.videocam_outlined,
                    label: l10n.pickVideos,
                    onTap: () => _pickContent('videos'),
                  ),
                  _AddChip(
                    icon: Icons.insert_drive_file_outlined,
                    label: l10n.pickFiles,
                    onTap: () => _pickContent('files'),
                  ),
                  _AddChip(
                    icon: Icons.text_snippet_outlined,
                    label: l10n.pickText,
                    onTap: () => _pickContent('text'),
                  ),
                ],
              ),
              SizedBox(height: compact ? 20 : 26),
              GlassPanel(
                padding: const EdgeInsets.all(16),
                child: _selectionContent(context),
              ),
              SizedBox(height: compact ? 24 : 30),
              SectionHeader(
                title: l10n.chooseDevice,
                count: _targetIds.length,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 1000
                      ? 3
                      : constraints.maxWidth >= 620
                          ? 2
                          : 1;
                  const gap = 12.0;
                  final itemWidth =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final device in devices)
                        SizedBox(
                          width: itemWidth,
                          child: _SelectableDeviceTile(
                            device: device,
                            selected: _targetIds.contains(device.id),
                            onTap: () => _toggleTarget(device.id),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (!mobileLayout) ...[
                SizedBox(height: compact ? 24 : 30),
                _actionPanel(context, controller),
              ],
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: mobileLayout
          ? Stack(
              children: [
                Positioned.fill(child: scroll),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: stickyOffset,
                  child: _actionPanel(context, controller),
                ),
              ],
            )
          : scroll,
    );
  }

  Widget _selectionContent(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    if (_selected.isEmpty) {
      return EmptyState(
        icon: Icons.layers_outlined,
        title: l10n.emptySelectionTitle,
        body: l10n.emptySelectionBody,
        compact: true,
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Text(
              l10n.selectedContent,
              style: context.textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: palette.brandSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_selected.length}',
                style: context.textStyles.labelSmall?.copyWith(
                  color: palette.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              l10n.totalSizeOf(Formatters.bytes(_totalBytes)),
              style: context.textStyles.labelSmall?.copyWith(
                color: palette.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _selected.length; i++) ...[
          if (i > 0) const SizedBox(height: 9),
          _SelectedRow(
            file: _selected[i],
            onRemove: () => setState(() => _selected.removeAt(i)),
          ),
        ],
      ],
    );
  }

  Widget _actionPanel(BuildContext context, AppController controller) {
    final l10n = context.l10n;
    final palette = context.palette;
    final targets = _targetIds.length;

    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectedCount(_selected.length),
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${l10n.totalSizeOf(Formatters.bytes(_totalBytes))} · ${l10n.targetCount(targets)}',
          style: context.textStyles.bodySmall?.copyWith(
            color: palette.textSecondary,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: l10n.send,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _start(controller),
          child: FrostedSurface(
            padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
            radius: 32,
            opacity: 0.74,
            blur: 0,
            backdrop: false,
            child: Row(
              children: [
                Expanded(child: summary),
                const SizedBox(width: 12),
                Text(
                  l10n.send,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: palette.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: palette.brand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: palette.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  gradient: AppGradients.aurora,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 9),
              Text(
                label,
                style: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedRow extends StatelessWidget {
  const _SelectedRow({required this.file, required this.onRemove});

  final TransferFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.brandSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              file.isDirectory
                  ? Icons.folder_rounded
                  : Formatters.iconForFile(file.name),
              size: 17,
              color: palette.brand,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  Formatters.bytes(file.size),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.remove,
            icon: Icon(
              Icons.close_rounded,
              size: 17,
              color: palette.textTertiary,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _SelectableDeviceTile extends StatelessWidget {
  const _SelectableDeviceTile({
    required this.device,
    required this.selected,
    required this.onTap,
  });

  final Device device;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? palette.surfaceElevated : palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? palette.brand.withValues(alpha: 0.55)
                : palette.hairline,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            DeviceAvatar(
              icon: device.kind.icon,
              gradient: device.kind.gradient,
              size: 40,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.model,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? palette.brand : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? palette.brand
                      : palette.textTertiary.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

