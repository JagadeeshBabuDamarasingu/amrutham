import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/profile_repository.dart';

import 'realm_test_helper.dart';

PersonProfile _person(String displayName, {String? given, String? surname}) => PersonProfile(
  id: const PersonId('p'),
  displayName: displayName,
  givenName: given,
  surname: surname,
  relationship: RelationshipType.self,
  createdAt: DateTime(2026),
);

void main() {
  test('given name and surname are stored apart and read back', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = ProfileRepository(realm);
    await repo.createProfile(
      displayName: 'Lakshmi Iyer',
      givenName: 'Lakshmi',
      surname: 'Iyer',
      relationship: RelationshipType.parent,
    );
    final saved = (await repo.watchProfiles().first).single;
    expect((saved.givenName, saved.surname, saved.displayName), ('Lakshmi', 'Iyer', 'Lakshmi Iyer'));
  });

  test('a profile made before the parts existed has none', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = ProfileRepository(realm);
    await repo.createProfile(displayName: 'Appa', relationship: RelationshipType.parent);
    final saved = (await repo.watchProfiles().first).single;
    expect((saved.givenName, saved.surname), (null, null));
  });

  group('firstName', () {
    test('prefers the given name', () {
      expect(_person('Iyer Lakshmi', given: 'Lakshmi', surname: 'Iyer').firstName, 'Lakshmi');
    });
    test('falls back to the first word of the full name', () {
      expect(_person('Rohan Reddy').firstName, 'Rohan');
      expect(_person('  Rohan   Reddy ').firstName, 'Rohan');
    });
    test('a blank given name falls back too', () {
      expect(_person('Rohan Reddy', given: '  ').firstName, 'Rohan');
    });
    test('a single name is returned whole', () {
      expect(_person('Appa').firstName, 'Appa');
    });
  });
}
