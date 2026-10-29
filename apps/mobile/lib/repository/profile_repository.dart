import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
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
  final Realm _realm;

  ProfileRepository(this._realm);

  // ---- PersonProfile ----

  Stream<List<PersonProfile>> watchProfiles() {
    return _realm.all<PersonRow>().changes.map(
      (c) => c.results.map(_profileFromRow).toList(),
    );
  }

  PersonProfile _profileFromRow(PersonRow row) {
    return PersonProfile(
      id: PersonId(row.id),
      displayName: row.displayName,
      relationship: RelationshipType.values.byName(row.relationship),
      dateOfBirth: row.dateOfBirth,
      sex: row.sex,
      bloodGroup: row.bloodGroup,
      emergencyContacts: row.emergencyContacts
          .map(
            (c) => EmergencyContact(
              name: c.name,
              phone: c.phone,
              relationship: c.relationship,
            ),
          )
          .toList(),
      createdAt: row.createdAt,
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

    _realm.write(() {
      _realm.add(
        PersonRow(
          id.value,
          displayName,
          relationship.name,
          createdAt,
          dateOfBirth: dateOfBirth,
          sex: sex,
          bloodGroup: bloodGroup,
          emergencyContacts: emergencyContacts
              .map(
                (c) => EmergencyContactRow(
                  c.name,
                  c.phone,
                  relationship: c.relationship,
                ),
              )
              .toList(),
        ),
      );
    });

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
    return _realm
        .query<FamilyHistoryEntryRow>(r'personId == $0', [personId.value])
        .changes
        .map((c) => c.results.map(_familyHistoryFromRow).toList());
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
    _realm.write(() {
      _realm.add(
        FamilyHistoryEntryRow(
          id.value,
          personId.value,
          relationship,
          conditionText,
          certainty.name,
          conditionCode: conditionCode,
          onsetAgeApprox: onsetAgeApprox,
          outcome: outcome,
          notes: notes,
        ),
      );
    });
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
    return _realm
        .query<AllergyRecordRow>(r'personId == $0', [personId.value])
        .changes
        .map((c) => c.results.map(_allergyFromRow).toList());
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
    _realm.write(() {
      _realm.add(
        AllergyRecordRow(
          id.value,
          personId.value,
          substance,
          reaction,
          certainty.name,
          severity: severity,
          notes: notes,
        ),
      );
    });
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
