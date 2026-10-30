import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/care_provider.dart';
import '../model/ids.dart';

class CareTeamRepository {
  final Realm _realm;

  CareTeamRepository(this._realm);

  /// Everyone on one person's care team, A to Z.
  Stream<List<CareProvider>> watchForPerson(PersonId personId) {
    // Filtered in Dart: it's a short list, and this avoids relying on list
    // containment semantics in the query language.
    return _realm.all<CareProviderRow>().changes.map(
      (c) =>
          c.results
              .where((r) => r.personIds.contains(personId.value))
              .map(_fromRow)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            ),
    );
  }

  /// Everyone saved for the whole family, A to Z.
  Stream<List<CareProvider>> watchAll() {
    return _realm.all<CareProviderRow>().changes.map(
      (c) =>
          c.results.map(_fromRow).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
    );
  }

  Future<CareProvider> add({
    required CareKind kind,
    required String name,
    String? specialty,
    String? worksAt,
    String? phone,
    String? location,
    required List<PersonId> personIds,
    bool isCurrent = true,
  }) async {
    final id = CareProviderId(Ulid().toString());
    _realm.write(() {
      _realm.add(
        CareProviderRow(
          id.value,
          kind.name,
          name,
          isCurrent,
          specialty: specialty,
          worksAt: worksAt,
          phone: phone,
          location: location,
          personIds: personIds.map((p) => p.value),
        ),
      );
    });
    return _fromRow(_realm.find<CareProviderRow>(id.value)!);
  }

  Future<void> setCurrent(CareProviderId id, bool isCurrent) async {
    final row = _realm.find<CareProviderRow>(id.value);
    if (row != null) _realm.write(() => row.isCurrent = isCurrent);
  }

  /// Puts an existing doctor or place on one more person's care team.
  Future<void> linkPerson(CareProviderId id, PersonId personId) async {
    final row = _realm.find<CareProviderRow>(id.value);
    if (row == null || row.personIds.contains(personId.value)) return;
    _realm.write(() => row.personIds.add(personId.value));
  }

  /// Takes one person off. The entry itself goes when nobody is left, so a
  /// doctor shared by three people is not lost when one of them drops out.
  Future<void> unlinkPerson(CareProviderId id, PersonId personId) async {
    final row = _realm.find<CareProviderRow>(id.value);
    if (row == null) return;
    _realm.write(() {
      row.personIds.remove(personId.value);
      if (row.personIds.isEmpty) _realm.delete(row);
    });
  }

  /// Replaces every editable field. Null clears an optional one.
  Future<void> update(
    CareProviderId id, {
    required CareKind kind,
    required String name,
    String? specialty,
    String? worksAt,
    String? phone,
    String? location,
    required List<PersonId> personIds,
    required bool isCurrent,
  }) async {
    final row = _realm.find<CareProviderRow>(id.value);
    if (row == null || personIds.isEmpty) return;
    _realm.write(() {
      row
        ..kind = kind.name
        ..name = name
        ..specialty = specialty
        ..worksAt = worksAt
        ..phone = phone
        ..location = location
        ..isCurrent = isCurrent;
      row.personIds
        ..clear()
        ..addAll(personIds.map((p) => p.value));
    });
  }

  Future<void> delete(CareProviderId id) async {
    final row = _realm.find<CareProviderRow>(id.value);
    if (row != null) _realm.write(() => _realm.delete(row));
  }

  CareProvider _fromRow(CareProviderRow row) => CareProvider(
    id: CareProviderId(row.id),
    kind: CareKind.values.byName(row.kind),
    name: row.name,
    specialty: row.specialty,
    worksAt: row.worksAt,
    phone: row.phone,
    location: row.location,
    personIds: row.personIds.map(PersonId.new).toList(),
    isCurrent: row.isCurrent,
  );
}
