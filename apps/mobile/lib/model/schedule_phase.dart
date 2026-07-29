import 'ids.dart';

/// See specs/phase-1-v1/01-features.md F2 and
/// specs/phase-1-v1/02-architecture.md §3.
enum PeriodUnit { day, week, month }

/// One phase of a (possibly multi-phase) schedule. Ordered phases with
/// distinct `phaseStart`/`phaseEnd` ranges are how tapers are represented —
/// there is no separate "taper" type.
///
/// `conflict_group_id` (phase 2 sync) intentionally has no field here: it's
/// reserved in the DB schema only, and this phase never populates it. See
/// specs/phase-1-v1/02-architecture.md §6's conflict rule.
class SchedulePhase {
  final SchedulePhaseId id;
  final MedicationCourseId courseId;
  final String doseAmount;
  final int frequency;
  final int period;
  final PeriodUnit periodUnit;
  final Set<int>? daysOfWeek; // 1=Mon..7=Sun, for alternate-day dosing
  final List<String> timesOfDay; // "HH:mm" strings
  final bool isPrn;
  final String? prnReason;
  final String? prnMaxFrequency; // a ceiling, never a fixed reminder cadence
  final DateTime phaseStart;
  final DateTime? phaseEnd;

  const SchedulePhase({
    required this.id,
    required this.courseId,
    required this.doseAmount,
    required this.frequency,
    required this.period,
    required this.periodUnit,
    this.daysOfWeek,
    required this.timesOfDay,
    this.isPrn = false,
    this.prnReason,
    this.prnMaxFrequency,
    required this.phaseStart,
    this.phaseEnd,
  });
}
