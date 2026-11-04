import 'dart:io';

import 'package:amrutham/db/realm_schemas.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/profile_repository.dart';
import 'package:amrutham/sync/sync_engine.dart';
import 'package:amrutham/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';

import 'realm_test_helper.dart';

void main() {
  test('a profile made on one phone appears on the other, and edits flow back', () async {
    final tmp = await Directory.systemTemp.createTemp('amr_svc');
    addTearDown(() => tmp.delete(recursive: true));
    final key = SyncEngine.newFamilyKey();
    final folder = FolderBlobStore(Directory('${tmp.path}/shared'));
    var t = 1000;
    int clock() => t += 10;

    final ra = openInMemoryRealm(), rb = openInMemoryRealm();
    SyncService svc(Realm r, String n) => SyncService(
        realm: r, stateFile: File('${tmp.path}/$n.json'), store: folder, familyKey: key);
    final a = svc(ra, 'a'), b = svc(rb, 'b');

    final appa = await ProfileRepository(ra).createProfile(
        displayName: 'Appa', relationship: RelationshipType.parent, bloodGroup: 'O positive');
    final first = await a.run(now: clock);
    expect(first.sent, greaterThan(0));

    final got = await b.run(now: clock);
    expect(got.received, greaterThan(0));
    PersonRow? row(r) => r.find<PersonRow>(appa.id.value);
    expect(row(rb)!.displayName, 'Appa');
    expect(row(rb)!.bloodGroup, 'O positive');

    // Nothing new: nothing sent, nothing written.
    expect((await b.run(now: clock)).sent, 0);

    await ProfileRepository(rb).updateProfile(appa.id,
        displayName: 'Appa', relationship: RelationshipType.parent, bloodGroup: 'A positive');
    await b.run(now: clock);
    final back = await a.run(now: clock);
    expect(back.people, contains(appa.id.value));
    expect(row(ra)!.bloodGroup, 'A positive');
  });
}
