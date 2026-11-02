import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/auto_backup.dart' show folderLastBackupKey;
import '../backup/backup_flow.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'auto_backup_screen.dart';
import 'backup_checks.dart';
import 'recovery_cases_screen.dart';
import 'readable_copy_screen.dart';
import 'recovery_code_dialog.dart';
import 'restore_screen.dart';
import 'storage_screens.dart';

/// Last time the backup folder was written, if ever.
final folderLastBackupProvider = FutureProvider<DateTime?>((ref) async {
  final last = await ref.watch(onboardingStoreProvider).setting(folderLastBackupKey);
  return last == null ? null : DateTime.tryParse(last);
});

/// "3 days ago", "today", "never".
String ago(DateTime? when, [DateTime? now]) {
  if (when == null) return 'never';
  final n = now ?? DateTime.now();
  final days = DateTime(n.year, n.month, n.day).difference(DateTime(when.year, when.month, when.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

/// How many places hold a backup, and when the newest copy was made.
(int, DateTime?) backupState(WidgetRef ref) {
  final drive = ref.watch(driveStatusProvider).valueOrNull;
  final folder = ref.watch(backupFolderProvider).valueOrNull;
  final folderLast = ref.watch(folderLastBackupProvider).valueOrNull;
  final times = [?drive?.$2, ?folderLast]..sort();
  return ((drive?.$1 != null ? 1 : 0) + (folder != null ? 1 : 0), times.lastOrNull);
}

/// Frame 16b: one place for everything about keeping records safe, with the
/// state first (is it backed up, where, when).
class BackupRecoveryScreen extends ConsumerWidget {
  const BackupRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoverySet = ref.watch(recoverySetProvider).valueOrNull ?? false;
    final drive = ref.watch(driveStatusProvider).valueOrNull;
    final folder = ref.watch(backupFolderProvider).valueOrNull;
    final folderLast = ref.watch(folderLastBackupProvider).valueOrNull;
    final auto = ref.watch(autoBackupSettingsProvider).valueOrNull;
    final driveOn = drive?.$1 != null;
    final (places, last) = backupState(ref);

    final (title, body) = switch (places) {
      0 => ('Not backed up yet', 'Make a backup so you can get your records back if this phone is lost.'),
      1 => ('Backed up in 1 place', 'Add a second place for more safety.'),
      _ => ('Safe in 2 places', 'Google Drive and a folder. If this phone is lost, you can still get everything back.'),
    };

    Widget tile(String label, String sub, VoidCallback? onTap) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
    void open(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Backup and recovery',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR RECORDS ARE',
                  style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(body, style: const TextStyle(color: Color(0xFFC9DCD2), height: 1.4)),
                const SizedBox(height: 12),
                Text(
                  'Last backup: ${ago(last)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OnboardButton(
            label: 'Back up now',
            onPressed: recoverySet ? () => runBackup(context, ref) : null,
          ),
          if (!recoverySet)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Make your recovery code first. It asks when you add your first person.',
                style: TextStyle(color: onboardMuted),
              ),
            ),
          const SectionLabel('Where backups go'),
          Card(
            child: Column(
              children: [
                tile(
                  'Google Drive',
                  driveOn ? '${drive!.$1} · last ${ago(drive.$2)}' : 'Not connected',
                  () => open(const StorageChoiceScreen()),
                ),
                const Divider(height: 1),
                tile(
                  'A folder',
                  folder != null ? 'Last copy ${ago(folderLast)}' : 'Not chosen',
                  () => open(const StorageChoiceScreen()),
                ),
                const Divider(height: 1),
                tile(
                  'Automatic backups',
                  (auto?.enabled ?? false)
                      ? 'On, ${auto?.everyDays == 7 ? 'every week' : 'every day'}'
                      : 'Off. Back up by itself to Google Drive or a folder.',
                  () => open(const AutoBackupScreen()),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Text(
              'Two places is safer than one. Everything is locked with your recovery code before it leaves this phone.',
              style: TextStyle(color: onboardMuted, height: 1.4),
            ),
          ),
          const SectionLabel('Your recovery code'),
          Card(
            child: tile(
              'Check that I still have it',
              recoverySet
                  ? 'Type it in. It is only checked on this phone.'
                  : "Not set up yet. You'll make one before your first record.",
              recoverySet ? () => _check(context, ref) : null,
            ),
          ),
          if (recoverySet)
            Card(
              child: Column(
                children: [
                  tile(
                    'Where did you keep it?',
                    ref.watch(codeKeptProvider).valueOrNull ?? 'Tap to note it, so you know where to look',
                    () => askWhereCodeKept(context, ref),
                  ),
                  const Divider(height: 1),
                  tile(
                    'Check my backup',
                    'Opens your latest backup with the code. Restores nothing',
                    () => checkMyBackup(context, driveOn: driveOn),
                  ),
                  const Divider(height: 1),
                  tile(
                    'Print a recovery sheet',
                    'A page to fill in and keep. No health data',
                    printRecoverySheet,
                  ),
                  const Divider(height: 1),
                  tile(
                    'Make a new recovery code',
                    'If you lost it, or think someone saw it',
                    () => makeNewRecoveryCode(context, ref),
                  ),
                ],
              ),
            ),
          const SectionLabel('Get your records back'),
          Card(
            child: tile(
              'Restore from a backup',
              'Replaces what is on this phone.',
              () => open(const RestoreVaultScreen(replacing: true)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: tile(
              'Save a readable copy',
              'Last resort. Not protected, you choose where it goes',
              () => open(const ReadableCopyScreen()),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: const Color(0xFFFBEFD2),
            child: tile(
              'I lost my phone, my code, or both',
              'See every way to get your records back',
              () => open(const RecoveryCasesScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final record = await ref.read(onboardingStoreProvider).readRecovery();
    if (record == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => RecoveryCodeDialog(
        verify: record.matches,
        title: 'Check your recovery code',
        intro: 'Type the code from your copy. It is checked on this phone and never stored or sent.',
        actionLabel: 'Check',
        cancelLabel: 'Close',
        closeOnMatch: false,
      ),
    );
  }
}
