import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;

import 'sync_journal.dart';

/// Where shards live. A synced folder today; a family member's phone over
/// Tailscale tomorrow (same three calls over HTTP). The store only ever sees
/// opaque names and encrypted bytes.
abstract class BlobStore {
  Future<List<String>> list();
  Future<List<int>> read(String name);
  Future<void> write(String name, List<int> bytes);
}

class FolderBlobStore implements BlobStore {
  FolderBlobStore(this.dir);
  final Directory dir;

  @override
  Future<List<String>> list() async => await dir.exists()
      ? [
          await for (final f in dir.list())
            if (f is File && f.path.endsWith(_ext)) p.basename(f.path),
        ]
      : [];

  @override
  Future<List<int>> read(String name) => File(p.join(dir.path, p.basename(name))).readAsBytes();

  @override
  Future<void> write(String name, List<int> bytes) async {
    await dir.create(recursive: true);
    // Write then rename, so a half-copied file is never mistaken for a shard.
    final tmp = File(p.join(dir.path, '.${p.basename(name)}.part'));
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(p.join(dir.path, p.basename(name)));
  }
}

const _ext = '.amrsync';
const _magic = 'AMRSY1';

class SyncException implements Exception {
  SyncException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Writes and reads this family's shards. Every phone writes only its own
/// files (`<device>-<counter>`), so two phones can never overwrite each other;
/// reading is "all files, merged".
class SyncEngine {
  SyncEngine({required this.store, required List<int> familyKey, required this.device})
      : _key = SecretKey(familyKey);

  final BlobStore store;
  final String device;
  final SecretKey _key;

  /// A short random name for a phone. Not the phone's own name: the shared
  /// folder never learns it.
  static String newDeviceId() {
    final r = Random.secure();
    return List.generate(8, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  /// A fresh 256-bit key for a new family; shown to other phones as a QR code.
  static List<int> newFamilyKey() {
    final r = Random.secure();
    return List<int>.generate(32, (_) => r.nextInt(256));
  }

  static final _algo = AesGcm.with256bits();

  Future<List<int>> _seal(Object json) async {
    final box = await _algo.encrypt(utf8.encode(jsonEncode(json)), secretKey: _key);
    return [...utf8.encode(_magic), ...box.concatenation()];
  }

  Future<Map<String, dynamic>> _open(List<int> bytes) async {
    final head = utf8.encode(_magic).length;
    if (bytes.length < head + 12 + 16 ||
        utf8.decode(bytes.sublist(0, head), allowMalformed: true) != _magic) {
      throw SyncException("That file isn't from Amrutham family sync.");
    }
    try {
      final plain = await _algo.decrypt(
        SecretBox.fromConcatenation(bytes.sublist(head), nonceLength: 12, macLength: 16),
        secretKey: _key,
      );
      return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
    } on SecretBoxAuthenticationError {
      throw SyncException("This family's key doesn't open that file.");
    }
  }

  /// Writes [changes] as this phone's next shard. Does nothing if empty.
  Future<void> push(List<Change> changes) async {
    if (changes.isEmpty) return;
    var last = 0;
    for (final n in await store.list()) {
      if (n.startsWith('$device-')) {
        last = max(last, int.tryParse(n.substring(device.length + 1, n.length - _ext.length)) ?? 0);
      }
    }
    final name = '$device-${(last + 1).toString().padLeft(6, '0')}$_ext';
    await store.write(name, await _seal({'changes': [for (final c in changes) c.toJson()]}));
  }

  /// Every change in shards not in [read]. Shards that are damaged or sealed
  /// with another family's key are skipped and named in [bad].
  Future<({List<Change> changes, Set<String> read, List<String> bad})> pull(Set<String> read) async {
    final changes = <Change>[];
    final names = <String>{};
    final bad = <String>[];
    for (final n in await store.list()) {
      if (read.contains(n)) continue;
      try {
        final j = await _open(await store.read(n));
        changes.addAll((j['changes'] as List).cast<Map<String, dynamic>>().map(Change.fromJson));
        names.add(n);
      } on SyncException {
        bad.add(n);
      }
    }
    return (changes: changes, read: {...read, ...names}, bad: bad);
  }
}
