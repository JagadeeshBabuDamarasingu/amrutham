import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/measurement.dart';
import 'package:amrutham/repository/measurement_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('readings display exactly as logged', () {
    expect(formatReading(MeasurementKind.bloodPressure, 128, 82), '128/82');
    expect(formatReading(MeasurementKind.weight, 71.4), '71.4');
    expect(formatReading(MeasurementKind.weight, 70), '70');
    expect(formatReading(MeasurementKind.sleep, 6.6667), '6h 40m');
  });

  test('add, list newest first, per person, and delete', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = MeasurementRepository(realm);
    const amma = PersonId('amma');
    const appa = PersonId('appa');

    final older = await repo.addMeasurement(
      personId: amma,
      kind: MeasurementKind.bloodPressure,
      value: 128,
      value2: 82,
      measuredAt: DateTime(2026, 10, 28, 7, 30),
    );
    await repo.addMeasurement(
      personId: amma,
      kind: MeasurementKind.weight,
      value: 71.4,
      value2: 99, // ignored: weight has no second value
      measuredAt: DateTime(2026, 10, 29, 7, 30),
    );
    await repo.addMeasurement(
      personId: appa,
      kind: MeasurementKind.weight,
      value: 80,
      measuredAt: DateTime(2026, 10, 29),
    );

    var list = (await repo.watchMeasurements(amma).first);
    expect(list.map((m) => m.kind), [
      MeasurementKind.weight,
      MeasurementKind.bloodPressure,
    ]);
    expect(list.first.value2, isNull);
    expect(list.last.display, '128/82');

    await repo.deleteMeasurement(older.id);
    list = await repo.watchMeasurements(amma).first;
    expect(list, hasLength(1));
  });
}
