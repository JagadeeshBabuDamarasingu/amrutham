// Editing saved entries: every update replaces what changed and keeps the id,
// and the new deletes remove only their own entry.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';

import 'package:amrutham/db/realm_schemas.dart';
import 'package:amrutham/model/certainty.dart';
import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/health_record.dart';
import 'package:amrutham/model/history_event.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/measurement.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/model/schedule_phase.dart';
import 'package:amrutham/repository/expense_repository.dart';
import 'package:amrutham/repository/history_repository.dart';
import 'package:amrutham/repository/measurement_repository.dart';
import 'package:amrutham/repository/medication_repository.dart';
import 'package:amrutham/repository/profile_repository.dart';
import 'package:amrutham/repository/record_repository.dart';

import 'realm_test_helper.dart';

void main() {
  late Realm realm;
  late PersonId who;

  setUp(() async {
    realm = openInMemoryRealm();
    who = (await ProfileRepository(realm).createProfile(
      displayName: 'Lakshmi',
      relationship: RelationshipType.self,
    )).id;
  });
  tearDown(() => realm.close());

  test('a profile can be renamed and marked deceased', () async {
    final repo = ProfileRepository(realm);
    await repo.updateProfile(
      who,
      displayName: 'Lakshmi Rao',
      givenName: 'Lakshmi',
      surname: 'Rao',
      relationship: RelationshipType.parent,
      dateOfBirth: DateTime(1950, 3, 4),
      sex: 'Female',
      bloodGroup: 'O positive',
      isDeceased: true,
      dateOfDeath: DateTime(2020, 1, 2),
      causeOfDeath: 'Old age',
    );
    final p = (await repo.watchProfiles().first).single;
    expect(p.id, who);
    expect(p.displayName, 'Lakshmi Rao');
    expect(p.surname, 'Rao');
    expect(p.relationship, RelationshipType.parent);
    expect(p.bloodGroup, 'O positive');
    expect(p.isDeceased, isTrue);
    expect(p.causeOfDeath, 'Old age');
  });

  test('allergies and family history can be edited and deleted', () async {
    final repo = ProfileRepository(realm);
    final a = await repo.addAllergyRecord(
      personId: who, substance: 'Penicillin', reaction: 'Rash', certainty: Certainty.reported,
    );
    final keep = await repo.addAllergyRecord(
      personId: who, substance: 'Dust', reaction: 'Sneezing', certainty: Certainty.suspected,
    );
    await repo.updateAllergyRecord(
      a.id, substance: 'Amoxicillin', reaction: 'Hives', severity: 'Mild', certainty: Certainty.confirmed,
    );
    var list = await repo.watchAllergies(who).first;
    final edited = list.firstWhere((x) => x.id == a.id);
    expect(edited.substance, 'Amoxicillin');
    expect(edited.severity, 'Mild');
    expect(edited.certainty, Certainty.confirmed);
    await repo.deleteAllergyRecord(a.id);
    list = await repo.watchAllergies(who).first;
    expect(list.map((x) => x.id), [keep.id]);

    final f = await repo.addFamilyHistoryEntry(
      personId: who, relationship: 'Father', conditionText: 'Diabetes', certainty: Certainty.reported,
    );
    await repo.updateFamilyHistoryEntry(
      f.id,
      relationship: 'Grandfather',
      conditionText: 'Type 2 diabetes',
      onsetAgeApprox: 55,
      outcome: 'Managed',
      certainty: Certainty.confirmed,
    );
    final fh = (await repo.watchFamilyHistory(who).first).single;
    expect(fh.relationship, 'Grandfather');
    expect(fh.onsetAgeApprox, 55);
    await repo.deleteFamilyHistoryEntry(f.id);
    expect(await repo.watchFamilyHistory(who).first, isEmpty);
  });

  test('a history event can be edited', () async {
    final repo = HistoryRepository(realm);
    final e = await repo.addEvent(
      personId: who, kind: HistoryKind.visit, title: 'Checkup', eventDate: DateTime(2025, 1, 1),
    );
    await repo.updateEvent(
      e.id, kind: HistoryKind.scan, title: 'Chest X-ray', eventDate: DateTime(2025, 2, 3), provider: 'City Lab', notes: 'Clear',
    );
    final got = (await repo.watchEvents(who).first).single;
    expect(got.id, e.id);
    expect(got.kind, HistoryKind.scan);
    expect(got.title, 'Chest X-ray');
    expect(got.provider, 'City Lab');
  });

  test('a reading can be edited, and the second value drops with its kind', () async {
    final repo = MeasurementRepository(realm);
    final m = await repo.addMeasurement(
      personId: who, kind: MeasurementKind.bloodPressure, value: 120, value2: 80, measuredAt: DateTime(2025, 1, 1),
    );
    await repo.updateMeasurement(m.id, kind: MeasurementKind.bloodPressure, value: 130, value2: 85, measuredAt: DateTime(2025, 1, 2));
    var row = realm.find<MeasurementRow>(m.id.value)!;
    expect([row.value, row.value2], [130, 85]);
    await repo.updateMeasurement(m.id, kind: MeasurementKind.weight, value: 61.5, value2: 99, measuredAt: DateTime(2025, 1, 2));
    row = realm.find<MeasurementRow>(m.id.value)!;
    expect(row.kind, 'weight');
    expect(row.value2, isNull);
  });

  test('an expense can be edited, including its receipt', () async {
    final dir = await Directory.systemTemp.createTemp('expense_edit');
    addTearDown(() => dir.delete(recursive: true));
    final repo = ExpenseRepository(realm, dir);
    final first = File('${dir.path}/a.jpg')..writeAsBytesSync([1]);
    final second = File('${dir.path}/b.jpg')..writeAsBytesSync([2, 2]);
    final e = await repo.add(
      personId: who, title: 'Visit', amountPaise: 50000, category: ExpenseCategory.consultation,
      spentOn: DateTime(2025, 1, 1), receipt: first,
    );
    await repo.update(
      e.id,
      personId: who,
      title: 'Blood tests',
      payee: 'City Lab',
      amountPaise: 123450,
      category: ExpenseCategory.tests,
      paidBy: 'UPI',
      spentOn: DateTime(2025, 1, 5),
      receipt: second,
    );
    final got = (await repo.watchAll().first).single;
    expect(got.title, 'Blood tests');
    expect(got.amountPaise, 123450);
    expect(got.category, ExpenseCategory.tests);
    expect(repo.receiptFor(e.id)!.readAsBytesSync(), [2, 2]);

    // No new photo keeps the old one.
    await repo.update(e.id, personId: who, title: 'Blood tests', amountPaise: 123450,
        category: ExpenseCategory.tests, spentOn: DateTime(2025, 1, 5));
    expect(repo.receiptFor(e.id)!.readAsBytesSync(), [2, 2]);
  });

  test('a medicine and its schedule can be edited; deleting removes both', () async {
    final repo = MedicationRepository(realm);
    final c = await repo.createCourse(
      personId: who, medicationName: 'Metformin', status: CourseStatus.active, startDate: DateTime(2025, 1, 1),
    );
    final other = await repo.createCourse(
      personId: who, medicationName: 'Vitamin D', status: CourseStatus.active, startDate: DateTime(2025, 1, 1),
    );
    final ph = await repo.addSchedulePhase(
      courseId: c.id, doseAmount: '500 mg', frequency: 1, period: 1, periodUnit: PeriodUnit.day,
      timesOfDay: ['08:00'], phaseStart: DateTime(2025, 1, 1),
    );
    await repo.addSchedulePhase(
      courseId: other.id, doseAmount: '1 tab', frequency: 1, period: 1, periodUnit: PeriodUnit.day,
      timesOfDay: ['09:00'], phaseStart: DateTime(2025, 1, 1),
    );

    await repo.updateCourse(
      c.id, medicationName: 'Metformin 500', startDate: DateTime(2025, 1, 2), endDate: DateTime(2025, 6, 1),
      prescriberName: 'Dr. Iyer', reason: 'Sugar',
    );
    final course = (await repo.courseById(c.id))!;
    expect(course.medicationName, 'Metformin 500');
    expect(course.endDate, isNotNull);
    expect(course.reason, 'Sugar');

    await repo.updateSchedulePhase(
      ph.id, doseAmount: '850 mg', frequency: 2, period: 1, periodUnit: PeriodUnit.day,
      daysOfWeek: {1, 3}, timesOfDay: ['08:00', '20:00'], phaseStart: DateTime(2025, 1, 2),
    );
    final phase = (await repo.watchPhasesForCourse(c.id).first).single;
    expect(phase.doseAmount, '850 mg');
    expect(phase.timesOfDay, ['08:00', '20:00']);
    expect(phase.daysOfWeek, {1, 3});

    await repo.deleteSchedulePhase(ph.id);
    expect(await repo.watchPhasesForCourse(c.id).first, isEmpty);

    await repo.deleteCourse(c.id);
    expect(await repo.courseById(c.id), isNull);
    expect(await repo.courseById(other.id), isNotNull);
    expect(realm.all<SchedulePhaseRow>().length, 1); // the other medicine's
  });

  test('a record keeps its files when its details change', () async {
    final dir = await Directory.systemTemp.createTemp('record_edit');
    addTearDown(() => dir.delete(recursive: true));
    final repo = RecordRepository(realm, dir);
    final src = File('${dir.path}/scan.jpg')..writeAsBytesSync([9]);
    final r = await repo.add(
      personId: who, type: RecordType.prescription, title: 'Old', recordDate: DateTime(2025, 1, 1), sources: [src],
    );
    await repo.update(r.id, type: RecordType.labReport, title: 'New', recordDate: DateTime(2025, 2, 2), source: 'City Lab');
    final row = realm.find<RecordRow>(r.id.value)!;
    expect(row.type, 'labReport');
    expect(row.title, 'New');
    expect(row.source, 'City Lab');
    expect(row.files.toList(), r.files);
  });
}
