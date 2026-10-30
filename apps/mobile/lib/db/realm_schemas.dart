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
  // Optional parts of displayName ("Given Surname"), kept so the app can greet
  // by given name. Null on profiles made before they were asked for.
  String? givenName;
  String? surname;
  late String relationship;
  DateTime? dateOfBirth;
  String? sex;
  String? bloodGroup;
  late List<_EmergencyContactRow> emergencyContacts;
  late DateTime createdAt;
  // A remembered family member: read-only, no reminders. The date can be
  // unknown, so "deceased" is its own flag rather than "date of death is set".
  bool isDeceased = false;
  DateTime? dateOfDeath;
  String? causeOfDeath;
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

/// A single reading (weight, blood pressure, sugar, ...). `value2` is only set
/// for kinds with a second number (blood pressure's diastolic). Stored exactly
/// as entered — nothing here interprets a value as normal or abnormal.
@RealmModel()
class _MeasurementRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String kind;
  late double value;
  double? value2;
  @Indexed()
  late DateTime measuredAt;
  String? note;
}

/// A dated event in someone's medical history: a visit, procedure or scan.
/// Medicine courses are already dated in MedicationCourseRow, so the timeline
/// merges those in rather than copying them here. A future `eventDate` means
/// the event is planned.
@RealmModel()
class _HistoryEventRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String kind;
  late String title;
  @Indexed()
  late DateTime eventDate;
  String? provider;
  String? notes;
}

/// The answer to "did you take it?" for one scheduled dose. The primary key is
/// courseId + scheduled time, so answering the same dose twice replaces the
/// first answer instead of double-counting. Logging only ever records what the
/// user said; nothing here is scored or turned into an adherence percentage.
@RealmModel()
class _DoseLogRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String courseId;
  @Indexed()
  late DateTime scheduledAt;
  late String status;
  late DateTime loggedAt;
}

/// A doctor or a hospital/clinic/lab the family consults. One entry can serve
/// several people (`personIds`), so a shared family doctor is entered once.
/// The phone number stays on this phone like everything else.
@RealmModel()
class _CareProviderRow {
  @PrimaryKey()
  late String id;
  late String kind; // 'doctor' | 'facility'
  late String name;
  String? specialty;
  String? worksAt;
  String? phone;
  String? location;
  late List<String> personIds;
  late bool isCurrent;
}

/// A medical expense. The amount is whole paise (an int), never a float, so
/// totals always add up exactly. A personal record only: nothing here is
/// submitted to an insurer.
@RealmModel()
class _ExpenseRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String title;
  String? payee;
  late int amountPaise;
  late String category;
  String? paidBy;
  @Indexed()
  late DateTime spentOn;
  late DateTime addedAt;
}

/// A filed document (prescription, lab report, scan, bill). The files
/// themselves are plain files under the vault folder; this row only remembers
/// where they are and what they are, so the folder stays readable without the
/// app. `files` are paths relative to the vault folder.
@RealmModel()
class _RecordRow {
  @PrimaryKey()
  late String id;
  @Indexed()
  late String personId;
  late String type;
  late String title;
  @Indexed()
  late DateTime recordDate;
  String? source;
  late List<String> files;
  late DateTime addedAt;
}
