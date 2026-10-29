import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/dose_log.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/repository/dose_log_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('answers are per dose, replace on re-answer, and scoped to the day', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = DoseLogRepository(realm);
    const person = PersonId('appa');
    const course = MedicationCourseId('d3');
    final today = DateTime.now();
    final eight = DateTime(today.year, today.month, today.day, 8);
    final two = DateTime(today.year, today.month, today.day, 14);
    final yesterday = eight.subtract(const Duration(days: 1));

    await repo.logDose(personId: person, courseId: course, scheduledAt: eight, status: DoseStatus.missed);
    // Changing your mind replaces the answer rather than adding a second one.
    await repo.logDose(personId: person, courseId: course, scheduledAt: eight, status: DoseStatus.taken);
    await repo.logDose(personId: person, courseId: course, scheduledAt: two, status: DoseStatus.missed);
    await repo.logDose(personId: person, courseId: course, scheduledAt: yesterday, status: DoseStatus.taken);

    final logs = await repo.watchDay(today).first;
    expect(logs, hasLength(2));
    final byKey = {for (final l in logs) l.key: l.status};
    expect(byKey[DoseLog.keyFor(course, eight)], DoseStatus.taken);
    expect(byKey[DoseLog.keyFor(course, two)], DoseStatus.missed);
  });
}
