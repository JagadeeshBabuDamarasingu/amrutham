import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_flow.dart';
import '../crypto/recovery_code.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'language_screen.dart';
import 'problem_report.dart';
import 'restore_screen.dart';
import 'storage_screens.dart';
import 'strings.dart';

/// Only what is real today: the privacy promise and the recovery code check.
/// Sync, language and sharing settings from the designs come with those
/// features.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recoverySet = ref.watch(recoverySetProvider).valueOrNull ?? false;
    final folder = ref.watch(backupFolderProvider).valueOrNull;
    final tipsHidden = ref.watch(tipsHiddenProvider).valueOrNull ?? false;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            tr(context, 'Settings'),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: onboardInk,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WHAT LEAVES THIS PHONE',
                  style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 12, letterSpacing: 1),
                ),
                SizedBox(height: 8),
                Text(
                  'Nothing, unless you choose it.',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 12),
                _Bullet('No account, no analytics'),
                _Bullet('Database encrypted with a key on this device'),
                _Bullet('Plain files you can read without the app'),
              ],
            ),
          ),
          const SectionLabel('Recovery'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              title: const Text(
                'Recovery code',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                recoverySet
                    ? 'Saved. Check that your copy still matches.'
                    : "Not set up yet. You'll make one before your first record.",
              ),
              trailing: recoverySet ? const Icon(Icons.chevron_right) : null,
              onTap: recoverySet ? () => _check(context, ref) : null,
            ),
          ),
          const SectionLabel('Backup'),
          Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  title: const Text('Back up now', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    recoverySet
                        ? 'Makes an encrypted file you keep. Only your recovery code opens it.'
                        : 'Make your recovery code first (it asks when you add your first person).',
                  ),
                  trailing: recoverySet ? const Icon(Icons.chevron_right) : null,
                  onTap: recoverySet ? () => runBackup(context, ref) : null,
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  title: const Text('Where backups go', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(
                    [
                      if (ref.watch(driveStatusProvider).valueOrNull?.$1 != null) 'Google Drive',
                      if (folder != null) 'A folder',
                    ].join(' and ').isEmpty
                        ? 'Google Drive, a folder, or the share sheet'
                        : [
                            if (ref.watch(driveStatusProvider).valueOrNull?.$1 != null) 'Google Drive',
                            if (folder != null) 'A folder',
                          ].join(' and '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StorageChoiceScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  title: const Text('Restore from a backup', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Replaces what is on this phone.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RestoreVaultScreen(replacing: true)),
                  ),
                ),
              ],
            ),
          ),
          const SectionLabel('Language'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              title: Text(tr(context, 'Language'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Set on this phone only.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
              ),
            ),
          ),
          const SectionLabel('Help'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              title: const Text('Send a problem report', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('See what crashed, then choose whether to send it.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showProblemReport(context),
            ),
          ),
          const SectionLabel('Home'),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              title: const Text('Daily tip', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text(
                'One short line above the tab bar. Same for everyone, never a notification.',
              ),
              value: !tipsHidden,
              onChanged: (show) async {
                await ref.read(onboardingStoreProvider).setTipsHidden(!show);
                ref.invalidate(tipsHiddenProvider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _check(BuildContext context, WidgetRef ref) async {
    final record = await ref.read(onboardingStoreProvider).readRecovery();
    if (record == null || !context.mounted) return;
    final input = TextEditingController();
    String? result;
    bool checking = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Check your recovery code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type the code from your copy. It is checked on this phone '
                'and never stored or sent.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: input,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX'),
              ),
              if (result != null) ...[
                const SizedBox(height: 12),
                Text(result!, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: checking
                  ? null
                  : () async {
                      final code = RecoveryCode.parse(input.text);
                      if (code == null) {
                        setState(() => result = 'That is not 24 characters of a code.');
                        return;
                      }
                      setState(() => checking = true);
                      final ok = await record.matches(code);
                      setState(() {
                        checking = false;
                        result = ok
                            ? 'That matches your recovery code.'
                            : 'That does not match.';
                      });
                    },
              child: Text(checking ? 'Checking…' : 'Check'),
            ),
          ],
        ),
      ),
    );
    input.dispose();
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: onboardAmber, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
