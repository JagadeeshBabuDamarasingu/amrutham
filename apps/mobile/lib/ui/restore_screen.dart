import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/vault_backup.dart';
import '../crypto/recovery_code.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

/// Restore an encrypted backup file with the recovery code. For a new phone or
/// a reinstall. If this phone already has records, they are replaced.
class RestoreVaultScreen extends ConsumerStatefulWidget {
  const RestoreVaultScreen({super.key, this.replacing = false});

  /// True when opened from Settings on a phone that already has records.
  final bool replacing;

  @override
  ConsumerState<RestoreVaultScreen> createState() => _RestoreState();
}

enum _Step { reading, decrypting, rebuilding, reminders, done }

class _RestoreState extends ConsumerState<RestoreVaultScreen> {
  final _code = TextEditingController();
  PlatformFile? _file;
  _Step? _step; // null = the form
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  RecoveryCode? get _parsed => RecoveryCode.parse(_code.text);

  Future<void> _pick() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isNotEmpty) setState(() => _file = picked.first);
  }

  Future<void> _go() async {
    final code = _parsed!;
    final path = _file!.path;
    if (path == null) return;
    setState(() {
      _error = null;
      _step = _Step.reading;
    });
    try {
      final bytes = await File(path).readAsBytes();
      setState(() => _step = _Step.decrypting);
      final data = await VaultBackup.decrypt(bytes, code);

      setState(() => _step = _Step.rebuilding);
      final realm = await ref.read(databaseProvider.future);
      final vault = await ref.read(vaultDirectoryProvider.future);
      final people = await VaultBackup.restore(realm, vault, data);

      // This phone now holds the same code: remember how to check it.
      final store = ref.read(onboardingStoreProvider);
      await store.saveRecovery(await RecoveryRecord.create(code));
      await store.markWelcomeSeen();

      setState(() => _step = _Step.reminders);
      final reminders = await ref.read(reminderRepositoryProvider.future);
      for (final id in people) {
        await reminders.armRemindersForPerson(PersonId(id));
      }

      ref
        ..invalidate(recoverySetProvider)
        ..invalidate(welcomeSeenProvider);
      setState(() => _step = _Step.done);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on BackupException catch (e) {
      setState(() {
        _error = e.message;
        _step = null;
      });
    } catch (e) {
      setState(() {
        _error = "Couldn't restore from that file. Nothing was changed if the code was wrong.";
        _step = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    if (step != null) return _Progress(step: step);

    final ready = _file != null && _parsed != null;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const Text(
            'Restore your vault',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'For a new phone, or after reinstalling. You need your backup file and your recovery code.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
          if (widget.replacing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFAEFD0), borderRadius: BorderRadius.circular(16)),
              child: const Text(
                'This phone already has records. Restoring replaces them with the backup.',
                style: TextStyle(color: Color(0xFF5A4300)),
              ),
            ),
          ],
          const SectionLabel('Backup file'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(_file?.name ?? 'Choose the backup file'),
              subtitle: const Text('A .amrutham file from Drive, Files or your computer'),
              onTap: _pick,
            ),
          ),
          const SectionLabel('Recovery code'),
          TextField(
            controller: _code,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 18, letterSpacing: 1),
            decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Checked on this phone only. There is no lockout server and no way for us to reset it.',
            style: TextStyle(fontSize: 13, color: onboardMuted, height: 1.4),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF9B3B2A), fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 28),
          OnboardButton(label: 'Restore my vault', onPressed: ready ? _go : null),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    const labels = [
      (_Step.reading, 'Reading the backup'),
      (_Step.decrypting, 'Checking your code and decrypting'),
      (_Step.rebuilding, 'Rebuilding your records'),
      (_Step.reminders, 'Setting up reminders'),
    ];
    final done = step.index;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: done / 4,
                    strokeWidth: 10,
                    color: onboardInk,
                    backgroundColor: const Color(0xFFD5E4DC),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Restoring your vault',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep the app open. This can take a few minutes.',
                  style: TextStyle(color: onboardMuted),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      for (final (s, label) in labels)
                        ListTile(
                          leading: s.index < done
                              ? const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Color(0xFFD5E4DC),
                                  child: Icon(Icons.check, size: 16, color: onboardInk),
                                )
                              : s.index == done
                              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3))
                              : const CircleAvatar(radius: 14, backgroundColor: Color(0xFFECEFED)),
                          title: Text(
                            label,
                            style: TextStyle(color: s.index > done ? onboardMuted : null),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
