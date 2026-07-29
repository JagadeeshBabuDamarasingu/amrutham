import 'package:drift/drift.dart';
import 'package:ulid/ulid.dart';

// drift generates a `Table` subclass named after each SQL table (e.g.
// `medication_course` -> `MedicationCourse`), separate from and in addition
// to the `AS ...Row` data class — that Table class isn't renameable from
// .drift files and collides with our own domain-model classes of the same
// name. We never reference it directly (only via `_db.medicationCourse`
// etc.), so hiding it is safe.
import '../db/database.dart' hide MedicationCourse, SchedulePhase;
import '../model/ids.dart';
import '../model/medication.dart';
import '../model/schedule_phase.dart';

/// The only way UI code touches medication data — UI must never write to
/// db/ directly. See specs/phase-1-v1/02-architecture.md §1.
class MedicationRepository {
  final AppDatabase _db;

  MedicationRepository(this._db);

  // ---- MedicationCourse ----

  Stream<List<MedicationCourse>> watchCoursesForPerson(PersonId personId) {
    return (_db.select(
      _db.medicationCourse,
    )..where((t) => t.personId.equals(personId.value))).watch().map(
      (rows) => rows.map(_courseFromRow).toList(),
    );
  }

  /// `medicationCoding` has no backing table this phase (not in
  /// specs/phase-1-v1/02-architecture.md §4's schema) — it's always empty
  /// when hydrated from the DB. The domain-model field exists for forward
  /// compatibility per the spec's DrugCode shape.
  MedicationCourse _courseFromRow(MedicationCourseRow row) {
    return MedicationCourse(
      id: MedicationCourseId(row.id),
      personId: PersonId(row.personId),
      medicationName: row.medicationName,
      status: CourseStatus.values.byName(row.status),
      startDate: DateTime.parse(row.startDate),
      endDate: row.endDate == null ? null : DateTime.parse(row.endDate!),
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
    await _db
        .into(_db.medicationCourse)
        .insert(
          MedicationCourseCompanion.insert(
            id: id.value,
            personId: personId.value,
            medicationName: medicationName,
            status: status.name,
            startDate: startDate.toIso8601String(),
            endDate: Value(endDate?.toIso8601String()),
            prescriberName: Value(prescriberName),
            reason: Value(reason),
          ),
        );
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

  Future<MedicationCourse?> courseById(MedicationCourseId courseId) async {
    final row =
        await (_db.select(
          _db.medicationCourse,
        )..where((t) => t.id.equals(courseId.value))).getSingleOrNull();
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
    await (_db.update(
      _db.medicationCourse,
    )..where((t) => t.id.equals(courseId.value))).write(
      MedicationCourseCompanion(status: Value(status.name)),
    );
  }

  // ---- SchedulePhase ----

  Stream<List<SchedulePhase>> watchPhasesForCourse(
    MedicationCourseId courseId,
  ) {
    return (_db.select(_db.schedulePhase)
          ..where((t) => t.courseId.equals(courseId.value))
          ..orderBy([(t) => OrderingTerm.asc(t.phaseStart)]))
        .watch()
        .map((rows) => rows.map(_phaseFromRow).toList());
  }

  SchedulePhase _phaseFromRow(SchedulePhaseRow row) {
    return SchedulePhase(
      id: SchedulePhaseId(row.id),
      courseId: MedicationCourseId(row.courseId),
      doseAmount: row.doseAmount,
      frequency: row.frequency,
      period: row.period,
      periodUnit: PeriodUnit.values.byName(row.periodUnit),
      daysOfWeek: _decodeDaysOfWeek(row.daysOfWeek),
      timesOfDay: _decodeTimesOfDay(row.timesOfDay),
      isPrn: row.isPrn != 0,
      prnReason: row.prnReason,
      prnMaxFrequency: row.prnMaxFrequency,
      phaseStart: DateTime.parse(row.phaseStart),
      phaseEnd: row.phaseEnd == null ? null : DateTime.parse(row.phaseEnd!),
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
    await _db
        .into(_db.schedulePhase)
        .insert(
          SchedulePhaseCompanion.insert(
            id: id.value,
            courseId: courseId.value,
            doseAmount: doseAmount,
            frequency: frequency,
            period: period,
            periodUnit: periodUnit.name,
            daysOfWeek: Value(_encodeDaysOfWeek(daysOfWeek)),
            timesOfDay: _encodeTimesOfDay(timesOfDay),
            isPrn: Value(isPrn ? 1 : 0),
            prnReason: Value(prnReason),
            prnMaxFrequency: Value(prnMaxFrequency),
            phaseStart: phaseStart.toIso8601String(),
            phaseEnd: Value(phaseEnd?.toIso8601String()),
          ),
        );
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

  /// The only query the reminder engine is allowed to read from. Excludes:
  /// - phases of a non-active course (completed/stopped/paused)
  /// - PRN phases (a max-frequency ceiling is never a fixed reminder
  ///   cadence — see specs/phase-1-v1/01-features.md F2)
  /// - phases outside their own start/end range (a taper's earlier/later
  ///   phases must not both fire)
  /// - conflicted phases (`conflict_group_id IS NOT NULL`) — always NULL in
  ///   phase 1, but the query must already respect it per
  ///   specs/phase-1-v1/02-architecture.md §6's conflict rule.
  Future<List<SchedulePhase>> activeNonConflictedPhasesForPerson(
    PersonId personId,
  ) async {
    final query = _db.select(_db.schedulePhase).join([
      innerJoin(
        _db.medicationCourse,
        _db.medicationCourse.id.equalsExp(_db.schedulePhase.courseId),
      ),
    ])
      ..where(_db.medicationCourse.personId.equals(personId.value))
      ..where(_db.medicationCourse.status.equals(CourseStatus.active.name))
      ..where(_db.schedulePhase.isPrn.equals(0))
      ..where(_db.schedulePhase.conflictGroupId.isNull());

    final rows = await query.get();
    final now = DateTime.now();
    return rows
        .map((row) => _phaseFromRow(row.readTable(_db.schedulePhase)))
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
    final query = _db.select(_db.schedulePhase).join([
      innerJoin(
        _db.medicationCourse,
        _db.medicationCourse.id.equalsExp(_db.schedulePhase.courseId),
      ),
    ])..where(_db.medicationCourse.personId.equals(personId.value));

    final rows = await query.get();
    return rows
        .map((row) => _phaseFromRow(row.readTable(_db.schedulePhase)))
        .toList();
  }

  static Set<int>? _decodeDaysOfWeek(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.split(',').map(int.parse).toSet();
  }

  static String? _encodeDaysOfWeek(Set<int>? days) {
    if (days == null || days.isEmpty) return null;
    return (days.toList()..sort()).join(',');
  }

  static List<String> _decodeTimesOfDay(String raw) {
    if (raw.isEmpty) return const [];
    return raw.split(',');
  }

  static String _encodeTimesOfDay(List<String> times) => times.join(',');
}
