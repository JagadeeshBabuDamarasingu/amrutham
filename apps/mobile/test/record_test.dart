import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/health_record.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/repository/record_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('records are filed as plain files, listed newest first, and deleted with their files', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final tmp = await Directory.systemTemp.createTemp('amrutham-vault-');
    addTearDown(() => tmp.delete(recursive: true));
    final vault = Directory('${tmp.path}/vault');
    final repo = RecordRepository(realm, vault);

    final src = File('${tmp.path}/scan.jpg')..writeAsBytesSync([1, 2, 3]);
    final src2 = File('${tmp.path}/scan2.jpg')..writeAsBytesSync([4, 5]);
    const amma = PersonId('amma');

    final r = await repo.add(
      personId: amma,
      type: RecordType.labReport,
      title: 'Blood panel report',
      recordDate: DateTime(2026, 10, 24),
      source: 'Vijaya Diagnostics',
      sources: [src, src2],
    );
    await repo.add(
      personId: amma,
      type: RecordType.bill,
      title: 'Pharmacy bill',
      recordDate: DateTime(2026, 10, 27),
      sources: [src],
    );

    expect(r.files, hasLength(2));
    expect(r.files.first, contains('2026-10-24-blood-panel-report'));
    expect(repo.fileFor(r.files.first).readAsBytesSync(), [1, 2, 3]);
    expect(repo.fileFor(r.files.last).readAsBytesSync(), [4, 5]);

    final all = await repo.watchAll().first;
    expect(all.map((x) => x.title), ['Pharmacy bill', 'Blood panel report']);
    expect(all.last.recordDate, DateTime(2026, 10, 24));

    await repo.delete(r.id);
    expect(repo.fileFor(r.files.first).existsSync(), isFalse);
    expect((await repo.watchAll().first).single.title, 'Pharmacy bill');
  });
}
