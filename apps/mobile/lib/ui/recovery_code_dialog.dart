import 'package:flutter/material.dart';

import '../crypto/recovery_code.dart';

/// Asks for the recovery code and checks it on this phone. The dialog owns its
/// text field, so the controller is only disposed once the dialog is gone;
/// disposing it right after `showDialog` returns, while the close animation is
/// still running, crashed the Back up flow.
///
/// With [closeOnMatch] the dialog returns the typed code (Back up); without it
/// the dialog stays open and says whether it matched (Check your code).
class RecoveryCodeDialog extends StatefulWidget {
  const RecoveryCodeDialog({
    super.key,
    required this.verify,
    required this.title,
    required this.intro,
    required this.actionLabel,
    this.cancelLabel = 'Cancel',
    this.closeOnMatch = true,
  });

  final Future<bool> Function(RecoveryCode code) verify;
  final String title;
  final String intro;
  final String actionLabel;
  final String cancelLabel;
  final bool closeOnMatch;

  @override
  State<RecoveryCodeDialog> createState() => _RecoveryCodeDialogState();
}

class _RecoveryCodeDialogState extends State<RecoveryCodeDialog> {
  final _input = TextEditingController();
  String? _message;
  bool _working = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = RecoveryCode.parse(_input.text);
    if (code == null) {
      setState(() => _message = 'That is not 24 characters of a code.');
      return;
    }
    setState(() => _working = true);
    final ok = await widget.verify(code);
    if (!mounted) return; // closed while checking
    if (ok && widget.closeOnMatch) {
      Navigator.pop(context, code);
      return;
    }
    setState(() {
      _working = false;
      _message = ok
          ? 'That matches your recovery code.'
          : 'That does not match your recovery code.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.intro),
          const SizedBox(height: 12),
          TextField(
            controller: _input,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        TextButton(
          onPressed: _working ? null : _submit,
          child: Text(_working ? 'Checking…' : widget.actionLabel),
        ),
      ],
    );
  }
}
