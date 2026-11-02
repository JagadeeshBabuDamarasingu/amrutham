import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/model/dose_log.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/alarm_screen.dart';

TodayDose _dose(String course, int h, [int m = 0]) => TodayDose(
  person: PersonProfile(id: const PersonId('p'), displayName: 'Appa', relationship: RelationshipType.parent, createdAt: DateTime(2025)),
  courseId: MedicationCourseId(course),
  scheduledAt: DateTime(2026, 11, 3, h, m),
  medicationName: course,
  doseAmount: '1',
  time: TimeOfDayLite(h, m),
);

void main() {
  test('one alarm covers every unanswered dose due at the same time', () {
    final doses = [_dose('a', 8), _dose('b', 8), _dose('c', 8), _dose('d', 21)];
    final answered = {DoseLog.keyFor(const MedicationCourseId('b'), DateTime(2026, 11, 3, 8))};
    expect([for (final d in dosesDueTogether(doses, answered, '08:00')) d.medicationName], ['a', 'c']);
    expect(dosesDueTogether(doses, {}, '09:30'), isEmpty);
  });
}
