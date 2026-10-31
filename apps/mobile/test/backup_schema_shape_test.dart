// Guards the published backup format (docs/backup-format.md). If this fails,
// the shape of the backup document changed: decide whether it is a MINOR bump
// (a new optional field or table) or a MAJOR one (anything an older reader
// can't understand), change VaultBackup.schemaVersion, add a row to the
// history table in the docs, then update this expectation to match.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/backup/vault_backup.dart';
import 'package:amrutham/model/care_provider.dart';
import 'package:amrutham/model/certainty.dart';
import 'package:amrutham/model/dose_log.dart';
import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/health_record.dart';
import 'package:amrutham/model/history_event.dart';
import 'package:amrutham/model/measurement.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/model/schedule_phase.dart';
import 'package:amrutham/repository/care_team_repository.dart';
import 'package:amrutham/repository/dose_log_repository.dart';
import 'package:amrutham/repository/expense_repository.dart';
import 'package:amrutham/repository/history_repository.dart';
import 'package:amrutham/repository/measurement_repository.dart';
import 'package:amrutham/repository/medication_repository.dart';
import 'package:amrutham/repository/profile_repository.dart';
import 'package:amrutham/repository/record_repository.dart';

import 'realm_test_helper.dart';

/// The keys of each part of the document, for [VaultBackup.schemaVersion].
const _shapeOf_1_0_0 = <String, List<String>>{
  '(top level)': [
    'allergies', 'careTeam', 'courses', 'createdAt', 'doseLogs', 'expenses',
    'familyHistory', 'history', 'measurements', 'people', 'phases', 'receipts',
    'records', 'schemaVersion', 'version',
  ],
  'people': [
    'bloodGroup', 'causeOfDeath', 'createdAt', 'dateOfBirth', 'dateOfDeath',
    'displayName', 'emergencyContacts', 'givenName', 'id', 'isDeceased',
    'relationship', 'sex', 'surname',
  ],
  'emergencyContacts': ['name', 'phone', 'relationship'],
  'familyHistory': [
    'certainty', 'conditionCode', 'conditionText', 'id', 'notes',
    'onsetAgeApprox', 'outcome', 'personId', 'relationship',
  ],
  'allergies': ['certainty', 'id', 'notes', 'personId', 'reaction', 'severity', 'substance'],
  'courses': [
    'endDate', 'id', 'medicationName', 'personId', 'prescriberName', 'reason',
    'startDate', 'status',
  ],
  'phases': [
    'conflictGroupId', 'courseId', 'daysOfWeek', 'doseAmount', 'frequency', 'id',
    'isPrn', 'period', 'periodUnit', 'phaseEnd', 'phaseStart', 'prnMaxFrequency',
    'prnReason', 'timesOfDay',
  ],
  'measurements': ['id', 'kind', 'measuredAt', 'note', 'personId', 'value', 'value2'],
  'history': ['eventDate', 'id', 'kind', 'notes', 'personId', 'provider', 'title'],
  'doseLogs': ['courseId', 'id', 'loggedAt', 'personId', 'scheduledAt', 'status'],
  'careTeam': [
    'id', 'isCurrent', 'kind', 'location', 'name', 'personIds', 'phone',
    'specialty', 'worksAt',
  ],
  'expenses': [
    'addedAt', 'amountPaise', 'category', 'id', 'paidBy', 'payee', 'personId',
    'spentOn', 'title',
  ],
  'records': ['addedAt', 'files', 'id', 'personId', 'recordDate', 'source', 'title', 'type'],
  'record files': ['data', 'path'],
  'receipts': ['data', 'path'],
};

void main() {
  test('the backup document still has the shape published for its schemaVersion', () async {
    expect(
      VaultBackup.schemaVersion,
      '1.0.0',
      reason: 'schemaVersion changed: add its shape here as a new constant and '
          'compare against that one (keep the old one for the old version).',
    );

    final tmp = await Directory.systemTemp.createTemp('shape-');
    addTearDown(() => tmp.delete(recursive: true));
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final vault = Directory('${tmp.path}/vault');

    final profiles = ProfileRepository(realm);
    final who = await profiles.createProfile(
      displayName: 'A B',
      givenName: 'A',
      surname: 'B',
      relationship: RelationshipType.self,
      emergencyContacts: const [EmergencyContact(name: 'C', phone: '1')],
    );
    await profiles.addFamilyHistoryEntry(
      personId: who.id, relationship: 'Father', conditionText: 'X', certainty: Certainty.reported,
    );
    await profiles.addAllergyRecord(
      personId: who.id, substance: 'S', reaction: 'R', certainty: Certainty.reported,
    );
    final meds = MedicationRepository(realm);
    final course = await meds.createCourse(
      personId: who.id, medicationName: 'M', status: CourseStatus.active, startDate: DateTime(2025),
    );
    await meds.addSchedulePhase(
      courseId: course.id, doseAmount: '1', frequency: 1, period: 1, periodUnit: PeriodUnit.day,
      timesOfDay: ['08:00'], phaseStart: DateTime(2025),
    );
    await MeasurementRepository(realm).addMeasurement(
      personId: who.id, kind: MeasurementKind.weight, value: 60, measuredAt: DateTime(2025),
    );
    await HistoryRepository(realm).addEvent(
      personId: who.id, kind: HistoryKind.visit, title: 'V', eventDate: DateTime(2025),
    );
    await DoseLogRepository(realm).logDose(
      personId: who.id, courseId: course.id, scheduledAt: DateTime(2025), status: DoseStatus.taken,
    );
    await CareTeamRepository(realm).add(kind: CareKind.doctor, name: 'D', personIds: [who.id]);
    final photo = File('${tmp.path}/p.jpg')..writeAsBytesSync([1]);
    await ExpenseRepository(realm, vault).add(
      personId: who.id, title: 'E', amountPaise: 100, category: ExpenseCategory.other,
      spentOn: DateTime(2025), receipt: photo,
    );
    await RecordRepository(realm, vault).add(
      personId: who.id, type: RecordType.bill, title: 'R', recordDate: DateTime(2025), sources: [photo],
    );

    final data = await VaultBackup.snapshot(realm, vault);

    List<String> keys(Object? m) => ((m as Map).keys.cast<String>().toList())..sort();
    Object? first(String k) => (data[k] as List).single;
    final actual = <String, List<String>>{
      '(top level)': keys(data),
      'people': keys(first('people')),
      'emergencyContacts': keys(((first('people') as Map)['emergencyContacts'] as List).single),
      'familyHistory': keys(first('familyHistory')),
      'allergies': keys(first('allergies')),
      'courses': keys(first('courses')),
      'phases': keys(first('phases')),
      'measurements': keys(first('measurements')),
      'history': keys(first('history')),
      'doseLogs': keys(first('doseLogs')),
      'careTeam': keys(first('careTeam')),
      'expenses': keys(first('expenses')),
      'records': keys(first('records')),
      'record files': keys(((first('records') as Map)['files'] as List).single),
      'receipts': keys(first('receipts')),
    };

    expect(actual.keys, _shapeOf_1_0_0.keys);
    for (final part in _shapeOf_1_0_0.keys) {
      expect(actual[part], _shapeOf_1_0_0[part], reason: 'shape of "$part" changed; bump schemaVersion');
    }
  });
}
