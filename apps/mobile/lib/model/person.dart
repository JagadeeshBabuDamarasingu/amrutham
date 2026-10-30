import 'ids.dart';

enum RelationshipType { self, spouse, child, parent, sibling, otherDependent }

extension RelationshipLabel on RelationshipType {
  String get label => switch (this) {
    RelationshipType.self => 'Self',
    RelationshipType.spouse => 'Spouse',
    RelationshipType.child => 'Child',
    RelationshipType.parent => 'Parent',
    RelationshipType.sibling => 'Sibling',
    RelationshipType.otherDependent => 'Other',
  };
}

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

  /// The parts of [displayName] ("Given Surname"), when they were entered
  /// separately. Null for profiles made before the app asked for them.
  final String? givenName;
  final String? surname;
  final RelationshipType relationship;
  final DateTime? dateOfBirth;
  final String? sex;
  final String? bloodGroup;
  final List<EmergencyContact> emergencyContacts;
  final DateTime createdAt;
  final bool isDeceased;
  final DateTime? dateOfDeath;
  final String? causeOfDeath;

  const PersonProfile({
    required this.id,
    required this.displayName,
    this.givenName,
    this.surname,
    required this.relationship,
    this.dateOfBirth,
    this.sex,
    this.bloodGroup,
    this.emergencyContacts = const [],
    required this.createdAt,
    this.isDeceased = false,
    this.dateOfDeath,
    this.causeOfDeath,
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
      givenName: givenName,
      surname: surname,
      relationship: relationship ?? this.relationship,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      createdAt: createdAt,
      isDeceased: isDeceased,
      dateOfDeath: dateOfDeath,
      causeOfDeath: causeOfDeath,
    );
  }
}

extension PersonFirstName on PersonProfile {
  /// What to call them in a greeting: the given name, or for older profiles
  /// the first word of the full name.
  String get firstName {
    final given = givenName?.trim();
    if (given != null && given.isNotEmpty) return given;
    final first = displayName.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? displayName : first;
  }
}

extension PersonAge on PersonProfile {
  /// Whole years, or null when the date of birth isn't known.
  int? get ageYears {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
