import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../backup/drive_backup.dart';
import '../backup/vault_backup.dart';
import 'recovery_code_dialog.dart';

/// Opens the newest backup with a typed code and says whether it works.
/// Nothing is restored and nothing on this phone changes.
Future<void> checkMyBackup(BuildContext context, {required bool driveOn}) async {
  List<int>? bytes;
  if (driveOn) {
    bytes = await DriveSession.instance.download();
  } else {
    final picked = await FilePicker.pickFiles();
    final path = picked.isEmpty ? null : picked.first.path;
    if (path == null) return;
    bytes = await File(path).readAsBytes();
  }
  if (!context.mounted) return;
  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No backup found there yet.')));
    return;
  }
  final data = bytes;
  await showDialog<void>(
    context: context,
    builder: (_) => RecoveryCodeDialog(
      verify: (code) async {
        try {
          await VaultBackup.decrypt(data, code);
          return true;
        } on BackupException {
          return false;
        }
      },
      title: 'Check my backup',
      intro: driveOn
          ? 'Type your recovery code. We open the backup in Google Drive to see that it works. Nothing is restored.'
          : 'Type your recovery code. We open the backup file you picked to see that it works. Nothing is restored.',
      actionLabel: 'Check',
      cancelLabel: 'Close',
      closeOnMatch: false,
    ),
  );
}

/// A page to print and keep: blanks for the recovery code and where it is,
/// and the steps to get records back. No health data, and never the code.
String recoverySheetHtml() =>
    '<html><body style="font-family:sans-serif;font-size:14px;line-height:1.5">'
    '<h1>Amrutham recovery sheet</h1>'
    '<p>Keep this somewhere safe, apart from your phone. It holds no health information.</p>'
    '<h2>My recovery code</h2>'
    '<p style="font-size:20px;border:1px solid #333;padding:14px;letter-spacing:2px">'
    '____ ____ ____ ____ ____ ____</p>'
    '<p>Write the code by hand. Amrutham cannot show it again, and nobody, including us, can open your backup without it.</p>'
    '<h2>My backups are in</h2>'
    '<p>Google account: ______________________________<br>Folder: ______________________________</p>'
    '<h2>If I lose my phone</h2>'
    '<ol><li>Install Amrutham on the new phone and tap Restore.</li>'
    '<li>Sign in to the same Google account, or choose the folder.</li>'
    '<li>Type the recovery code above.</li></ol>'
    '<p style="font-size:12px">amrutham.app</p>'
    '</body></html>';

Future<void> printRecoverySheet() => Printing.layoutPdf(
  name: 'Amrutham recovery sheet',
  onLayout: (format) => Printing.convertHtml(format: format, html: recoverySheetHtml()),
);
