import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/history_event.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/ui/emergency_card_screen.dart';

HistoryEvent _e(String t, DateTime d, [HistoryKind k = HistoryKind.procedure]) => HistoryEvent(
  id: HistoryEventId(t),
  personId: const PersonId('p'),
  kind: k,
  title: t,
  eventDate: d,
);

void main() {
  test('the card shows the latest surgery and the next planned one, nothing else', () {
    final next = DateTime.now().add(const Duration(days: 40));
    final lines = EmergencyCardScreen.recentSurgeries([
      _e('Appendectomy', DateTime(2015, 3)),
      _e('Cataract surgery', DateTime(2022, 3)),
      _e('Knee replacement', next),
      _e('Checkup', DateTime(2024, 1), HistoryKind.visit),
    ]);
    expect(lines.first, 'Cataract surgery, Mar 2022');
    expect(lines.last, startsWith('Knee replacement planned '));
    expect(lines, hasLength(2));
    expect(EmergencyCardScreen.recentSurgeries([]), isEmpty);
  });
}
