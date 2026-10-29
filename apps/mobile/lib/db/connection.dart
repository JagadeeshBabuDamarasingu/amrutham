import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';

import 'realm_schemas.dart';

final List<SchemaObject> _schema = [
  PersonRow.schema,
  EmergencyContactRow.schema,
  FamilyHistoryEntryRow.schema,
  AllergyRecordRow.schema,
  MedicationCourseRow.schema,
  SchedulePhaseRow.schema,
];

/// Opens the encrypted local Realm. `dbKey` is the 64-byte device DB key from
/// [DbKeyProvider] (crypto/key_manager.dart) — never the export/recovery
/// passphrase, which is a separate key used only by the vault (M5). See
/// specs/phase-1-v1/02-architecture.md §4 and §8.
Future<Realm> openRealm(List<int> dbKey) async {
  // App-support dir, not the user-visible documents dir: this file is an
  // internal rebuildable cache, not the vault the user owns and can see.
  final dir = await getApplicationSupportDirectory();
  final path = p.join(dir.path, 'amrutham.realm');
  final config = Configuration.local(
    _schema,
    path: path,
    encryptionKey: dbKey,
  );
  return Realm(config);
}
