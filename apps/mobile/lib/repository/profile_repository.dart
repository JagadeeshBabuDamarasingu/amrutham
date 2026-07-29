import 'package:drift/drift.dart';
import 'package:ulid/ulid.dart';

// See medication_repository.dart's import comment: drift's auto-named
// `Table` subclasses (not the `AS ...Row` data classes) collide with our
// domain-model classes of the same name.
import '../db/database.dart' hide AllergyRecord, FamilyHistoryEntry, EmergencyContact;
import '../model/allergy.dart';
import '../model/certainty.dart';
import '../model/family_history.dart';
import '../model/ids.dart';
import '../model/person.dart';

/// The only way UI code touches persisted data — UI must never write to
/// db/ directly. See specs/phase-1-v1/02-architecture.md §1 and the M5
/// milestone note in specs/phase-1-v1/00-overview.md ("this is why M1–M4
/// must go through the repository layer consistently rather than writing to
/// the database directly from UI code").
class ProfileRepository {
  final AppDatabase _db;

  ProfileRepository(this._db);

  // ---- PersonProfile ----

  Stream<List<PersonProfile>> watchProfiles() {
    return _db.select(_db.person).watch().asyncMap((rows) async {
      final profiles = <PersonProfile>[];
      for (final row in rows) {
        profiles.add(await _hydrateProfile(row));
      }
      return profiles;
    });
  }

  Future<PersonProfile> _hydrateProfile(PersonRow row) async {
    final contactRows = await (_db.select(
      _db.emergencyContact,
    )..where((t) => t.personId.equals(row.id))).get();
    return _profileFromRow(row, contactRows);
  }

  PersonProfile _profileFromRow(
    PersonRow row,
    List<EmergencyContactRow> contactRows,
  ) {
    return PersonProfile(
      id: PersonId(row.id),
      displayName: row.displayName,
      relationship: RelationshipType.values.byName(row.relationship),
      dateOfBirth: row.dateOfBirth == null
          ? null
          : DateTime.parse(row.dateOfBirth!),
      sex: row.sex,
      bloodGroup: row.bloodGroup,
      emergencyContacts: contactRows
          .map(
            (c) => EmergencyContact(
              name: c.name,
              phone: c.phone,
              relationship: c.relationship,
            ),
          )
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    );
  }

  Future<PersonProfile> createProfile({
    required String displayName,
    required RelationshipType relationship,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
    List<EmergencyContact> emergencyContacts = const [],
  }) async {
    final id = PersonId(Ulid().toString());
    final createdAt = DateTime.now();

    await _db
        .into(_db.person)
        .insert(
          PersonCompanion.insert(
            id: id.value,
            displayName: displayName,
            relationship: relationship.name,
            dateOfBirth: Value(dateOfBirth?.toIso8601String()),
            sex: Value(sex),
            bloodGroup: Value(bloodGroup),
            createdAt: createdAt.millisecondsSinceEpoch,
          ),
        );

    for (final contact in emergencyContacts) {
      await _db
          .into(_db.emergencyContact)
          .insert(
            EmergencyContactCompanion.insert(
              id: Ulid().toString(),
              personId: id.value,
              name: contact.name,
              phone: contact.phone,
              relationship: Value(contact.relationship),
            ),
          );
    }

    return PersonProfile(
      id: id,
      displayName: displayName,
      relationship: relationship,
      dateOfBirth: dateOfBirth,
      sex: sex,
      bloodGroup: bloodGroup,
      emergencyContacts: emergencyContacts,
      createdAt: createdAt,
    );
  }

  // ---- FamilyHistoryEntry ----

  Stream<List<FamilyHistoryEntry>> watchFamilyHistory(PersonId personId) {
    return (_db.select(
      _db.familyHistoryEntry,
    )..where((t) => t.personId.equals(personId.value))).watch().map(
      (rows) => rows.map(_familyHistoryFromRow).toList(),
    );
  }

  FamilyHistoryEntry _familyHistoryFromRow(FamilyHistoryEntryRow row) {
    return FamilyHistoryEntry(
      id: FamilyHistoryEntryId(row.id),
      personId: PersonId(row.personId),
      relationship: row.relationship,
      conditionText: row.conditionText,
      conditionCode: row.conditionCode,
      onsetAgeApprox: row.onsetAgeApprox,
      outcome: row.outcome,
      certainty: Certainty.values.byName(row.certainty),
      notes: row.notes,
    );
  }

  Future<FamilyHistoryEntry> addFamilyHistoryEntry({
    required PersonId personId,
    required String relationship,
    required String conditionText,
    String? conditionCode,
    int? onsetAgeApprox,
    String? outcome,
    required Certainty certainty,
    String? notes,
  }) async {
    final id = FamilyHistoryEntryId(Ulid().toString());
    await _db
        .into(_db.familyHistoryEntry)
        .insert(
          FamilyHistoryEntryCompanion.insert(
            id: id.value,
            personId: personId.value,
            relationship: relationship,
            conditionText: conditionText,
            conditionCode: Value(conditionCode),
            onsetAgeApprox: Value(onsetAgeApprox),
            outcome: Value(outcome),
            certainty: certainty.name,
            notes: Value(notes),
          ),
        );
    return FamilyHistoryEntry(
      id: id,
      personId: personId,
      relationship: relationship,
      conditionText: conditionText,
      conditionCode: conditionCode,
      onsetAgeApprox: onsetAgeApprox,
      outcome: outcome,
      certainty: certainty,
      notes: notes,
    );
  }

  // ---- AllergyRecord ----

  Stream<List<AllergyRecord>> watchAllergies(PersonId personId) {
    return (_db.select(
      _db.allergyRecord,
    )..where((t) => t.personId.equals(personId.value))).watch().map(
      (rows) => rows.map(_allergyFromRow).toList(),
    );
  }

  AllergyRecord _allergyFromRow(AllergyRecordRow row) {
    return AllergyRecord(
      id: AllergyRecordId(row.id),
      personId: PersonId(row.personId),
      substance: row.substance,
      reaction: row.reaction,
      severity: row.severity,
      certainty: Certainty.values.byName(row.certainty),
      notes: row.notes,
    );
  }

  Future<AllergyRecord> addAllergyRecord({
    required PersonId personId,
    required String substance,
    required String reaction,
    String? severity,
    required Certainty certainty,
    String? notes,
  }) async {
    final id = AllergyRecordId(Ulid().toString());
    await _db
        .into(_db.allergyRecord)
        .insert(
          AllergyRecordCompanion.insert(
            id: id.value,
            personId: personId.value,
            substance: substance,
            reaction: reaction,
            severity: Value(severity),
            certainty: certainty.name,
            notes: Value(notes),
          ),
        );
    return AllergyRecord(
      id: id,
      personId: personId,
      substance: substance,
      reaction: reaction,
      severity: severity,
      certainty: certainty,
      notes: notes,
    );
  }
}
