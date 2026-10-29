import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/profile_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('a remembered person keeps their date and cause; the date can be unknown', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = ProfileRepository(realm);
    await repo.createProfile(
      displayName: 'Venkata Reddy',
      relationship: RelationshipType.parent,
      dateOfBirth: DateTime(1948),
      isDeceased: true,
      dateOfDeath: DateTime(2019),
      causeOfDeath: 'Heart problem, sudden.',
    );
    await repo.createProfile(
      displayName: 'Anita',
      relationship: RelationshipType.self,
    );
    await repo.createProfile(
      displayName: 'Grandfather',
      relationship: RelationshipType.otherDependent,
      isDeceased: true,
    );
    final all = await repo.watchProfiles().first;
    final venkata = all.firstWhere((p) => p.displayName == 'Venkata Reddy');
    expect(venkata.isDeceased, isTrue);
    expect(venkata.dateOfDeath, DateTime(2019)); // local midnight, not UTC
    expect(venkata.causeOfDeath, 'Heart problem, sudden.');
    expect(all.firstWhere((p) => p.displayName == 'Anita').isDeceased, isFalse);
    expect(all.firstWhere((p) => p.displayName == 'Grandfather').dateOfDeath, isNull);
  });
}
