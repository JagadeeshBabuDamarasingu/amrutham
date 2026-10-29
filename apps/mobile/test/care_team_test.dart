import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/care_provider.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/repository/care_team_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('a shared doctor appears for each person; past and delete work', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = CareTeamRepository(realm);
    const appa = PersonId('appa');
    const amma = PersonId('amma');

    final iyer = await repo.add(
      kind: CareKind.doctor,
      name: 'Dr. Lakshmi Iyer',
      specialty: 'General physician',
      phone: '+91 98480 55012',
      personIds: [appa, amma],
    );
    await repo.add(
      kind: CareKind.facility,
      name: 'Apollo Hospitals',
      personIds: [appa],
    );

    expect((await repo.watchForPerson(appa).first).map((p) => p.name), [
      'Apollo Hospitals',
      'Dr. Lakshmi Iyer',
    ]);
    expect((await repo.watchForPerson(amma).first).single.name, 'Dr. Lakshmi Iyer');

    await repo.setCurrent(iyer.id, false);
    expect((await repo.watchForPerson(amma).first).single.isCurrent, isFalse);

    await repo.delete(iyer.id);
    expect(await repo.watchForPerson(amma).first, isEmpty);
  });
}
