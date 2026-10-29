import 'dart:io';

import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import 'package:amrutham/db/realm_schemas.dart';

/// A fresh in-memory Realm, isolated from every other test in this run —
/// the unique path per call is what gives that isolation (two `inMemory`
/// configs sharing a path would share data), the same guarantee
/// drift's `NativeDatabase.memory()` gave per-test.
Realm openInMemoryRealm() {
  final config = Configuration.inMemory(
    [
      PersonRow.schema,
      EmergencyContactRow.schema,
      FamilyHistoryEntryRow.schema,
      AllergyRecordRow.schema,
      MedicationCourseRow.schema,
      SchedulePhaseRow.schema,
      MeasurementRow.schema,
      HistoryEventRow.schema,
      DoseLogRow.schema,
      CareProviderRow.schema,
      ExpenseRow.schema,
    ],
    // In the system temp dir: even in-memory Realms create .lock and
    // .management files beside this path, which littered the project root.
    path:
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'test-${Ulid()}.realm',
  );
  return Realm(config);
}
