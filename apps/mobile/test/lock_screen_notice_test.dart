import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/quick_access/lock_screen_notice.dart';
import 'package:amrutham/quick_access/widget_settings.dart';


PersonProfile samplePerson() => PersonProfile(
  id: const PersonId('p1'),
  displayName: 'Appa',
  relationship: RelationshipType.parent,
  bloodGroup: 'O positive',
  emergencyContacts: const [EmergencyContact(name: 'Anita', phone: '+91 98765 43210', relationship: 'daughter')],
  createdAt: DateTime(2025),
);

void main() {
  test('the lock screen text follows the card choices, and is off by default', () {
    expect(const CardOptions().lockScreen, isFalse);
    final person = samplePerson();
    final all = LockScreenNotice.text(person: person, allergies: const [], medicines: const [], options: const CardOptions(medicines: true))!;
    expect(all.title, contains(person.displayName));
    expect(all.body, contains('Blood group'));
    expect(all.body, contains('No medicines added'));
    final none = LockScreenNotice.text(
      person: person, allergies: const [], medicines: const [],
      options: const CardOptions(bloodGroup: false, allergies: false, dial: false),
    );
    expect(none, isNull);
  });

  test('the setting survives being saved and read back', () {
    final s = const WidgetSettings(enabled: true).withOptions('a', const CardOptions(lockScreen: true));
    expect(WidgetSettings.decode(s.encode()).optionsFor('a').lockScreen, isTrue);
  });
}
