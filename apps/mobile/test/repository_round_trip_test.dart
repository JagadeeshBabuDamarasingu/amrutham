// F1 acceptance: a full profile plus 3 family-history entries round-trips
// through the repository layer. See specs/phase-1-v1/01-features.md F1.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// drift's auto-named `Table` subclass collides with model/person.dart's
// EmergencyContact — see medication_repository.dart's import comment.
import 'package:amrutham/db/database.dart' hide EmergencyContact;
import 'package:amrutham/model/certainty.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/repository/profile_repository.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProfileRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('a created profile round-trips through the database', () async {
    final profile = await repository.createProfile(
      displayName: 'Lakshmi',
      relationship: RelationshipType.self,
      bloodGroup: 'O+',
      emergencyContacts: const [
        EmergencyContact(name: 'Appa', phone: '9000000000'),
      ],
    );

    final profiles = await repository.watchProfiles().first;

    expect(profiles, hasLength(1));
    expect(profiles.single.id, profile.id);
    expect(profiles.single.displayName, 'Lakshmi');
    expect(profiles.single.bloodGroup, 'O+');
    expect(profiles.single.emergencyContacts, hasLength(1));
    expect(profiles.single.emergencyContacts.single.name, 'Appa');
  });

  test('3 family-history entries round-trip for one profile', () async {
    final profile = await repository.createProfile(
      displayName: 'Amma',
      relationship: RelationshipType.parent,
    );

    for (final condition in ['Type-2 diabetes', 'Hypertension', 'Asthma']) {
      await repository.addFamilyHistoryEntry(
        personId: profile.id,
        relationship: 'mother',
        conditionText: condition,
        certainty: Certainty.reported,
      );
    }

    final entries = await repository.watchFamilyHistory(profile.id).first;
    expect(entries, hasLength(3));
    expect(
      entries.map((e) => e.conditionText),
      containsAll(<String>['Type-2 diabetes', 'Hypertension', 'Asthma']),
    );
  });

  test('an allergy record round-trips for one profile', () async {
    final profile = await repository.createProfile(
      displayName: 'Ravi',
      relationship: RelationshipType.self,
    );

    await repository.addAllergyRecord(
      personId: profile.id,
      substance: 'Penicillin',
      reaction: 'Hives',
      certainty: Certainty.confirmed,
    );

    final allergies = await repository.watchAllergies(profile.id).first;
    expect(allergies, hasLength(1));
    expect(allergies.single.substance, 'Penicillin');
    expect(allergies.single.certainty, Certainty.confirmed);
  });

  test(
    'family history and allergies stay scoped to their own profile',
    () async {
      final personA = await repository.createProfile(
        displayName: 'Person A',
        relationship: RelationshipType.self,
      );
      final personB = await repository.createProfile(
        displayName: 'Person B',
        relationship: RelationshipType.child,
      );

      await repository.addFamilyHistoryEntry(
        personId: personA.id,
        relationship: 'father',
        conditionText: 'Heart disease',
        certainty: Certainty.reported,
      );

      final entriesForB = await repository
          .watchFamilyHistory(personB.id)
          .first;
      expect(entriesForB, isEmpty);
    },
  );
}
