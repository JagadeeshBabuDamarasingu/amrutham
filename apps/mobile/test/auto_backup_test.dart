import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/backup/auto_backup.dart';
import 'package:amrutham/backup/drive_backup.dart';
import 'package:amrutham/backup/vault_backup.dart';
import 'package:amrutham/crypto/recovery_code.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/profile_repository.dart';

import 'memory_onboarding_store.dart';
import 'realm_test_helper.dart';

final _code = RecoveryCode.parse('ABCD-EFGH-JKMN-PQRS-TUVW-XYZ2')!;
final _noon = DateTime(2026, 10, 31, 12);

void main() {
  group('isDue', () {
    test('never backed up is due', () => expect(isDue(null, 1, _noon), isTrue));
    test('a few hours ago is not', () => expect(isDue(_noon.subtract(const Duration(hours: 5)), 1, _noon), isFalse));
    test('a day ago is, even if it ran a little later in the day', () {
      expect(isDue(_noon.subtract(const Duration(hours: 23)), 1, _noon), isTrue);
    });
    test('weekly waits six days', () {
      expect(isDue(_noon.subtract(const Duration(days: 5)), 7, _noon), isFalse);
      expect(isDue(_noon.subtract(const Duration(days: 7)), 7, _noon), isTrue);
    });
  });

  test('a stored key round-trips, and junk decodes to nothing', () async {
    final key = await VaultBackup.deriveAutoKey(_code);
    final again = AutoBackupKey.decode(key.encode())!;
    expect(again.salt, orderedEquals(key.salt));
    expect(again.key, orderedEquals(key.key));
    expect(AutoBackupKey.decode(null), isNull);
    expect(AutoBackupKey.decode('nope'), isNull);
    expect(AutoBackupKey.decode('AAAA.BBBB'), isNull);
  });

  test('a backup made with the stored key opens with the recovery code', () async {
    final tmp = await Directory.systemTemp.createTemp('auto');
    addTearDown(() => tmp.delete(recursive: true));
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    await ProfileRepository(realm).createProfile(displayName: 'Appa', relationship: RelationshipType.parent);

    final key = await VaultBackup.deriveAutoKey(_code);
    final bytes = await VaultBackup.encryptWithKey(await VaultBackup.snapshot(realm, tmp), key);

    final data = await VaultBackup.decrypt(bytes, _code);
    expect((data['people'] as List).single['displayName'], 'Appa');
    await expectLater(
      VaultBackup.decrypt(bytes, RecoveryCode.parse('ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZ')!),
      throwsA(isA<BackupException>()),
    );
    // Two backups under one key differ (fresh nonce) but both open.
    final second = await VaultBackup.encryptWithKey(await VaultBackup.snapshot(realm, tmp), key);
    expect(second, isNot(bytes));
    await VaultBackup.decrypt(second, _code);
  });

  group('runAutoBackup', () {
    late MemoryOnboardingStore store;
    late Directory tmp;
    final uploads = <List<int>>[];
    final folderWrites = <String>[];

    setUp(() async {
      store = MemoryOnboardingStore();
      tmp = await Directory.systemTemp.createTemp('auto');
      uploads.clear();
      folderWrites.clear();
    });
    tearDown(() => tmp.delete(recursive: true));

    Future<({Outcome drive, Outcome folder})> run({
      DateTime? now,
      Future<void> Function(List<int>)? drive,
      Future<void> Function(String, List<int>)? folder,
    }) async {
      final realm = openInMemoryRealm();
      addTearDown(realm.close);
      return runAutoBackup(
        realm: realm,
        vault: tmp,
        store: store,
        now: now ?? _noon,
        uploadToDrive: drive ?? (b) async => uploads.add(b),
        writeToFolder: folder ?? (f, b) async => folderWrites.add(f),
      );
    }

    Future<void> setUpBoth() async {
      await store.putSetting(driveEmailKey, 'me@example.com');
      await store.setBackupFolder('content://tree/x');
      await enableAutoBackup(store, _code);
    }

    test('does nothing while it is off', () async {
      await store.putSetting(driveEmailKey, 'me@example.com');
      final r = await run();
      expect((r.drive, r.folder), (Outcome.skipped, Outcome.skipped));
      expect(uploads, isEmpty);
    });

    test('backs up both destinations when due, and records the time', () async {
      await setUpBoth();
      final r = await run();
      expect((r.drive, r.folder), (Outcome.done, Outcome.done));
      expect(uploads, hasLength(1));
      expect(folderWrites, ['content://tree/x']);
      final s = await AutoBackupSettings.load(store);
      expect(s.driveLast, _noon);
      expect(s.folderLast, _noon);
      expect((s.driveError, s.folderError), (null, null));
    });

    test('a second run soon after does nothing', () async {
      await setUpBoth();
      await run();
      final r = await run(now: _noon.add(const Duration(hours: 3)));
      expect((r.drive, r.folder), (Outcome.skipped, Outcome.skipped));
      expect(uploads, hasLength(1));
    });

    test('the next day it runs again', () async {
      await setUpBoth();
      await run();
      final r = await run(now: _noon.add(const Duration(days: 1)));
      expect((r.drive, r.folder), (Outcome.done, Outcome.done));
    });

    test('weekly leaves a day-old backup alone', () async {
      await setUpBoth();
      await setAutoBackupDays(store, 7);
      await run();
      final r = await run(now: _noon.add(const Duration(days: 2)));
      expect((r.drive, r.folder), (Outcome.skipped, Outcome.skipped));
    });

    test('only the destinations switched on are used', () async {
      await setUpBoth();
      await setAutoBackupDestination(store, drive: false);
      final r = await run();
      expect((r.drive, r.folder), (Outcome.skipped, Outcome.done));
      expect(uploads, isEmpty);
    });

    test('a destination that is not set up is skipped, not failed', () async {
      await store.setBackupFolder('content://tree/x');
      await enableAutoBackup(store, _code); // Drive never connected
      final r = await run();
      expect((r.drive, r.folder), (Outcome.skipped, Outcome.done));
    });

    test('one failing destination is recorded and does not stop the other', () async {
      await setUpBoth();
      final r = await run(drive: (_) async => throw StateError('no activity'));
      expect((r.drive, r.folder), (Outcome.failed, Outcome.done));
      final s = await AutoBackupSettings.load(store);
      expect(s.driveError, contains('no activity'));
      expect(s.driveLast, isNull); // still due next time
      expect(s.folderLast, _noon);

      final retry = await run(now: _noon.add(const Duration(hours: 1)));
      expect((retry.drive, retry.folder), (Outcome.done, Outcome.skipped));
      expect((await AutoBackupSettings.load(store)).driveError, isNull);
    });

    test('turning it off forgets the key and stops backups', () async {
      await setUpBoth();
      await disableAutoBackup(store);
      expect((await AutoBackupSettings.load(store)).key, isNull);
      final r = await run();
      expect((r.drive, r.folder), (Outcome.skipped, Outcome.skipped));
    });
  });
}
