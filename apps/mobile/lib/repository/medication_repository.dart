import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/ids.dart';
import '../model/medication.dart';
import '../model/schedule_phase.dart';

/// The only way UI code touches medication data — UI must never write to
/// db/ directly. See specs/phase-1-v1/02-architecture.md §1.
class MedicationRepository {
  final Realm _realm;

  MedicationRepository(this._realm);

  // ---- MedicationCourse ----

  Stream<List<MedicationCourse>> watchCoursesForPerson(PersonId personId) {
    return _realm
        .query<MedicationCourseRow>(r'personId == $0', [personId.value])
        .changes
        .map((c) => c.results.map(_courseFromRow).toList());
  }

  /// `medicationCoding` has no backing field this phase (not in
  /// specs/phase-1-v1/02-architecture.md §4's schema) — it's always empty
  /// when hydrated from the DB. The domain-model field exists for forward
  /// compatibility per the spec's DrugCode shape.
  MedicationCourse _courseFromRow(MedicationCourseRow row) {
    return MedicationCourse(
      id: MedicationCourseId(row.id),
      personId: PersonId(row.personId),
      medicationName: row.medicationName,
      status: CourseStatus.values.byName(row.status),
      startDate: row.startDate.toLocal(),
      endDate: row.endDate?.toLocal(),
      prescriberName: row.prescriberName,
      reason: row.reason,
    );
  }

  Future<MedicationCourse> createCourse({
    required PersonId personId,
    required String medicationName,
    required CourseStatus status,
    required DateTime startDate,
    DateTime? endDate,
    String? prescriberName,
    String? reason,
  }) async {
    final id = MedicationCourseId(Ulid().toString());
    _realm.write(() {
      _realm.add(
        MedicationCourseRow(
          id.value,
          personId.value,
          medicationName,
          status.name,
          startDate,
          endDate: endDate,
          prescriberName: prescriberName,
          reason: reason,
        ),
      );
    });
    return MedicationCourse(
      id: id,
      personId: personId,
      medicationName: medicationName,
      status: status,
      startDate: startDate,
      endDate: endDate,
      prescriberName: prescriberName,
      reason: reason,
    );
  }

  /// Edits the course's own details. Status has its own method; reminders must
  /// be re-armed by the caller afterwards.
  Future<void> updateCourse(
    MedicationCourseId courseId, {
    required String medicationName,
    required DateTime startDate,
    DateTime? endDate,
    String? prescriberName,
    String? reason,
  }) async {
    final row = _realm.find<MedicationCourseRow>(courseId.value);
    if (row == null) return;
    _realm.write(() {
      row
        ..medicationName = medicationName
        ..startDate = startDate
        ..endDate = endDate
        ..prescriberName = prescriberName
        ..reason = reason;
    });
  }

  /// Removes the course with its schedule phases and dose answers.
  Future<void> deleteCourse(MedicationCourseId courseId) async {
    _realm.write(() {
      _realm.deleteMany(
        _realm.query<SchedulePhaseRow>(r'courseId == $0', [courseId.value]),
      );
      _realm.deleteMany(
        _realm.query<DoseLogRow>(r'courseId == $0', [courseId.value]),
      );
      final row = _realm.find<MedicationCourseRow>(courseId.value);
      if (row != null) _realm.delete(row);
    });
  }

  Future<MedicationCourse?> courseById(MedicationCourseId courseId) async {
    final row = _realm.find<MedicationCourseRow>(courseId.value);
    return row == null ? null : _courseFromRow(row);
  }

  /// Changing a schedule always requires explicit local confirmation, never
  /// a silent background update — this is a direct user action from the UI,
  /// never called from a background task. See
  /// specs/phase-1-v1/01-features.md F2's acceptance criteria.
  Future<void> updateCourseStatus(
    MedicationCourseId courseId,
    CourseStatus status,
  ) async {
    final row = _realm.find<MedicationCourseRow>(courseId.value);
    if (row == null) return;
    _realm.write(() {
      row.status = status.name;
    });
  }

  // ---- SchedulePhase ----

  Stream<List<SchedulePhase>> watchPhasesForCourse(
    MedicationCourseId courseId,
  ) {
    return _realm
        .query<SchedulePhaseRow>(
          r'courseId == $0 SORT(phaseStart ASC)',
          [courseId.value],
        )
        .changes
        .map((c) => c.results.map(_phaseFromRow).toList());
  }

  SchedulePhase _phaseFromRow(SchedulePhaseRow row) {
    return SchedulePhase(
      id: SchedulePhaseId(row.id),
      courseId: MedicationCourseId(row.courseId),
      doseAmount: row.doseAmount,
      frequency: row.frequency,
      period: row.period,
      periodUnit: PeriodUnit.values.byName(row.periodUnit),
      daysOfWeek: row.daysOfWeek.isEmpty ? null : row.daysOfWeek.toSet(),
      timesOfDay: row.timesOfDay.toList(),
      isPrn: row.isPrn,
      prnReason: row.prnReason,
      prnMaxFrequency: row.prnMaxFrequency,
      phaseStart: row.phaseStart.toLocal(),
      phaseEnd: row.phaseEnd?.toLocal(),
    );
  }

