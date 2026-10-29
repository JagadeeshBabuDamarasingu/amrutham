import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../crypto/recovery_code.dart';
import '../providers/app_providers.dart';
import 'vault_backup.dart';
import 'drive_backup.dart';

/// Asks for the recovery code, then writes an encrypted backup to Google
/// Drive and/or the chosen folder, or opens the share sheet if neither is set.
Future<void> runBackup(BuildContext context, WidgetRef ref) async {
  final record = await ref.read(onboardingStoreProvider).readRecovery();
  if (record == null || !context.mounted) return;
  final input = TextEditingController();
  String? error;
  bool working = false;
  final code = await showDialog<RecoveryCode>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Back up your vault'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Type your recovery code. It locks the backup, so only the code opens it.'),
            const SizedBox(height: 12),
            TextField(
              controller: input,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX'),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: working
                ? null
                : () async {
                    final parsed = RecoveryCode.parse(input.text);
                    if (parsed == null) {
                      setState(() => error = 'That is not 24 characters of a code.');
                      return;
                    }
                    setState(() => working = true);
                    final ok = await record.matches(parsed);
                    if (!ok) {
                      setState(() {
                        working = false;
                        error = 'That does not match your recovery code.';
                      });
                      return;
                    }
                    if (dialogContext.mounted) Navigator.pop(dialogContext, parsed);
                  },
            child: Text(working ? 'Checking…' : 'Back up'),
          ),
        ],
      ),
    ),
  );
  input.dispose();
  if (code == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Making your backup…')));
  final realm = await ref.read(databaseProvider.future);
  final vault = await ref.read(vaultDirectoryProvider.future);
  final bytes = await VaultBackup.encrypt(await VaultBackup.snapshot(realm, vault), code);
  final now = DateTime.now();
  final name =
      'amrutham-backup-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.amrutham';
  final store = ref.read(onboardingStoreProvider);
  final saved = <String>[];

  if (await store.setting(driveEmailKey) != null) {
    try {
      await DriveSession.instance.upload(bytes);
      await store.putSetting(driveLastBackupKey, DateTime.now().toIso8601String());
      ref.invalidate(driveStatusProvider);
      saved.add('Google Drive');
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't reach Google Drive. Check your connection.")),
      );
    }
  }

  final folder = await store.backupFolder();
  if (folder != null) {
    try {
      // One fixed name, overwritten each time, so a sync app sees one file.
      await File('$folder/amrutham-backup.amrutham').writeAsBytes(bytes, flush: true);
      saved.add('your folder');
    } on FileSystemException {
      messenger.showSnackBar(
        const SnackBar(content: Text("Couldn't write to that folder.")),
      );
    }
  }

  messenger.hideCurrentSnackBar();
  if (saved.isNotEmpty) {
    messenger.showSnackBar(SnackBar(content: Text('Backed up to ${saved.join(' and ')}')));
    return;
  }
  final file = File('${(await getTemporaryDirectory()).path}/$name');
  await file.writeAsBytes(bytes);
  // The share sheet lets you save it to Files or Drive, or send it to
  // yourself. Keep it somewhere that is not only this phone.
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: name));
}
