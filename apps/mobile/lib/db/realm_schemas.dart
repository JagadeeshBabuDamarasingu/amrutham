import 'package:realm/realm.dart';

part 'realm_schemas.realm.dart';

/// The DB is a rebuildable cache, not the source of truth (the plain-files
/// vault, built in M5, is). See specs/phase-1-v1/02-architecture.md §4.
///
/// Every generated class here is named `*Row` (matching the previous drift
/// convention) precisely so it never collides with the domain-model classes
/// of the same name in model/ — the repository layer converts to/from these,
/// UI and the rest of the app never sees a `*Row` type. See
/// repository/profile_repository.dart and repository/medication_repository.dart.

@RealmModel(ObjectType.embeddedObject)
class _EmergencyContactRow {
  late String name;
  late String phone;
  String? relationship;
}

@RealmModel()
class _PersonRow {
  @PrimaryKey()
  late String id;
  late String displayName;
  late String relationship;
  DateTime? dateOfBirth;
  String? sex;
  String? bloodGroup;
  late List<_EmergencyContactRow> emergencyContacts;
  late DateTime createdAt;
}

@RealmModel()
class _FamilyHistoryEntryRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String relationship;
  late String conditionText;
  String? conditionCode;
  int? onsetAgeApprox;
  String? outcome;
  late String certainty;
  String? notes;
}

@RealmModel()
class _AllergyRecordRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String substance;
  late String reaction;
  String? severity;
  late String certainty;
  String? notes;
}

@RealmModel()
class _MedicationCourseRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String medicationName;
  late String status;
  late DateTime startDate;
  DateTime? endDate;
  String? prescriberName;
  String? reason;
}

/// `isPrn` defaults to false and `daysOfWeek`/`timesOfDay` default to empty
/// lists, matching the drift schema's `NOT NULL DEFAULT 0` / always-present
/// list columns. `conflictGroupId` is reserved for phase 2's sync conflict
/// rule; always null in phase 1 — see
/// specs/phase-1-v1/02-architecture.md §6's conflict rule.
@RealmModel()
class _SchedulePhaseRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String courseId;
  late String doseAmount;
  late int frequency;
  late int period;
  late String periodUnit;
  late List<int> daysOfWeek;
  late List<String> timesOfDay;
  late bool isPrn = false;
  String? prnReason;
  String? prnMaxFrequency;
  late DateTime phaseStart;
  DateTime? phaseEnd;
  String? conflictGroupId;
}
