import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/auto_backup.dart';
import '../backup/auto_backup_scheduler.dart';
import '../crypto/recovery_code.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show dateLabel;
import 'recovery_code_dialog.dart';

/// "Automatic backups" for Google Drive and the chosen folder. Turning it on
/// asks for the recovery code once and keeps a key made from it, so scheduled
/// backups can encrypt without the code. Backing up by hand still asks.
class AutoBackupScreen extends ConsumerStatefulWidget {
  const AutoBackupScreen({super.key});

  @override
  ConsumerState<AutoBackupScreen> createState() => _AutoBackupScreenState();
}

class _AutoBackupScreenState extends ConsumerState<AutoBackupScreen> {
  bool _busy = false;

  Future<void> _changed() async {
    ref.invalidate(autoBackupSettingsProvider);
    await AutoBackupScheduler.sync(ref.read(onboardingStoreProvider));
  }

  Future<void> _turnOn() async {
    final store = ref.read(onboardingStoreProvider);
    final record = await store.readRecovery();
    if (record == null || !mounted) return;
    final code = await showDialog<RecoveryCode>(
      context: context,
      builder: (_) => RecoveryCodeDialog(
        verify: record.matches,
        title: 'Turn on automatic backups',
        intro: 'Type your recovery code once. A key made from it is kept in this '
            "phone's secure storage so backups can run without you. The code "
            'itself is not stored.',
        actionLabel: 'Turn on',
      ),
    );
    if (code == null || !mounted) return;
    setState(() => _busy = true);
    await enableAutoBackup(store, code);
    await _changed();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _turnOff() async {
    final store = ref.read(onboardingStoreProvider);
    await disableAutoBackup(store);
    await _changed();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(autoBackupSettingsProvider).valueOrNull;
    final hasRecovery = ref.watch(recoverySetProvider).valueOrNull ?? false;
    final store = ref.read(onboardingStoreProvider);
    final driveEmail = ref.watch(driveStatusProvider).valueOrNull?.$1;
    final folder = ref.watch(backupFolderProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Automatic backups',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Backs up by itself, so a lost phone does not mean lost records. '
            'Every copy is encrypted on this phone first.',
            style: TextStyle(color: onboardMuted),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              title: const Text('Back up automatically', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                hasRecovery
                    ? "Needs your recovery code once. Restoring on another phone still needs it."
                    : 'Make your recovery code first. It is asked when you add your first person.',
              ),
              value: s?.enabled ?? false,
              onChanged: s == null || !hasRecovery || _busy
                  ? null
                  : (on) => on ? _turnOn() : _turnOff(),
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (s != null && s.enabled) ...[
            const SectionLabel('How often'),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 1, label: Text('Every day')),
                ButtonSegment(value: 7, label: Text('Every week')),
              ],
              selected: {s.everyDays == 7 ? 7 : 1},
              onSelectionChanged: (v) async {
                await setAutoBackupDays(store, v.first);
                await _changed();
              },
            ),
            const SectionLabel('Where to'),
            Card(
              child: Column(
                children: [
                  _Destination(
                    title: 'Google Drive',
                    available: s.driveConnected,
                    unavailable: 'Connect Google Drive in "Where backups go" first.',
                    detail: driveEmail,
                    on: s.drive,
                    last: s.driveLast,
                    error: s.driveError,
                    onChanged: (v) async {
                      await setAutoBackupDestination(store, drive: v);
                      await _changed();
                    },
                  ),
                  const Divider(height: 1),
                  _Destination(
                    title: 'A folder on this phone',
                    available: s.folderChosen,
                    unavailable: 'Choose a folder in "Where backups go" first.',
                    detail: folder,
                    on: s.folder,
                    last: s.folderLast,
                    error: s.folderError,
                    onChanged: (v) async {
                      await setAutoBackupDestination(store, folder: v);
                      await _changed();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Android decides exactly when background work runs, usually once or '
              'twice a day, and may hold it back when the battery is low. A backup '
              'that is overdue also runs when you open Amrutham. If Google Drive '
              "can't sign in without the app open, it waits until you open it.",
              style: TextStyle(color: onboardMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Backing up by hand always asks for your recovery code. The key kept '
            'for automatic backups is deleted when you turn this off.',
            style: TextStyle(color: onboardMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Destination extends StatelessWidget {
  const _Destination({
    required this.title,
    required this.available,
    required this.unavailable,
    required this.on,
    required this.onChanged,
    this.detail,
    this.last,
    this.error,
  });

  final String title;
  final bool available;
  final String unavailable;
  final String? detail;
  final bool on;
  final DateTime? last;
  final String? error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (!available) unavailable else ?detail,
      if (available && last != null) 'Last backup: ${dateLabel(last!)}, ${_time(last!)}',
      if (available && last == null) 'No automatic backup yet',
    ];
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lines.join('\n')),
          if (available && error != null)
            Text(
              "Couldn't back up: $error. It will try again.",
              style: const TextStyle(color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
            ),
        ],
      ),
      value: available && on,
      onChanged: available ? onChanged : null,
    );
  }

  static String _time(DateTime t) => TimeOfDayLite(t.hour, t.minute).label;
}
