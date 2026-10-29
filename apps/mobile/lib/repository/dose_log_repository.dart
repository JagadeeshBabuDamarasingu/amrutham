import 'package:realm/realm.dart';

import '../db/realm_schemas.dart';
import '../model/dose_log.dart';
import '../model/ids.dart';

class DoseLogRepository {
  final Realm _realm;

  DoseLogRepository(this._realm);

  /// Every answer logged for doses scheduled on [day], across the family.
  Stream<List<DoseLog>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _realm
        .query<DoseLogRow>(
          r'scheduledAt >= $0 AND scheduledAt < $1 SORT(loggedAt DESC)',
          [start, end],
        )
        .changes
        .map((c) => c.results.map(_fromRow).toList());
  }

  Future<void> logDose({
    required PersonId personId,
    required MedicationCourseId courseId,
    required DateTime scheduledAt,
    required DoseStatus status,
  }) async {
    _realm.write(() {
      _realm.add(
        DoseLogRow(
          DoseLog.keyFor(courseId, scheduledAt),
          personId.value,
          courseId.value,
          scheduledAt,
          status.name,
          DateTime.now(),
        ),
        update: true,
      );
    });
  }

  DoseLog _fromRow(DoseLogRow row) => DoseLog(
    personId: PersonId(row.personId),
    courseId: MedicationCourseId(row.courseId),
    scheduledAt: row.scheduledAt.toLocal(),
    status: DoseStatus.values.byName(row.status),
    loggedAt: row.loggedAt.toLocal(),
  );
}
