import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/ui/emergency_card_screen.dart';

MedicationCourse _med(String id, String name) => MedicationCourse(
  id: MedicationCourseId(id),
  personId: const PersonId('p'),
  medicationName: name,
  status: CourseStatus.active,
  startDate: DateTime(2025),
);

void main() {
  test('two courses of the same medicine are one line on the card', () {
    final out = EmergencyCardScreen.distinctMedicines([
      _med('1', 'Vitamin D3'),
      _med('2', ' vitamin d3 '),
      _med('3', 'Gastric Medicine'),
      _med('4', 'Vitamin D3'),
    ]);
    expect(out.map((c) => c.id.value), ['1', '3']);
  });

  test('an empty list stays empty, and order is kept', () {
    expect(EmergencyCardScreen.distinctMedicines(const []), isEmpty);
    expect(
      EmergencyCardScreen.distinctMedicines([_med('1', 'B'), _med('2', 'A')]).map((c) => c.medicationName),
      ['B', 'A'],
    );
  });
}
