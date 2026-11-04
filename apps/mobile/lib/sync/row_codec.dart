import 'package:realm/realm.dart';

import '../db/realm_schemas.dart';

/// One synced table row from its backup JSON. Shared by restore and family
/// sync, so the two can never disagree about what a row looks like.
RealmObject rowFromJson(String table, Map<String, dynamic> x) {
  DateTime t(Object? v) => DateTime.parse(v as String).toLocal();
  DateTime? to(Object? v) => v == null ? null : t(v);
  switch (table) {
    case 'people':
      return PersonRow(
        x['id'] as String,
        x['displayName'] as String,
        x['relationship'] as String,
        t(x['createdAt']),
        givenName: x['givenName'] as String?,
        surname: x['surname'] as String?,
        dateOfBirth: to(x['dateOfBirth']),
        sex: x['sex'] as String?,
        bloodGroup: x['bloodGroup'] as String?,
        pregnant: x['pregnant'] as bool? ?? false,
        pregnancyDue: to(x['pregnancyDue']),
        isDeceased: x['isDeceased'] as bool? ?? false,
        dateOfDeath: to(x['dateOfDeath']),
        causeOfDeath: x['causeOfDeath'] as String?,
        emergencyContacts: [
          for (final c
              in (x['emergencyContacts'] as List).cast<Map<String, dynamic>>())
            EmergencyContactRow(
              c['name'] as String,
              c['phone'] as String,
              relationship: c['relationship'] as String?,
            ),
        ],
      );
    case 'familyHistory':
      return FamilyHistoryEntryRow(
        x['id'] as String,
        x['personId'] as String,
        x['relationship'] as String,
        x['conditionText'] as String,
        x['certainty'] as String,
        conditionCode: x['conditionCode'] as String?,
        onsetAgeApprox: x['onsetAgeApprox'] as int?,
        outcome: x['outcome'] as String?,
        notes: x['notes'] as String?,
      );
    case 'allergies':
      return AllergyRecordRow(
        x['id'] as String,
        x['personId'] as String,
        x['substance'] as String,
        x['reaction'] as String,
        x['certainty'] as String,
        severity: x['severity'] as String?,
        notes: x['notes'] as String?,
      );
    case 'courses':
      return MedicationCourseRow(
        x['id'] as String,
        x['personId'] as String,
        x['medicationName'] as String,
        x['status'] as String,
        t(x['startDate']),
        endDate: to(x['endDate']),
        prescriberName: x['prescriberName'] as String?,
        reason: x['reason'] as String?,
      );
    case 'phases':
      return SchedulePhaseRow(
        x['id'] as String,
        x['courseId'] as String,
        x['doseAmount'] as String,
        x['frequency'] as int,
        x['period'] as int,
        x['periodUnit'] as String,
        t(x['phaseStart']),
        daysOfWeek: (x['daysOfWeek'] as List).cast<int>(),
        timesOfDay: (x['timesOfDay'] as List).cast<String>(),
        isPrn: x['isPrn'] as bool,
        prnReason: x['prnReason'] as String?,
        prnMaxFrequency: x['prnMaxFrequency'] as String?,
        phaseEnd: to(x['phaseEnd']),
        conflictGroupId: x['conflictGroupId'] as String?,
      );
    case 'measurements':
      return MeasurementRow(
        x['id'] as String,
        x['personId'] as String,
        x['kind'] as String,
        (x['value'] as num).toDouble(),
        t(x['measuredAt']),
        value2: (x['value2'] as num?)?.toDouble(),
        note: x['note'] as String?,
      );
    case 'history':
      return HistoryEventRow(
        x['id'] as String,
        x['personId'] as String,
        x['kind'] as String,
        x['title'] as String,
        t(x['eventDate']),
        provider: x['provider'] as String?,
        notes: x['notes'] as String?,
      );
    case 'doseLogs':
      return DoseLogRow(
        x['id'] as String,
        x['personId'] as String,
        x['courseId'] as String,
        t(x['scheduledAt']),
        x['status'] as String,
        t(x['loggedAt']),
      );
    case 'careTeam':
      return CareProviderRow(
        x['id'] as String,
        x['kind'] as String,
        x['name'] as String,
        x['isCurrent'] as bool,
        specialty: x['specialty'] as String?,
        worksAt: x['worksAt'] as String?,
        phone: x['phone'] as String?,
        location: x['location'] as String?,
        personIds: (x['personIds'] as List).cast<String>(),
      );
    case 'expenses':
      return ExpenseRow(
        x['id'] as String,
        x['personId'] as String,
        x['title'] as String,
        x['amountPaise'] as int,
        x['category'] as String,
        t(x['spentOn']),
        t(x['addedAt']),
        payee: x['payee'] as String?,
        paidBy: x['paidBy'] as String?,
      );
  }
  throw ArgumentError('Not a synced table: $table');
}

/// Removes one row by id; nothing happens if it is already gone.
void deleteRowById(Realm realm, String table, String id) {
  void go<T extends RealmObject>() {
    final o = realm.find<T>(id);
    if (o != null) realm.delete(o);
  }

  switch (table) {
    case 'people':
      go<PersonRow>();
    case 'familyHistory':
      go<FamilyHistoryEntryRow>();
    case 'allergies':
      go<AllergyRecordRow>();
    case 'courses':
      go<MedicationCourseRow>();
    case 'phases':
      go<SchedulePhaseRow>();
    case 'measurements':
      go<MeasurementRow>();
    case 'history':
      go<HistoryEventRow>();
    case 'doseLogs':
      go<DoseLogRow>();
    case 'careTeam':
      go<CareProviderRow>();
    case 'expenses':
      go<ExpenseRow>();
  }
}
