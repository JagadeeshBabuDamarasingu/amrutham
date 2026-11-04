/// Family sync, part 1: what changed, and how two phones agree.
///
/// Each phone turns "what is in my vault now vs. last time" into [Change]s,
/// writes them as an encrypted shard only it ever writes (see sync_engine.dart),
/// and merges everyone's shards the same way, so all phones reach the same state.
/// Pure Dart: no Realm, no files, no network.
library;

/// Tables that sync. Filed documents, receipts and medicine photos are not here
/// yet (they are files, not rows).
// ponytail: files sync later as content-addressed blobs; rows first.
const syncTables = [
  'people',
  'familyHistory',
  'allergies',
  'courses',
  'phases',
  'measurements',
  'history',
  'doseLogs',
  'careTeam',
  'expenses',
];

/// Tables where two phones editing the same row at once must never be settled
/// by "latest wins" (spec phase 2 F7): the app shows both and a person picks.
const guardedTables = {'phases'};

/// A version label: sorts by time, then by phone, so any two phones order the
/// same two edits the same way.
String stampOf(int millis, String device) =>
    '${millis.toString().padLeft(15, '0')}-$device';

/// Hands out ever-increasing stamps for one phone. After reading other phones'
/// changes call [seen], so a phone with a slow clock still stamps after them.
class Stamper {
  Stamper(this.device, {int Function()? now, int last = 0})
    : _now = now ?? (() => DateTime.now().millisecondsSinceEpoch),
      _last = last;

  final String device;
  final int Function() _now;
  int _last;

  int get last => _last;

  String next() {
    final t = _now();
    _last = t > _last ? t : _last + 1;
    return stampOf(_last, device);
  }

  void seen(String stamp) {
    final ms = int.tryParse(stamp.split('-').first) ?? 0;
    if (ms > _last) _last = ms;
  }
}

/// One row created, edited (`fields` set) or deleted (`fields` null).
/// `base` is the version this edit was made on top of: two edits with the same
/// base but different stamps happened without either phone having seen the other.
class Change {
  const Change({
    required this.table,
    required this.id,
    required this.at,
    required this.base,
    required this.fields,
  });

  final String table;
  final String id;
  final String at;
  final String? base;
  final Map<String, dynamic>? fields;

  String get key => '$table/$id';

  Map<String, dynamic> toJson() => {
    't': table,
    'id': id,
    'at': at,
    'base': base,
    'f': fields,
  };

  factory Change.fromJson(Map<String, dynamic> j) => Change(
    table: j['t'] as String,
    id: j['id'] as String,
    at: j['at'] as String,
    base: j['base'] as String?,
    fields: (j['f'] as Map?)?.cast<String, dynamic>(),
  );
}

/// table -> id -> row, taken from a backup snapshot ([syncTables] only).
typedef Rows = Map<String, Map<String, Map<String, dynamic>>>;

Rows rowsOf(Map<String, dynamic> snapshot) => {
  for (final t in syncTables)
    t: {
      for (final r
          in ((snapshot[t] as List?) ?? const []).cast<Map<String, dynamic>>())
        r['id'] as String: r,
    },
};

bool _same(Object? a, Object? b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _same(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        [for (var i = 0; i < a.length; i++) _same(a[i], b[i])].every((x) => x);
  }
  return a == b;
}

/// What the owner of this phone did between [before] and [after].
List<Change> diffRows(
  Rows before,
  Rows after,
  Map<String, String> versions,
  Stamper stamper,
) {
  final out = <Change>[];
  for (final t in syncTables) {
    final was = before[t] ?? const {};
    final now = after[t] ?? const {};
    for (final e in now.entries) {
      if (was[e.key] != null && _same(was[e.key], e.value)) continue;
      out.add(
        Change(
          table: t,
          id: e.key,
          at: stamper.next(),
          base: versions['$t/${e.key}'],
          fields: e.value,
        ),
      );
    }
    for (final id in was.keys) {
      if (now.containsKey(id)) continue;
      out.add(
        Change(
          table: t,
          id: id,
          at: stamper.next(),
          base: versions['$t/$id'],
          fields: null,
        ),
      );
    }
  }
  return out;
}

/// Two versions of one guarded row that were edited without seeing each other.
/// `kept` is what the phone now holds; `other` is the version it did not keep.
class SyncConflict {
  const SyncConflict(this.table, this.id, this.kept, this.other);
  final String table;
  final String id;
  final Map<String, dynamic>? kept;
  final Map<String, dynamic>? other;
}

/// The agreed state on one phone: rows, the version each row is at, and which
/// changes have been applied (so reading a shard twice is harmless).
class SyncState {
  SyncState({Rows? rows, Map<String, String>? versions, Set<String>? applied})
    : rows = rows ?? {for (final t in syncTables) t: {}},
      versions = versions ?? {},
      applied = applied ?? {};

  final Rows rows;
  final Map<String, String> versions;
  final Set<String> applied;

  /// Applies [changes] in stamp order. Newest stamp wins a row; for
  /// [guardedTables] a clash is also returned so someone can look at it.
  List<SyncConflict> merge(Iterable<Change> changes) {
    final conflicts = <SyncConflict>[];
    final sorted = changes.toList()..sort((a, b) => a.at.compareTo(b.at));
    for (final c in sorted) {
      final id = '${c.key}@${c.at}';
      if (!applied.add(id)) continue;
      final current = versions[c.key];
      final clash = current != null && c.base != current;
      final rowsOfTable = rows.putIfAbsent(c.table, () => {});
      final held = rowsOfTable[c.id];
      if (current == null || c.at.compareTo(current) > 0) {
        if (clash && guardedTables.contains(c.table)) {
          conflicts.add(SyncConflict(c.table, c.id, c.fields, held));
        }
        if (c.fields == null) {
          rowsOfTable.remove(c.id);
        } else {
          rowsOfTable[c.id] = c.fields!;
        }
        versions[c.key] = c.at;
      } else if (clash && guardedTables.contains(c.table)) {
        conflicts.add(SyncConflict(c.table, c.id, held, c.fields));
      }
    }
    return conflicts;
  }
}
