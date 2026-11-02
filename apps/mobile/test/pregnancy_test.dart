import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/ui/emergency_card_screen.dart';

PersonProfile _p({bool pregnant = false, DateTime? due}) => PersonProfile(
  id: const PersonId('a'),
  displayName: 'Anita',
  relationship: RelationshipType.spouse,
  pregnant: pregnant,
  pregnancyDue: due,
  createdAt: DateTime(2025),
);

void main() {
  test('pregnancy shows on the card text only while pregnant', () {
    expect(_p().pregnancyLine, isNull);
    expect(_p(pregnant: true).pregnancyLine, 'Pregnant');
    expect(_p(pregnant: true, due: DateTime(2027, 3, 14)).pregnancyLine, 'Pregnant, due 14 Mar 2027');
    expect(EmergencyCardScreen.cardHtml(_p(), [], []), isNot(contains('Pregnancy')));
    expect(EmergencyCardScreen.cardHtml(_p(pregnant: true), [], []), contains('Pregnancy'));
  });
}
