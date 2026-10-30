import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../crash/crash_log.dart';

const reportAddress = 'hello@amrutham.app';

/// Shows exactly what would be sent, then opens the share sheet. Nothing is
/// sent unless the person picks an app and sends it.
Future<void> showProblemReport(BuildContext context) async {
  final log = await CrashLog.open();
  if (!context.mounted) return;
  final text = log.read();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Send a problem report'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text.isEmpty
                  ? 'No problems have been recorded on this phone.'
                  : 'This is everything that would be shared. It holds the '
                      'time and technical details of each crash, never your '
                      'records, names or messages. Send it to $reportAddress.',
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (text.isNotEmpty)
          TextButton(
            onPressed: () {
              log.clear();
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete log'),
          ),
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        if (text.isNotEmpty)
          TextButton(
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile(log.file.path, mimeType: 'text/plain')],
                subject: 'Amrutham problem report',
                text: 'Please send this to $reportAddress',
              ),
            ),
            child: const Text('Share'),
          ),
      ],
    ),
  );
}
