import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/history_event.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/history_repository.dart';
import 'package:amrutham/repository/profile_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('history events: newest first, per person, planned flag, delete', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final profiles = ProfileRepository(realm);
    final repo = HistoryRepository(realm);
    final appa = await profiles.createProfile(
      displayName: 'Appa',
      relationship: RelationshipType.parent,
    );
    final amma = await profiles.createProfile(
      displayName: 'Amma',
      relationship: RelationshipType.parent,
    );

    final past = await repo.addEvent(
      personId: appa.id,
      kind: HistoryKind.procedure,
      title: 'Cataract surgery',
      eventDate: DateTime(2022, 3, 1),
    );
    final planned = await repo.addEvent(
      personId: appa.id,
      kind: HistoryKind.procedure,
      title: 'Knee replacement',
      eventDate: DateTime.now().add(const Duration(days: 30)),
      provider: 'Dr. S. Rao',
    );
    await repo.addEvent(
      personId: amma.id,
      kind: HistoryKind.visit,
      title: 'Check-up',
      eventDate: DateTime(2026, 1, 1),
    );

    var list = await repo.watchEvents(appa.id).first;
    expect(list.map((e) => e.title), ['Knee replacement', 'Cataract surgery']);
    expect(list.first.isPlanned, isTrue);
    expect(list.last.isPlanned, isFalse);

    await repo.deleteEvent(past.id);
    list = await repo.watchEvents(appa.id).first;
    expect(list.single.id, planned.id);
  });

  test('emergency contacts can be added after the profile exists', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final profiles = ProfileRepository(realm);
    final p = await profiles.createProfile(
      displayName: 'Appa',
      relationship: RelationshipType.parent,
    );
    await profiles.addEmergencyContact(
      p.id,
      const EmergencyContact(
        name: 'Anita',
        phone: '+91 98765 43210',
        relationship: 'daughter',
      ),
    );
    final loaded = (await profiles.watchProfiles().first).single;
    expect(loaded.emergencyContacts.single.name, 'Anita');
    expect(loaded.emergencyContacts.single.relationship, 'daughter');
  });

  test('vaccine entries round trip as their own kind', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final baby = await ProfileRepository(realm).createProfile(
      displayName: 'Aarav',
      relationship: RelationshipType.child,
    );
    final repo = HistoryRepository(realm);
    await repo.addEvent(
      personId: baby.id,
      kind: HistoryKind.vaccine,
      title: 'BCG',
      eventDate: DateTime(2026, 7, 3),
      provider: 'Government hospital',
    );
    final events = await repo.watchEvents(baby.id).first;
    expect(events.single.kind, HistoryKind.vaccine);
    expect(events.single.provider, 'Government hospital');
  });
}
