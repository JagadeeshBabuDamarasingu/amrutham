import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/backup/vault_backup.dart';
import 'package:amrutham/crypto/recovery_code.dart';
import 'package:amrutham/model/care_provider.dart';
import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/health_record.dart';
import 'package:amrutham/model/history_event.dart';
import 'package:amrutham/model/measurement.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/care_team_repository.dart';
import 'package:amrutham/repository/expense_repository.dart';
import 'package:amrutham/repository/history_repository.dart';
import 'package:amrutham/repository/measurement_repository.dart';
import 'package:amrutham/repository/profile_repository.dart';
import 'package:amrutham/repository/record_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('a backup round-trips everything, and only the right code opens it', () async {
    final tmp = await Directory.systemTemp.createTemp('amrutham-backup-');
    addTearDown(() => tmp.delete(recursive: true));

    // --- a vault with a bit of everything ---
    final realm = openInMemoryRealm();
    final vault = Directory('${tmp.path}/vault');
    final profiles = ProfileRepository(realm);
    final appa = await profiles.createProfile(
      displayName: 'Appa',
      relationship: RelationshipType.parent,
      dateOfBirth: DateTime(1954, 3, 14),
      bloodGroup: 'O positive',
      emergencyContacts: const [EmergencyContact(name: 'Anita', phone: '+91 98765 43210', relationship: 'daughter')],
    );
    await profiles.createProfile(
      displayName: 'Venkata',
      relationship: RelationshipType.parent,
      isDeceased: true,
      dateOfDeath: DateTime(2019),
      causeOfDeath: 'Heart problem',
    );
    await MeasurementRepository(realm).addMeasurement(
      personId: appa.id,
      kind: MeasurementKind.bloodPressure,
      value: 128,
      value2: 82,
      measuredAt: DateTime(2026, 10, 29, 7, 30),
    );
    await HistoryRepository(realm).addEvent(
      personId: appa.id,
      kind: HistoryKind.procedure,
      title: 'Cataract surgery',
      eventDate: DateTime(2022, 3, 1),
    );
    await ExpenseRepository(realm).add(
      personId: appa.id,
      title: 'Blood panel',
      amountPaise: 185050,
      category: ExpenseCategory.tests,
      spentOn: DateTime(2026, 10, 24),
    );
    await CareTeamRepository(realm).add(
      kind: CareKind.doctor,
      name: 'Dr. S. Rao',
      personIds: [appa.id],
    );
    final scan = File('${tmp.path}/scan.jpg')..writeAsBytesSync([9, 8, 7, 6]);
    final records = RecordRepository(realm, vault);
    await records.add(
      personId: appa.id,
      type: RecordType.labReport,
      title: 'Blood panel report',
      recordDate: DateTime(2026, 10, 24),
      sources: [scan],
    );

    // --- encrypt, then open with the right and the wrong code ---
    final code = RecoveryCode.generate();
    final bytes = await VaultBackup.encrypt(await VaultBackup.snapshot(realm, vault), code);
    expect(String.fromCharCodes(bytes.take(6)), 'AMRBK1');

    await expectLater(
      VaultBackup.decrypt(bytes, RecoveryCode.generate()),
      throwsA(isA<BackupException>()),
    );
    await expectLater(
      VaultBackup.decrypt([1, 2, 3], code),
      throwsA(isA<BackupException>()),
    );
    final data = await VaultBackup.decrypt(bytes, code);

    // --- restore into a different, non-empty vault: it is replaced ---
    final other = openInMemoryRealm();
    final otherVault = Directory('${tmp.path}/other');
    await ProfileRepository(other).createProfile(
      displayName: 'Someone else',
      relationship: RelationshipType.self,
    );
    final ids = await VaultBackup.restore(other, otherVault, data);

    expect(ids, hasLength(2));
    final people = await ProfileRepository(other).watchProfiles().first;
    expect(people.map((p) => p.displayName).toSet(), {'Appa', 'Venkata'});
    final restoredAppa = people.firstWhere((p) => p.displayName == 'Appa');
    expect(restoredAppa.dateOfBirth, DateTime(1954, 3, 14));
    expect(restoredAppa.emergencyContacts.single.phone, '+91 98765 43210');
    expect(people.firstWhere((p) => p.displayName == 'Venkata').isDeceased, isTrue);

    final bp = (await MeasurementRepository(other).watchMeasurements(restoredAppa.id).first).single;
    expect((bp.value, bp.value2, bp.measuredAt), (128.0, 82.0, DateTime(2026, 10, 29, 7, 30)));
    expect((await HistoryRepository(other).watchEvents(restoredAppa.id).first).single.title, 'Cataract surgery');
    expect((await ExpenseRepository(other).watchAll().first).single.amountPaise, 185050);
    expect((await CareTeamRepository(other).watchForPerson(restoredAppa.id).first).single.name, 'Dr. S. Rao');

    final restoredRecords = RecordRepository(other, otherVault);
    final rec = (await restoredRecords.watchAll().first).single;
    expect(restoredRecords.fileFor(rec.files.single).readAsBytesSync(), [9, 8, 7, 6]);
  });
}
