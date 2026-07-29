// F2 acceptance: a course with a multi-phase taper round-trips through the
// repository layer. See specs/phase-1-v1/01-features.md F2.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// drift's auto-named `Table` subclasses collide with our own domain-model
// classes of the same name — see medication_repository.dart's import comment.
import 'package:amrutham/db/database.dart'
    hide EmergencyContact, MedicationCourse, SchedulePhase;
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/model/schedule_phase.dart';
import 'package:amrutham/repository/medication_repository.dart';
import 'package:amrutham/repository/profile_repository.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository profileRepository;
  late MedicationRepository medicationRepository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    profileRepository = ProfileRepository(db);
    medicationRepository = MedicationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('a course round-trips through the database', () async {
    final person = await profileRepository.createProfile(
      displayName: 'Lakshmi',
      relationship: RelationshipType.self,
    );

    final course = await medicationRepository.createCourse(
      personId: person.id,
      medicationName: 'Prednisolone',
      status: CourseStatus.active,
      startDate: DateTime(2026, 1, 1),
      prescriberName: 'Dr. Rao',
      reason: 'Asthma flare',
    );

    final courses = await medicationRepository
        .watchCoursesForPerson(person.id)
        .first;

    expect(courses, hasLength(1));
    expect(courses.single.id, course.id);
    expect(courses.single.medicationName, 'Prednisolone');
    expect(courses.single.prescriberName, 'Dr. Rao');
  });

  test('a 3-phase taper round-trips in start order', () async {
    final person = await profileRepository.createProfile(
      displayName: 'Amma',
      relationship: RelationshipType.parent,
    );
    final course = await medicationRepository.createCourse(
      personId: person.id,
      medicationName: 'Prednisolone',
      status: CourseStatus.active,
      startDate: DateTime(2026, 1, 1),
    );

    await medicationRepository.addSchedulePhase(
      courseId: course.id,
      doseAmount: '40mg',
      frequency: 1,
      period: 1,
      periodUnit: PeriodUnit.day,
      timesOfDay: const ['08:00'],
      phaseStart: DateTime(2026, 1, 1),
      phaseEnd: DateTime(2026, 1, 5),
    );
    await medicationRepository.addSchedulePhase(
      courseId: course.id,
      doseAmount: '20mg',
      frequency: 1,
      period: 1,
      periodUnit: PeriodUnit.day,
      timesOfDay: const ['08:00'],
      phaseStart: DateTime(2026, 1, 6),
      phaseEnd: DateTime(2026, 1, 10),
    );
    await medicationRepository.addSchedulePhase(
      courseId: course.id,
      doseAmount: '10mg',
      frequency: 1,
      period: 1,
      periodUnit: PeriodUnit.day,
      daysOfWeek: {1, 3, 5},
      timesOfDay: const ['08:00', '20:00'],
      phaseStart: DateTime(2026, 1, 11),
    );

    final phases = await medicationRepository
        .watchPhasesForCourse(course.id)
        .first;

    expect(phases, hasLength(3));
    expect(phases.map((p) => p.doseAmount), ['40mg', '20mg', '10mg']);
    expect(phases.last.daysOfWeek, {1, 3, 5});
    expect(phases.last.timesOfDay, ['08:00', '20:00']);
    expect(phases.last.phaseEnd, isNull);
  });

  test('updateCourseStatus changes the stored status', () async {
    final person = await profileRepository.createProfile(
      displayName: 'Ravi',
      relationship: RelationshipType.self,
    );
    final course = await medicationRepository.createCourse(
      personId: person.id,
      medicationName: 'Amoxicillin',
      status: CourseStatus.active,
      startDate: DateTime(2026, 1, 1),
    );

    await medicationRepository.updateCourseStatus(
      course.id,
      CourseStatus.completed,
    );

    final courses = await medicationRepository
        .watchCoursesForPerson(person.id)
        .first;
    expect(courses.single.status, CourseStatus.completed);
  });

  test('a PRN phase round-trips with no times of day', () async {
    final person = await profileRepository.createProfile(
      displayName: 'Ravi',
      relationship: RelationshipType.self,
    );
    final course = await medicationRepository.createCourse(
      personId: person.id,
      medicationName: 'Paracetamol',
      status: CourseStatus.active,
      startDate: DateTime(2026, 1, 1),
    );

    await medicationRepository.addSchedulePhase(
      courseId: course.id,
      doseAmount: '1 tablet',
      frequency: 1,
      period: 1,
      periodUnit: PeriodUnit.day,
      timesOfDay: const [],
      isPrn: true,
      prnReason: 'Fever',
      prnMaxFrequency: 'up to 3 times a day',
      phaseStart: DateTime(2026, 1, 1),
    );

    final phases = await medicationRepository
        .watchPhasesForCourse(course.id)
        .first;
    expect(phases.single.isPrn, isTrue);
    expect(phases.single.timesOfDay, isEmpty);
    expect(phases.single.prnMaxFrequency, 'up to 3 times a day');
  });
}
