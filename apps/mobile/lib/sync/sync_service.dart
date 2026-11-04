import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:realm/realm.dart';

import '../backup/vault_backup.dart';
import '../db/realm_schemas.dart';
import 'row_codec.dart';
import 'sync_engine.dart';
import 'sync_journal.dart';

const _channel = MethodChannel('app.amrutham/folder');

/// A shared folder that is either a plain path or an Android `content://` tree.
class SharedFolderStore implements BlobStore {
  SharedFolderStore(this.folder)
    : _plain = folder.startsWith('content://')
          ? null
          : FolderBlobStore(Directory(folder));

  final String folder;
  final FolderBlobStore? _plain;

  @override
  Future<List<String>> list() async => _plain != null
      ? _plain.list()
      : [
          for (final n
              in (await _channel.invokeListMethod<String>('list', {
                    'tree': folder,
                  })) ??
                  <String>[])
            if (n.endsWith('.amrsync')) n,
        ];

  @override
  Future<List<int>> read(String name) async => _plain != null
      ? _plain.read(name)
      : (await _channel.invokeMethod<Uint8List>('read', {
          'tree': folder,
          'name': name,
        }))!;

  @override
  Future<void> write(String name, List<int> bytes) async => _plain != null
      ? _plain.write(name, bytes)
      : _channel.invokeMethod<bool>('write', {
          'tree': folder,
          'name': name,
          'bytes': Uint8List.fromList(bytes),
        });
}

/// What one sync did, for the screen.
class SyncResult {
  const SyncResult({
    required this.sent,
    required this.received,
    required this.conflicts,
    required this.unreadable,
    required this.people,
  });
  final int sent;
  final int received;
  final List<SyncConflict> conflicts;
  final int unreadable;

  /// People whose rows changed, so their alarms can be re-armed.
  final Set<String> people;
}

/// One round of family sync for this phone: send my changes, read everyone's,
/// merge, write the result into the database. What this phone knew last time
/// is kept in [stateFile], so the next round only sends what changed since.
class SyncService {
  SyncService({
    required this.realm,
    required this.stateFile,
    required this.store,
    required this.familyKey,
  });

  final Realm realm;
  final File stateFile;
  final BlobStore store;
  final List<int> familyKey;

  // ponytail: `applied` grows by one entry per change forever; compact it
  // (drop entries older than every phone's last shard) when it gets large.
  Future<
    ({SyncState state, Rows synced, Set<String> read, String device, int last})
  >
  _load() async {
    if (!await stateFile.exists()) {
      return (
        state: SyncState(),
        synced: {
          for (final t in syncTables) t: <String, Map<String, dynamic>>{},
        },
        read: <String>{},
        device: SyncEngine.newDeviceId(),
        last: 0,
      );
    }
    final j =
        jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;
    Rows rows(Object? m) => {
      for (final t in syncTables)
        t: {
          for (final e in ((m as Map)[t] as Map? ?? {}).entries)
            e.key as String: (e.value as Map).cast<String, dynamic>(),
        },
    };
    return (
      state: SyncState(
        rows: rows(j['held']),
        versions: (j['versions'] as Map).cast<String, String>(),
        applied: (j['applied'] as List).cast<String>().toSet(),
      ),
      synced: rows(j['synced']),
      read: (j['read'] as List).cast<String>().toSet(),
      device: j['device'] as String,
      last: j['last'] as int,
    );
  }

  Future<void> _save(
    SyncState s,
    Rows synced,
    Set<String> read,
    String device,
    int last,
  ) async {
    await stateFile.parent.create(recursive: true);
    final tmp = File('${stateFile.path}.part');
    await tmp.writeAsString(
      jsonEncode({
        'device': device,
        'last': last,
        'held': s.rows,
        'synced': synced,
        'versions': s.versions,
        'applied': s.applied.toList(),
        'read': read.toList(),
      }),
      flush: true,
    );
    await tmp.rename(stateFile.path);
  }

  Future<SyncResult> run({int Function()? now}) async {
    final loaded = await _load();
    final state = loaded.state;
    final stamper = Stamper(loaded.device, now: now, last: loaded.last);
    final engine = SyncEngine(
      store: store,
      familyKey: familyKey,
      device: loaded.device,
    );

    // What I did since last time.
    final mine = rowsOf(
      jsonDecode(jsonEncode(VaultBackup.tableRows(realm)))
          as Map<String, dynamic>,
    );
    final own = diffRows(loaded.synced, mine, state.versions, stamper);
    await engine.push(own);
    state.merge(own);

    // What everyone else did.
    final got = await engine.pull(loaded.read);
    for (final c in got.changes) {
      stamper.seen(c.at);
    }
    final conflicts = state.merge(got.changes);

    // Write the agreed rows into the database.
    final people = <String>{};
    realm.write(() {
      for (final t in syncTables) {
        final want = state.rows[t] ?? {};
        final have = mine[t] ?? {};
        for (final e in want.entries) {
          if (have[e.key] != null &&
              jsonEncode(have[e.key]) == jsonEncode(e.value)) {
            continue;
          }
          realm.add(rowFromJson(t, e.value), update: true);
          _noteOwner(people, t, e.value);
        }
        for (final id in have.keys) {
          if (want.containsKey(id)) continue;
          deleteRowById(realm, t, id);
          _noteOwner(people, t, have[id]!);
        }
      }
    });

    final synced = {
      for (final t in syncTables) t: {...?state.rows[t]},
    };
    await _save(state, synced, got.read, loaded.device, stamper.last);
    return SyncResult(
      sent: own.length,
      received: got.changes.length,
      conflicts: conflicts,
      unreadable: got.bad.length,
      people: people,
    );
  }

  /// Which person's alarms a changed row can affect. Phases belong to a
  /// course, which the caller looks up; here only direct links are noted.
  void _noteOwner(Set<String> people, String table, Map<String, dynamic> row) {
    final pid = table == 'people' ? row['id'] : row['personId'];
    if (pid is String) people.add(pid);
    if (table == 'phases') {
      final c = realm.find<MedicationCourseRow>(row['courseId'] as String);
      if (c != null) people.add(c.personId);
    }
  }
}
