import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backup/backup_flow.dart';
import '../backup/backup_folder.dart';
import '../backup/drive_backup.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show dateLabel;
import 'restore_screen.dart';

const _fine = TextStyle(color: onboardMuted, height: 1.4);

/// "Where records sync": where encrypted backups are kept.
class StorageChoiceScreen extends ConsumerWidget {
  const StorageChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drive = ref.watch(driveStatusProvider).valueOrNull?.$1;
    final folder = ref.watch(backupFolderProvider).valueOrNull;
    Widget option(IconData icon, String title, String sub, VoidCallback? onTap, {VoidCallback? onLongPress}) =>
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFE3ECE7),
              child: Icon(icon, color: onboardInk),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(sub),
            trailing: onTap == null ? null : const Icon(Icons.chevron_right),
            enabled: onTap != null,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Where records sync',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pick where the encrypted copy goes. Amrutham has no server of its own.',
            style: _fine,
          ),
          const SizedBox(height: 16),
          option(
            Icons.cloud_outlined,
            'Google Drive',
            drive ?? 'Your own Drive, in a folder only Amrutham can see',
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DriveScreen())),
          ),
          option(
            Icons.folder_outlined,
            'A folder on this phone',
            folder == null
                ? 'Works with any app that syncs a folder'
                : '${backupFolderLabel(folder)}\nTap to change. Hold to stop using it.',
            () async {
              final path = await pickBackupFolder();
              if (path == null) return;
              await ref.read(onboardingStoreProvider).setBackupFolder(path);
              ref.invalidate(backupFolderProvider);
            },
            onLongPress: folder == null
                ? null
                : () async {
                    await ref.read(onboardingStoreProvider).setBackupFolder(null);
                    ref.invalidate(backupFolderProvider);
                  },
          ),
          option(Icons.shield_outlined, 'Tailscale', 'Phone to phone. Not built yet.', null),
          const SectionLabel('Not yet'),
          option(Icons.cloud_queue, 'OneDrive, Dropbox', 'Planned after Drive is solid', null),
          const SizedBox(height: 8),
          const Text(
            'Whatever you pick, records are encrypted on this phone first. The '
            'storage provider only ever holds scrambled files. You choose when to '
            'back up: Amrutham keeps only a check of your recovery code, not the '
            'code, so it cannot encrypt in the background.',
            style: _fine,
          ),
        ],
      ),
    );
  }
}

/// Connect Google Drive, or manage the connection.
class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key});

  @override
  ConsumerState<DriveScreen> createState() => _DriveState();
}

class _DriveState extends ConsumerState<DriveScreen> {
  bool _busy = false;
  String? _error;
  int? _size;

  @override
  void initState() {
    super.initState();
    _loadSize();
  }

  Future<void> _loadSize() async {
    if (ref.read(driveStatusProvider).valueOrNull?.$1 == null) return;
    try {
      final size = await DriveSession.instance.size();
      if (mounted) setState(() => _size = size);
    } catch (_) {}
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = await DriveSession.instance.connect();
      await ref.read(onboardingStoreProvider).putSetting(driveEmailKey, email);
      ref.invalidate(driveStatusProvider);
    } catch (e) {
      debugPrint('Drive connect failed: $e');
      _error = "Couldn't connect to Google. Check your connection and try again.";
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _disconnect() async {
    final store = ref.read(onboardingStoreProvider);
    await DriveSession.instance.disconnect();
    await store.putSetting(driveEmailKey, null);
    await store.putSetting(driveLastBackupKey, null);
    ref.invalidate(driveStatusProvider);
    if (mounted) setState(() => _size = null);
  }

  @override
  Widget build(BuildContext context) {
    final (email, last) = ref.watch(driveStatusProvider).valueOrNull ?? (null, null);
    return email == null ? _connectView() : _connectedView(email, last);
  }

  Widget _connectView() {
    Widget point(IconData icon, bool good, String title, String sub) => ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: good ? const Color(0xFFD5E4DC) : const Color(0xFFFAEFD0),
        child: Icon(icon, size: 16, color: onboardInk),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Connect Google Drive',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text('Sign in with the Google account you want to hold the encrypted copy.', style: _fine),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                point(Icons.check, true, 'One folder only',
                    'Amrutham can see only the folder it creates, never the rest of your Drive.'),
                point(Icons.check, true, 'Encrypted before upload',
                    'Google stores scrambled files. The key is your recovery code.'),
                point(Icons.priority_high, false, 'What Google can still see',
                    'That the folder exists, file sizes and when they change. Not what is inside.'),
                point(Icons.priority_high, false, 'Needs internet access',
                    'Only used when you back up or restore.'),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 20),
          OnboardButton(label: _busy ? 'Connecting…' : 'Continue with Google', onPressed: _busy ? null : _connect),
          const SizedBox(height: 10),
          const Text(
            'You can disconnect any time. Files already in Drive stay until you delete them.',
            style: _fine,
          ),
        ],
      ),
    );
  }

  Widget _connectedView(String email, DateTime? last) {
    Widget row(String l, String v) => ListTile(
      title: Text(l),
      trailing: Text(v, style: const TextStyle(color: onboardMuted)),
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Google Drive',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connected', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                Text(email, style: const TextStyle(color: Color(0xFFB8D0C5))),
                const SizedBox(height: 14),
                Text(
                  last == null ? 'No backup yet' : 'Last backup ${dateLabel(last)}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SectionLabel('Folder'),
          Card(
            child: Column(
              children: [
                row('Name', 'Hidden app folder'),
                row('Backup size', _size == null ? '—' : '${(_size! / 1048576).toStringAsFixed(1)} MB'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OnboardButton(
            label: 'Back up now',
            onPressed: () async {
              await runBackup(context, ref);
              _loadSize();
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RestoreVaultScreen(
                  replacing: true,
                  source: DriveSession.instance.download,
                  sourceLabel: 'Backup in $email',
                ),
              ),
            ),
            child: const Text('Restore from Drive'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFF9B3B2A),
            ),
            onPressed: _disconnect,
            child: const Text('Disconnect Google Drive'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Disconnecting stops backups to Drive. The file already there stays until you remove it from your Drive settings.',
            style: _fine,
          ),
        ],
      ),
    );
  }
}
