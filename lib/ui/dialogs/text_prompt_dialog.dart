import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// A text prompt whose controller lives with the dialog route. This avoids
/// disposing the controller while the dialog's exit transition is still
/// mounted (which can trip Flutter lifecycle assertions).
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  String hint = '',
  String initialText = '',
  String? confirmLabel,
  TextInputType? keyboardType,
  int minLines = 1,
  int maxLines = 1,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      hint: hint,
      initialText: initialText,
      confirmLabel: confirmLabel,
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.hint,
    required this.initialText,
    required this.confirmLabel,
    required this.keyboardType,
    required this.minLines,
    required this.maxLines,
  });

  final String title;
  final String hint;
  final String initialText;
  final String? confirmLabel;
  final TextInputType? keyboardType;
  final int minLines;
  final int maxLines;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

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
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel ?? l10n.save),
        ),
      ],
    );
  }
}
