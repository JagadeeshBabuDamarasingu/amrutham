import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup/backup_folder.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_service.dart';
import '../sync/sync_settings.dart';
import 'app_style.dart';
import 'backup_recovery_screen.dart' show ago;

final syncSettingsProvider = FutureProvider<SyncSettings>(
  (ref) => SyncSettings.load(ref.watch(onboardingStoreProvider)),
);

/// Runs one round and re-arms the alarms of anyone whose medicines changed.
Future<SyncResult> runFamilySync(WidgetRef ref) async {
  final store = ref.read(onboardingStoreProvider);
  final s = await SyncSettings.load(store);
  final support = await getApplicationSupportDirectory();
  final result = await SyncService(
    realm: await ref.read(databaseProvider.future),
    stateFile: File(p.join(support.path, 'family_sync.json')),
    store: SharedFolderStore(s.folder!),
    familyKey: s.key!,
  ).run();
  if (result.people.isNotEmpty) {
    await (await ref.read(
      reminderRepositoryProvider.future,
    )).rearm([for (final id in result.people) PersonId(id)]);
  }
  await SyncSettings.saveLast(store, DateTime.now());
  ref.invalidate(syncSettingsProvider);
  return result;
}

/// Frames 20a and 20b: set up family sync and see how it is going.
class FamilySyncScreen extends ConsumerStatefulWidget {
  const FamilySyncScreen({super.key});

  @override
  ConsumerState<FamilySyncScreen> createState() => _FamilySyncScreenState();
}

class _FamilySyncScreenState extends ConsumerState<FamilySyncScreen> {
  String? _message;
  bool _busy = false;

  Future<void> _guard(Future<String?> Function() job) async {
    setState(() => _busy = true);
    try {
      _message = await job();
    } catch (e) {
      _message = "That didn't work: $e";
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickFolder() async {
    final folder = await pickBackupFolder();
    if (folder == null) return;
    await SyncSettings.saveFolder(ref.read(onboardingStoreProvider), folder);
    ref.invalidate(syncSettingsProvider);
  }

  Future<void> _start() async {
    await SyncSettings.saveKey(
      ref.read(onboardingStoreProvider),
      SyncEngine.newFamilyKey(),
    );
    ref.invalidate(syncSettingsProvider);
  }

  Future<void> _join() async {
    final controller = TextEditingController();
    final key = await showDialog<List<int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join a family'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Paste the family code'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final k = keyFromFamilyCode(controller.text);
              if (k == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "That isn't a family code. It starts with amr1.",
                    ),
                  ),
                );
              } else {
                Navigator.pop(context, k);
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
    if (key == null) return;
    await SyncSettings.saveKey(ref.read(onboardingStoreProvider), key);
    ref.invalidate(syncSettingsProvider);
  }

  Future<void> _leave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop syncing?'),
        content: const Text(
          'This phone keeps everything it has. It stops sending and reading changes. '
          'Other phones are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep syncing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final store = ref.read(onboardingStoreProvider);
    await SyncSettings.saveKey(store, null);
    await SyncSettings.saveFolder(store, null);
    ref.invalidate(syncSettingsProvider);
  }

  String _summary(SyncResult r) {
    final parts = [
      if (r.sent > 0) 'sent ${r.sent}',
      if (r.received > 0) 'received ${r.received}',
    ];
    return [
      parts.isEmpty
          ? 'Up to date.'
          : 'Done: ${parts.join(', ')} change${r.sent + r.received == 1 ? '' : 's'}.',
      if (r.conflicts.isNotEmpty)
        '${r.conflicts.length} medicine${r.conflicts.length == 1 ? ' was' : 's were'} changed on two phones at once. '
            'The newer change is showing; check the schedule with your family.',
      if (r.unreadable > 0)
        '${r.unreadable} file${r.unreadable == 1 ? '' : 's'} could not be read.',
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final s =
        ref.watch(syncSettingsProvider).valueOrNull ?? const SyncSettings();
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Family devices',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Keep this family's medicines and records the same on every phone. "
            'Changes travel in a folder you choose, locked with a family code. Nothing goes to Amrutham.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
          if (s.key == null) ...[
            const SectionLabel('Set up'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Start a family',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Make a family code, then share it with the others.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _start,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text(
                      'Join a family',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text('Enter the code from another phone.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _join,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SectionLabel('Family code'),
            Card(
              child: ListTile(
                title: const Text(
                  'Share with family',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Anyone with this code and the folder can read your records. Send it only to people you trust.',
                ),
                trailing: const Icon(Icons.ios_share),
                onTap: () =>
                    SharePlus.instance.share(ShareParams(text: 'Amrutham family code: ${familyCode(s.key!)}')),
                onLongPress: () =>
                    Clipboard.setData(ClipboardData(text: familyCode(s.key!))),
              ),
            ),
            const SectionLabel('Shared folder'),
            Card(
              child: ListTile(
                title: Text(
                  s.folder == null
                      ? 'Choose a folder'
                      : backupFolderLabel(s.folder!),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Pick a folder every phone can reach, such as one kept in sync by Google Drive or Syncthing.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickFolder,
              ),
            ),
            const SectionLabel('Sync'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Sync now',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      s.last == null
                          ? 'Not synced yet'
                          : 'Last synced ${ago(s.last)}',
                    ),
                    trailing: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    onTap: !s.ready || _busy
                        ? null
                        : () => _guard(
                            () async => _summary(await runFamilySync(ref)),
                          ),
                  ),
                  if (_message != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _message!,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _leave,
              child: const Text('Stop syncing on this phone'),
            ),
          ],
        ],
      ),
    );
  }
}
