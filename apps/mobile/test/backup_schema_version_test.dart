// The backup document is versioned with a semantic version, and every major
// version we have ever written keeps a reader so old backups still open.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';

import 'package:amrutham/backup/vault_backup.dart';
import 'package:amrutham/db/realm_schemas.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/profile_repository.dart';

import 'realm_test_helper.dart';

void main() {
  late Realm realm;
  late Directory tmp;

  setUp(() async {
    realm = openInMemoryRealm();
    tmp = await Directory.systemTemp.createTemp('schema-version-');
  });
  tearDown(() async {
    realm.close();
    await tmp.delete(recursive: true);
  });

  Map<String, dynamic> person(String name) => {
    'id': 'p1', 'displayName': name, 'relationship': 'self',
    'createdAt': '2025-01-01T00:00:00.000Z', 'emergencyContacts': <Object>[],
  };

  Future<List<String>> restore(Map<String, dynamic> data) =>
      VaultBackup.restore(realm, Directory('${tmp.path}/vault'), data);

  test('a new snapshot carries a semantic schemaVersion and the major as version', () async {
    await ProfileRepository(realm).createProfile(displayName: 'A', relationship: RelationshipType.self);
    final data = await VaultBackup.snapshot(realm, Directory('${tmp.path}/vault'));
    expect(data['schemaVersion'], VaultBackup.schemaVersion);
    expect(RegExp(r'^\d+\.\d+\.\d+$').hasMatch(VaultBackup.schemaVersion), isTrue);
    expect(data['version'], 1);
  });

  test('a file from before schemaVersion existed (only version: 1) still restores', () async {
    // Frozen shape of the first backups: no schemaVersion, no careTeam,
    // doseLogs, expenses or receipts, and no given name or surname.
    final ids = await restore({'version': 1, 'people': [person('Old Appa')]});
    expect(ids, ['p1']);
    expect(realm.all<PersonRow>().single.displayName, 'Old Appa');
  });

  test('a newer minor version of the same major restores and ignores what it does not know', () async {
    final ids = await restore({
      'version': 1,
      'schemaVersion': '1.7.2',
      'people': [
        {...person('Amma'), 'someFutureField': 42},
      ],
      'aFutureTable': [1, 2, 3],
    });
    expect(ids, ['p1']);
    expect(realm.all<PersonRow>().single.displayName, 'Amma');
  });

  test('a newer major version is refused before anything is touched', () async {
    await ProfileRepository(realm).createProfile(displayName: 'Keep me', relationship: RelationshipType.self);
    await expectLater(
      restore({'version': 2, 'schemaVersion': '2.0.0', 'people': <Object>[]}),
      throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('newer version'))),
    );
    expect(realm.all<PersonRow>().single.displayName, 'Keep me');
  });

  test('a major version we have no reader for, or a malformed version, is refused', () async {
    await expectLater(restore({'schemaVersion': '0.9.0'}), throwsA(isA<BackupException>()));
    await expectLater(restore({'schemaVersion': 'one.two'}), throwsA(isA<BackupException>()));
    await expectLater(restore({'schemaVersion': '1.0'}), throwsA(isA<BackupException>()));
    await expectLater(restore(<String, dynamic>{}), throwsA(isA<BackupException>()));
  });

  test('every major up to the current one has a reader', () {
    final current = int.parse(VaultBackup.schemaVersion.split('.').first);
    for (var major = 1; major <= current; major++) {
      expect(
        () => VaultBackup.parseSchemaVersion({'schemaVersion': '$major.0.0'}),
        returnsNormally,
      );
    }
  });
}
