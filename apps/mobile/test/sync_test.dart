import 'dart:io';

import 'package:amrutham/sync/sync_engine.dart';
import 'package:amrutham/sync/sync_journal.dart';
import 'package:flutter_test/flutter_test.dart';

Rows rows(Map<String, Map<String, Map<String, dynamic>>> some) =>
    {for (final t in syncTables) t: some[t] ?? {}};

/// One simulated phone: what it holds, what it last synced, its versions.
class Phone {
  Phone(this.id, this.store, this.key, int Function() clock)
      : stamper = Stamper(id, now: clock),
        engine = SyncEngine(store: store, familyKey: key, device: id);
  final String id;
  final BlobStore store;
  final List<int> key;
  final Stamper stamper;
  final SyncEngine engine;
  final state = SyncState();
  var synced = rows({});
  var read = <String>{};
  var conflicts = <SyncConflict>[];

  Rows get now => state.rows;

  Future<void> edit(String table, String id, Map<String, dynamic>? row) async {
    final after = {
      for (final t in syncTables) t: {...state.rows[t]!}
    };
    row == null ? after[table]!.remove(id) : after[table]![id] = row;
    await sync(after);
  }

  /// Push own edits, then read everyone's.
  Future<void> sync([Rows? after]) async {
    final own = diffRows(synced, after ?? state.rows, state.versions, stamper);
    await engine.push(own);
    state.merge(own);
    final got = await engine.pull(read);
    read = got.read;
    for (final c in got.changes) {
      stamper.seen(c.at);
    }
    conflicts.addAll(state.merge(got.changes));
    synced = {for (final t in syncTables) t: {...state.rows[t]!}};
  }
}

void main() {
  late Directory dir;
  late BlobStore store;
  late List<int> key;
  var t = 1000;
  int clock() => t += 10;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('amr_sync');
    store = FolderBlobStore(dir);
    key = SyncEngine.newFamilyKey();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('an edit on one phone shows up on the other, and a delete too', () async {
    final a = Phone('aaaa', store, key, clock), b = Phone('bbbb', store, key, clock);
    await a.edit('people', 'p1', {'id': 'p1', 'displayName': 'Appa'});
    await b.sync();
    expect(b.now['people']!['p1']!['displayName'], 'Appa');
    await b.edit('people', 'p1', {'id': 'p1', 'displayName': 'Appa K'});
    await a.sync();
    expect(a.now['people']!['p1']!['displayName'], 'Appa K');
    await a.edit('people', 'p1', null);
    await b.sync();
    expect(b.now['people']!, isEmpty);
    expect(a.conflicts + b.conflicts, isEmpty);
  });

  test('unguarded rows: the later edit wins on both phones, silently', () async {
    final a = Phone('aaaa', store, key, clock), b = Phone('bbbb', store, key, clock);
    await a.edit('allergies', 'x', {'id': 'x', 'substance': 'dust'});
    await b.sync();
    await a.edit('allergies', 'x', {'id': 'x', 'substance': 'pollen'});
    await b.edit('allergies', 'x', {'id': 'x', 'substance': 'peanut'}); // later
    await a.sync();
    expect(a.now['allergies']!['x']!['substance'], 'peanut');
    expect(b.now['allergies']!['x']!['substance'], 'peanut');
    expect(a.conflicts + b.conflicts, isEmpty);
  });

  test('a schedule edited on both phones without seeing each other is a conflict', () async {
    final a = Phone('aaaa', store, key, clock), b = Phone('bbbb', store, key, clock);
    await a.edit('phases', 's1', {'id': 's1', 'doseAmount': '1 tablet'});
    await b.sync();
    // Both go offline: each edits, neither has read the other's shard.
    final aAfter = {for (final x in syncTables) x: {...a.now[x]!}};
    aAfter['phases']!['s1'] = {'id': 's1', 'doseAmount': '2 tablets'};
    final bAfter = {for (final x in syncTables) x: {...b.now[x]!}};
    bAfter['phases']!['s1'] = {'id': 's1', 'doseAmount': 'half tablet'};
    final ca = diffRows(a.synced, aAfter, a.state.versions, a.stamper);
    final cb = diffRows(b.synced, bAfter, b.state.versions, b.stamper);
    await a.engine.push(ca);
    a.state.merge(ca);
    a.synced = aAfter;
    await b.engine.push(cb);
    b.state.merge(cb);
    b.synced = bAfter;
    await a.sync();
    await b.sync();
    expect(a.conflicts, hasLength(1));
    expect(b.conflicts, hasLength(1));
    expect(b.conflicts.single.table, 'phases');
    expect(
      {b.conflicts.single.kept!['doseAmount'], b.conflicts.single.other!['doseAmount']},
      {'2 tablets', 'half tablet'},
    );
  });

  test('reading the same shards twice changes nothing', () async {
    final a = Phone('aaaa', store, key, clock), b = Phone('bbbb', store, key, clock);
    await a.edit('people', 'p1', {'id': 'p1', 'displayName': 'Amma'});
    await b.sync();
    b.read = {};
    await b.sync();
    expect(b.now['people']!.length, 1);
    expect(b.conflicts, isEmpty);
  });

  test('a phone with a slow clock still sorts after what it has read', () async {
    final a = Phone('aaaa', store, key, () => 5000), b = Phone('bbbb', store, key, () => 100);
    await a.edit('people', 'p1', {'id': 'p1', 'displayName': 'first'});
    await b.sync();
    await b.edit('people', 'p1', {'id': 'p1', 'displayName': 'second'});
    await a.sync();
    expect(a.now['people']!['p1']!['displayName'], 'second');
  });

  test('the wrong family key opens nothing, and files carry no plaintext', () async {
    final a = Phone('aaaa', store, key, clock);
    await a.edit('people', 'p1', {'id': 'p1', 'displayName': 'Appa Kumar'});
    for (final f in dir.listSync().whereType<File>()) {
      expect(String.fromCharCodes(f.readAsBytesSync()).contains('Appa'), isFalse);
    }
    final other = SyncEngine(store: store, familyKey: SyncEngine.newFamilyKey(), device: 'cccc');
    final got = await other.pull({});
    expect(got.changes, isEmpty);
    expect(got.bad, hasLength(1));
  });
}
