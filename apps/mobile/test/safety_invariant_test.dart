// Draft-cannot-feed-a-reminder / conflict-exclusion guarantees. Written now
// even though phase 1 has no drafts yet, so the invariant is locked in
// before phase 2 introduces DraftExtraction. See
// specs/phase-1-v1/02-architecture.md §11.

import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';

import 'package:amrutham/db/realm_schemas.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/model/schedule_phase.dart';
import 'package:amrutham/repository/medication_repository.dart';
import 'package:amrutham/repository/profile_repository.dart';

import 'realm_test_helper.dart';

void main() {
  late Realm realm;
  late ProfileRepository profileRepository;
  late MedicationRepository medicationRepository;

  setUp(() {
    realm = openInMemoryRealm();
    profileRepository = ProfileRepository(realm);
    medicationRepository = MedicationRepository(realm);
  });

  tearDown(() {
    realm.close();
  });

  test(
    'the reminder-arming query reads a confirmed schedule_phase row written '
    'through the repository',
    () async {
      final person = await profileRepository.createProfile(
        displayName: 'Amma',
        relationship: RelationshipType.parent,
      );
      final course = await medicationRepository.createCourse(
        personId: person.id,
        medicationName: 'Metformin',
        status: CourseStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final phase = await medicationRepository.addSchedulePhase(
        courseId: course.id,
        doseAmount: '1 tablet',
        frequency: 1,
        period: 1,
        periodUnit: PeriodUnit.day,
        timesOfDay: const ['08:00'],
        phaseStart: DateTime.now().subtract(const Duration(days: 1)),
      );

      final armable = await medicationRepository
          .activeNonConflictedPhasesForPerson(person.id);

      expect(armable, hasLength(1));
      expect(armable.single.id, phase.id);
    },
  );

  test(
    'a schedule_phase row with a non-null conflict_group_id is excluded '
    'from arming, even though no phase-1 code path can create one',
    () async {
      final person = await profileRepository.createProfile(
        displayName: 'Appa',
        relationship: RelationshipType.parent,
      );
      final course = await medicationRepository.createCourse(
        personId: person.id,
        medicationName: 'Amlodipine',
        status: CourseStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      // Simulates a divergent row phase-2 sync would eventually write —
      // inserted directly at the Realm layer since MedicationRepository
      // exposes no way to set this field. The query must already respect
      // it. See specs/phase-1-v1/02-architecture.md §6's conflict rule.
      realm.write(() {
        realm.add(
          SchedulePhaseRow(
            'conflicted-phase',
            course.id.value,
            '1 tablet',
            1,
            1,
            PeriodUnit.day.name,
            DateTime.now().subtract(const Duration(days: 1)),
            timesOfDay: const ['08:00'],
            conflictGroupId: 'conflict-group-1',
          ),
        );
      });

      final armable = await medicationRepository
          .activeNonConflictedPhasesForPerson(person.id);

      expect(armable, isEmpty);
    },
  );

  test(
    'a PRN phase never produces an armable reminder — a max-frequency '
    'ceiling is never a fixed reminder cadence',
    () async {
      final person = await profileRepository.createProfile(
        displayName: 'Ravi',
        relationship: RelationshipType.self,
      );
      final course = await medicationRepository.createCourse(
        personId: person.id,
        medicationName: 'Paracetamol',
        status: CourseStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await medicationRepository.addSchedulePhase(
        courseId: course.id,
        doseAmount: '1 tablet',
        frequency: 1,
        period: 1,
        periodUnit: PeriodUnit.day,
        timesOfDay: const [],
        isPrn: true,
        prnMaxFrequency: 'up to 3 times a day',
        phaseStart: DateTime.now().subtract(const Duration(days: 1)),
      );

      final armable = await medicationRepository
          .activeNonConflictedPhasesForPerson(person.id);

      expect(armable, isEmpty);
    },
  );

  test(
    'a phase belonging to a non-active course is excluded from arming',
    () async {
      final person = await profileRepository.createProfile(
        displayName: 'Lakshmi',
        relationship: RelationshipType.self,
      );
      final course = await medicationRepository.createCourse(
        personId: person.id,
        medicationName: 'Old antibiotic course',
        status: CourseStatus.completed,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      await medicationRepository.addSchedulePhase(
        courseId: course.id,
        doseAmount: '1 tablet',
        frequency: 1,
        period: 1,
        periodUnit: PeriodUnit.day,
        timesOfDay: const ['08:00'],
        phaseStart: DateTime.now().subtract(const Duration(days: 10)),
      );

      final armable = await medicationRepository
          .activeNonConflictedPhasesForPerson(person.id);

      expect(armable, isEmpty);
    },
  );
}
