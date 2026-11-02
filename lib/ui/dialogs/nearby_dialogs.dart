import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../state/app_scope.dart';
import '../widgets/toast.dart';

Future<void> showManualConnectDialog(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<String>(
    context: context,
    builder: (_) => const _ManualConnectDialog(),
  );

  final value = result?.trim() ?? '';
  if (value.isEmpty || !context.mounted) return;

  final connected = await AppScope.read(context).connectManually(value);
  if (!context.mounted) return;
  if (connected) {
    Haptics.success();
  } else {
    Haptics.action();
  }
  showAppToast(
    context,
    connected ? l10n.manualConnectDone : l10n.manualConnectFailed,
    icon: connected ? Icons.check_rounded : Icons.error_outline_rounded,
  );
}

class _ManualConnectDialog extends StatefulWidget {
  const _ManualConnectDialog();

  @override
  State<_ManualConnectDialog> createState() => _ManualConnectDialogState();
}

class _ManualConnectDialogState extends State<_ManualConnectDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.manualConnectTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(hintText: l10n.manualConnectHint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.manualConnectAction),
        ),
      ],
    );
  }
}

class ScanAction extends StatelessWidget {
  const ScanAction({
    super.key,
    required this.scanning,
    required this.onTap,
    required this.tooltip,
  });

  final bool scanning;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scanning ? palette.brandSoft : palette.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: scanning
                    ? palette.brand.withValues(alpha: 0.4)
                    : palette.hairline,
              ),
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: scanning
                    ? SizedBox(
                        key: const ValueKey('scanning'),
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.brand,
                        ),
                      )
                    : Icon(
                        Icons.radar_rounded,
                        key: const ValueKey('idle'),
                        size: 19,
                        color: palette.textSecondary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
