import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/ids.dart';
import '../model/measurement.dart';

/// Readings for one person, newest first. UI never touches [MeasurementRow].
class MeasurementRepository {
  final Realm _realm;

  MeasurementRepository(this._realm);

  Stream<List<Measurement>> watchMeasurements(PersonId personId) {
    return _realm
        .query<MeasurementRow>(
          'personId == \$0 SORT(measuredAt DESC)',
          [personId.value],
        )
        .changes
        .map((c) => c.results.map(_fromRow).toList());
  }

  Future<Measurement> addMeasurement({
    required PersonId personId,
    required MeasurementKind kind,
    required double value,
    double? value2,
    required DateTime measuredAt,
    String? note,
  }) async {
    final id = MeasurementId(Ulid().toString());
    _realm.write(() {
      _realm.add(
        MeasurementRow(
          id.value,
          personId.value,
          kind.name,
          value,
          measuredAt,
          value2: kind.hasSecondValue ? value2 : null,
          note: note,
        ),
      );
    });
    return Measurement(
      id: id,
      personId: personId,
      kind: kind,
      value: value,
      value2: kind.hasSecondValue ? value2 : null,
      measuredAt: measuredAt,
      note: note,
    );
  }

  Future<void> deleteMeasurement(MeasurementId id) async {
    final row = _realm.find<MeasurementRow>(id.value);
    if (row != null) _realm.write(() => _realm.delete(row));
  }

  Measurement _fromRow(MeasurementRow row) => Measurement(
    id: MeasurementId(row.id),
    personId: PersonId(row.personId),
    kind: MeasurementKind.values.byName(row.kind),
    value: row.value,
    value2: row.value2,
    measuredAt: row.measuredAt,
    note: row.note,
  );
}