  Future<SchedulePhase> addSchedulePhase({
    required MedicationCourseId courseId,
    required String doseAmount,
    required int frequency,
    required int period,
    required PeriodUnit periodUnit,
    Set<int>? daysOfWeek,
    required List<String> timesOfDay,
    bool isPrn = false,
    String? prnReason,
    String? prnMaxFrequency,
    required DateTime phaseStart,
    DateTime? phaseEnd,
  }) async {
    final id = SchedulePhaseId(Ulid().toString());
    _realm.write(() {
      _realm.add(
        SchedulePhaseRow(
          id.value,
          courseId.value,
          doseAmount,
          frequency,
          period,
          periodUnit.name,
          phaseStart,
          daysOfWeek: daysOfWeek == null ? const [] : (daysOfWeek.toList()..sort()),
          timesOfDay: timesOfDay,
          isPrn: isPrn,
          prnReason: prnReason,
          prnMaxFrequency: prnMaxFrequency,
          phaseEnd: phaseEnd,
        ),
      );
    });
    return SchedulePhase(
      id: id,
      courseId: courseId,
      doseAmount: doseAmount,
      frequency: frequency,
      period: period,
      periodUnit: periodUnit,
      daysOfWeek: daysOfWeek,
      timesOfDay: timesOfDay,
      isPrn: isPrn,
      prnReason: prnReason,
      prnMaxFrequency: prnMaxFrequency,
      phaseStart: phaseStart,
      phaseEnd: phaseEnd,
    );
  }

  Future<void> updateSchedulePhase(
    SchedulePhaseId id, {
    required String doseAmount,
    required int frequency,
    required int period,
    required PeriodUnit periodUnit,
    Set<int>? daysOfWeek,
    required List<String> timesOfDay,
    bool isPrn = false,
    String? prnReason,
    String? prnMaxFrequency,
    required DateTime phaseStart,
    DateTime? phaseEnd,
  }) async {
    final row = _realm.find<SchedulePhaseRow>(id.value);
    if (row == null) return;
    _realm.write(() {
      row
        ..doseAmount = doseAmount
        ..frequency = frequency
        ..period = period
        ..periodUnit = periodUnit.name
        ..isPrn = isPrn
        ..prnReason = prnReason
        ..prnMaxFrequency = prnMaxFrequency
        ..phaseStart = phaseStart
        ..phaseEnd = phaseEnd;
      row.daysOfWeek
        ..clear()
        ..addAll(daysOfWeek == null ? const <int>[] : (daysOfWeek.toList()..sort()));
      row.timesOfDay
        ..clear()
        ..addAll(timesOfDay);
    });
  }

  Future<void> deleteSchedulePhase(SchedulePhaseId id) async {
    final row = _realm.find<SchedulePhaseRow>(id.value);
    if (row != null) _realm.write(() => _realm.delete(row));
  }

  /// The only query the reminder engine is allowed to read from. Excludes:
  /// - phases of a non-active course (completed/stopped/paused)
  /// - PRN phases (a max-frequency ceiling is never a fixed reminder
  ///   cadence — see specs/phase-1-v1/01-features.md F2)
  /// - phases outside their own start/end range (a taper's earlier/later
  ///   phases must not both fire)
  /// - conflicted phases (`conflictGroupId != null`) — always null in
  ///   phase 1, but the query must already respect it per
  ///   specs/phase-1-v1/02-architecture.md §6's conflict rule.
  ///
  /// Realm has no cross-table join, so this is a two-step query: active
  /// course ids for the person, then phases whose courseId is in that set.
  Future<List<SchedulePhase>> activeNonConflictedPhasesForPerson(
    PersonId personId,
  ) async {
    final activeCourseIds = _realm
        .query<MedicationCourseRow>(
          r'personId == $0 AND status == $1',
          [personId.value, CourseStatus.active.name],
        )
        .map((c) => c.id)
        .toList();
    if (activeCourseIds.isEmpty) return [];

    final rows = _realm.query<SchedulePhaseRow>(
      r'courseId IN $0 AND isPrn == false AND conflictGroupId == nil',
      [activeCourseIds],
    );

    final now = DateTime.now();
    return rows
        .map(_phaseFromRow)
        .where(
          (phase) =>
              !phase.phaseStart.isAfter(now) &&
              (phase.phaseEnd == null || !phase.phaseEnd!.isBefore(now)),
        )
        .toList();
  }

  /// Every phase for a person regardless of course status/PRN/conflict —
  /// used only by ReminderRepository to sweep-cancel stale notifications
  /// before a re-arm. Never used to decide what to schedule; see
  /// activeNonConflictedPhasesForPerson for that.
  Future<List<SchedulePhase>> allPhasesForPerson(PersonId personId) async {
    final courseIds = _realm
        .query<MedicationCourseRow>(r'personId == $0', [personId.value])
        .map((c) => c.id)
        .toList();
    if (courseIds.isEmpty) return [];

    final rows = _realm.query<SchedulePhaseRow>(
      r'courseId IN $0',
      [courseIds],
    );
    return rows.map(_phaseFromRow).toList();
  }
}
