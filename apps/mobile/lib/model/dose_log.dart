import 'ids.dart';

enum DoseStatus { taken, missed }

class DoseLog {
  final PersonId personId;
  final MedicationCourseId courseId;
  final DateTime scheduledAt;
  final DoseStatus status;
  final DateTime loggedAt;

  const DoseLog({
    required this.personId,
    required this.courseId,
    required this.scheduledAt,
    required this.status,
    required this.loggedAt,
  });

  /// Matches a log to the dose it answers.
  static String keyFor(MedicationCourseId courseId, DateTime scheduledAt) =>
      '${courseId.value}_${scheduledAt.millisecondsSinceEpoch}';

  String get key => keyFor(courseId, scheduledAt);
}
