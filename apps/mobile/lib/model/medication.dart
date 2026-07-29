import 'ids.dart';

/// The core loop. See specs/phase-1-v1/01-features.md F2 and
/// specs/phase-1-v1/02-architecture.md §3.
enum CourseStatus { active, completed, stopped, paused }

class DrugCode {
  final String system;
  final String code;
  final String display;

  const DrugCode({
    required this.system,
    required this.code,
    required this.display,
  });
}

/// A prescribing episode. `medicationName` is free text and always the
/// ground truth — India has no universal drug code — `medicationCoding` is
/// optional enrichment, never required.
class MedicationCourse {
  final MedicationCourseId id;
  final PersonId personId;
  final String medicationName;
  final List<DrugCode> medicationCoding;
  final CourseStatus status;
  final DateTime startDate;
  final DateTime? endDate; // null = chronic/ongoing
  final String? prescriberName;
  final String? reason;

  const MedicationCourse({
    required this.id,
    required this.personId,
    required this.medicationName,
    this.medicationCoding = const [],
    required this.status,
    required this.startDate,
    this.endDate,
    this.prescriberName,
    this.reason,
  });

  MedicationCourse copyWith({CourseStatus? status, DateTime? endDate}) {
    return MedicationCourse(
      id: id,
      personId: personId,
      medicationName: medicationName,
      medicationCoding: medicationCoding,
      status: status ?? this.status,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      prescriberName: prescriberName,
      reason: reason,
    );
  }
}
