import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../data/models/transfer.dart';
import '../flows/file_picking.dart';
import 'frosted_surface.dart';

/// Accepts OS file and folder drops on desktop and turns them into send items.
class DesktopDropTarget extends StatefulWidget {
  const DesktopDropTarget({
    super.key,
    required this.onFiles,
    required this.child,
  });

  final ValueChanged<List<TransferFile>> onFiles;
  final Widget child;

  @override
  State<DesktopDropTarget> createState() => _DesktopDropTargetState();
}

class _DesktopDropTargetState extends State<DesktopDropTarget> {
  bool _dragging = false;

  Future<void> _handleDrop(DropDoneDetails details) async {
    if (_dragging) setState(() => _dragging = false);
    final paths = details.files
        .map((file) => file.path)
        .where((path) => path.trim().isNotEmpty)
        .toList();
    if (paths.isEmpty) return;
    final files = await transferFilesFromPaths(paths);
    if (!mounted || files.isEmpty) return;
    widget.onFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DropTarget(
      onDragEntered: (_) {
        if (!_dragging) setState(() => _dragging = true);
      },
      onDragExited: (_) {
        if (_dragging) setState(() => _dragging = false);
      },
      onDragDone: _handleDrop,
      child: Stack(
        children: [
          widget.child,
          if (_dragging)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: palette.bg.withValues(alpha: 0.58),
                  child: Center(
                    child: FrostedSurface(
                      radius: 28,
                      opacity: 0.20,
                      blur: 34,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: palette.brand.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.file_upload_outlined,
                              color: palette.brand,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.l10n.dropFilesHint,
                            style: context.textStyles.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
