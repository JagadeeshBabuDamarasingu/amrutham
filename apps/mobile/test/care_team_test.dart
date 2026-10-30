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

  test('one doctor can be linked to another person without retyping', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = CareTeamRepository(realm);
    const appa = PersonId('appa');
    const amma = PersonId('amma');
    final rao = await repo.add(kind: CareKind.doctor, name: 'Dr. S. Rao', personIds: [appa]);

    await repo.linkPerson(rao.id, amma);
    await repo.linkPerson(rao.id, amma); // linking twice changes nothing

    expect((await repo.watchAll().first).single.personIds, [appa, amma]);
    expect((await repo.watchForPerson(amma).first).single.name, 'Dr. S. Rao');
  });

  test('removing one person keeps the doctor; removing the last deletes it', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = CareTeamRepository(realm);
    const appa = PersonId('appa');
    const amma = PersonId('amma');
    final rao = await repo.add(kind: CareKind.doctor, name: 'Dr. S. Rao', personIds: [appa, amma]);

    await repo.unlinkPerson(rao.id, appa);
    expect(await repo.watchForPerson(appa).first, isEmpty);
    expect((await repo.watchForPerson(amma).first).single.name, 'Dr. S. Rao');

    await repo.unlinkPerson(rao.id, amma);
    expect(await repo.watchAll().first, isEmpty);
  });

  test('update changes every field, and can clear the optional ones', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = CareTeamRepository(realm);
    const appa = PersonId('appa');
    const amma = PersonId('amma');
    final rao = await repo.add(
      kind: CareKind.doctor,
      name: 'Dr. S. Rao',
      specialty: 'Cardiologist',
      worksAt: 'Rao Clinic',
      phone: '98480 55012',
      location: 'Kondapur',
      personIds: [appa],
    );

    await repo.update(
      rao.id,
      kind: CareKind.facility,
      name: 'Rao Heart Centre',
      phone: '040 1234 5678',
      personIds: [appa, amma],
      isCurrent: false,
    );

    final saved = (await repo.watchAll().first).single;
    expect(saved.kind, CareKind.facility);
    expect(saved.name, 'Rao Heart Centre');
    expect((saved.specialty, saved.worksAt, saved.location), (null, null, null));
    expect(saved.phone, '040 1234 5678');
    expect(saved.personIds, [appa, amma]);
    expect(saved.isCurrent, isFalse);
  });

  test('update with nobody linked is ignored', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = CareTeamRepository(realm);
    final rao = await repo.add(kind: CareKind.doctor, name: 'Dr. S. Rao', personIds: [const PersonId('appa')]);
    await repo.update(rao.id, kind: CareKind.doctor, name: 'Changed', personIds: [], isCurrent: true);
    expect((await repo.watchAll().first).single.name, 'Dr. S. Rao');
  });

  group('sameProvider', () {
    CareProvider p(String name, {CareKind kind = CareKind.doctor, String id = 'x'}) => CareProvider(
      id: CareProviderId(id),
      kind: kind,
      name: name,
      personIds: const [],
      isCurrent: true,
    );

    test('ignores case, Dr., dots and spacing', () {
      final saved = [p('Dr. S. Rao')];
      for (final typed in ['s rao', 'DR S RAO', 'Dr S.Rao ', 'Dr.  S.  Rao']) {
        expect(sameProvider(saved, CareKind.doctor, typed), isNotNull, reason: typed);
      }
    });
    test('different people, kinds and blank names do not match', () {
      final saved = [p('Dr. S. Rao')];
      expect(sameProvider(saved, CareKind.doctor, 'Dr. S. Reddy'), isNull);
      expect(sameProvider(saved, CareKind.facility, 'Dr. S. Rao'), isNull);
      expect(sameProvider(saved, CareKind.doctor, '  '), isNull);
      expect(sameProvider(saved, CareKind.doctor, 'Draupadi'), isNull);
    });
    test('an entry never matches itself when editing', () {
      final saved = [p('Dr. S. Rao', id: 'a')];
      expect(sameProvider(saved, CareKind.doctor, 'Dr. S. Rao', except: const CareProviderId('a')), isNull);
    });
  });
}
