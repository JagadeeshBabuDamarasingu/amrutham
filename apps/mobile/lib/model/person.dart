import 'ids.dart';

enum RelationshipType { self, child, parent, otherDependent }

class EmergencyContact {
  final String name;
  final String phone;
  final String? relationship;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relationship,
  });
}

/// No adult-peer accounts, no admin role — per-person data ownership is the
/// model. See specs/phase-1-v1/01-features.md F1.
class PersonProfile {
  final PersonId id;
  final String displayName;
  final RelationshipType relationship;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? bloodGroup;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;

  const PersonProfile({
    required this.id,
    required this.displayName,
    required this.relationship,
    this.dateOfBirth,
    this.sex,
    this.bloodGroup,
    this.emergencyContacts = const [],
    required this.createdAt,
  });

  PersonProfile copyWith({
    String? displayName,
    RelationshipType? relationship,
    DateTime? dateOfBirth,
    String? sex,
    String? bloodGroup,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return PersonProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      createdAt: createdAt,
    );
  }
}
