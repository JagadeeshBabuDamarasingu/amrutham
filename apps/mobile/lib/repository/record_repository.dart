import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/health_record.dart';
import '../model/ids.dart';

/// Files a document as plain files under `<vault>/<personId>/`, and remembers
/// it in the DB. The folder stays readable without the app.
class RecordRepository {
  final Realm _realm;
  final Directory vaultDir;

  RecordRepository(this._realm, this.vaultDir);

  Stream<List<HealthRecord>> watchAll() {
    return _realm
        .query<RecordRow>('TRUEPREDICATE SORT(recordDate DESC, addedAt DESC)')
        .changes
        .map((c) => c.results.map(_fromRow).toList());
  }

  File fileFor(String relativePath) => File(p.join(vaultDir.path, relativePath));

  Future<HealthRecord> add({
    required PersonId personId,
    required RecordType type,
    required String title,
    required DateTime recordDate,
    String? source,
    required List<File> sources,
  }) async {
    final id = RecordId(Ulid().toString());
    final date =
        '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final dir = Directory(p.join(vaultDir.path, personId.value));
    await dir.create(recursive: true);

    final saved = <String>[];
    for (var i = 0; i < sources.length; i++) {
      final ext = p.extension(sources[i].path).toLowerCase();
      // Name carries the date and title so the folder is browsable by hand;
      // the id suffix keeps two records with the same title apart.
      final name =
          '$date-${slug.isEmpty ? 'record' : slug}-${id.value.substring(id.value.length - 6)}'
          '${sources.length > 1 ? '-${i + 1}' : ''}$ext';
      await sources[i].copy(p.join(dir.path, name));
      saved.add(p.join(personId.value, name));
    }

    _realm.write(() {
      _realm.add(
        RecordRow(
          id.value,
          personId.value,
          type.name,
          title,
          recordDate,
          DateTime.now(),
          source: source,
          files: saved,
        ),
      );
    });
    return _fromRow(_realm.find<RecordRow>(id.value)!);
  }

  /// Changes the details shown in the app. The files keep their names, so the
  /// vault folder stays as it was.
  Future<void> update(
    RecordId id, {
    required RecordType type,
    required String title,
    required DateTime recordDate,
    String? source,
  }) async {
    final row = _realm.find<RecordRow>(id.value);
    if (row == null) return;
    _realm.write(() {
      row
        ..type = type.name
        ..title = title
        ..recordDate = recordDate
        ..source = source;
    });
  }

  Future<void> delete(RecordId id) async {
    final row = _realm.find<RecordRow>(id.value);
    if (row == null) return;
    for (final f in row.files) {
      final file = fileFor(f);
      if (await file.exists()) await file.delete();
    }
    _realm.write(() => _realm.delete(row));
  }

  HealthRecord _fromRow(RecordRow row) => HealthRecord(
    id: RecordId(row.id),
    personId: PersonId(row.personId),
    type: RecordType.values.byName(row.type),
    title: row.title,
    recordDate: row.recordDate.toLocal(),
    source: row.source,
    files: row.files.toList(),
    addedAt: row.addedAt.toLocal(),
  );
}
