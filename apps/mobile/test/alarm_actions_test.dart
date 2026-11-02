import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/reminder/alarm_actions.dart';
import 'package:amrutham/ui/medicine_alarms_screen.dart';

void main() {
  test('an alarm payload survives the notification, and other payloads are ignored', () {
    final p = AlarmPayload('p1', 'c1', '08:00', 'Metformin', '500 mg');
    final back = AlarmPayload.parse(p.encode())!;
    expect([back.personId, back.courseId, back.time, back.name, back.dose], ['p1', 'c1', '08:00', 'Metformin', '500 mg']);
    expect(AlarmPayload.parse(null), isNull);
    expect(AlarmPayload.parse('not json'), isNull);
  });

  test('Taken logs the dose the alarm was for: today, or yesterday if left past midnight', () {
    expect(doseTimeFor('08:00', DateTime(2026, 11, 3, 8, 5)), DateTime(2026, 11, 3, 8));
    expect(doseTimeFor('22:00', DateTime(2026, 11, 3, 0, 20)), DateTime(2026, 11, 2, 22));
  });

  test('days read plainly', () {
    expect(daysLabel(null), 'Every day');
    expect(daysLabel({1, 3}), 'Mon, Wed');
  });
}
