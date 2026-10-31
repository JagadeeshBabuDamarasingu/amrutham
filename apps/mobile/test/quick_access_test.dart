// The home screen emergency card copies only what the person turned on, and
// says plainly when something has not been added.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/allergy.dart';
import 'package:amrutham/model/certainty.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/medication.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/quick_access/emergency_snapshot.dart';
import 'package:amrutham/quick_access/widget_settings.dart';

PersonProfile _person({
  String? blood = 'O positive',
  List<EmergencyContact> contacts = const [
    EmergencyContact(name: 'Anita', phone: '+91 98765 43210', relationship: 'daughter'),
    EmergencyContact(name: 'Dr. Rao', phone: '040-2345 6789'),
  ],
}) => PersonProfile(
  id: const PersonId('p1'),
  displayName: 'Appa',
  relationship: RelationshipType.parent,
  bloodGroup: blood,
  emergencyContacts: contacts,
  createdAt: DateTime(2025),
);

AllergyRecord _allergy(String s) => AllergyRecord(
  id: AllergyRecordId('a-$s'),
  personId: const PersonId('p1'),
  substance: s,
  reaction: 'rash',
  certainty: Certainty.reported,
);

MedicationCourse _med(String n) => MedicationCourse(
  id: MedicationCourseId('m-$n'),
  personId: const PersonId('p1'),
  medicationName: n,
  status: CourseStatus.active,
  startDate: DateTime(2025),
);

Map<String, dynamic> _build({
  PersonProfile? person,
  List<AllergyRecord> allergies = const [],
  List<MedicationCourse> medicines = const [],
  CardOptions options = const CardOptions(),
}) => jsonDecode(
  EmergencySnapshot.build(
    person: person ?? _person(),
    allergies: allergies,
    medicines: medicines,
    options: options,
  ),
) as Map<String, dynamic>;

void main() {
  group('EmergencySnapshot', () {
    test('defaults show name, blood group, allergies and a dial contact, but not medicines', () {
      final s = _build(allergies: [_allergy('Penicillin')], medicines: [_med('Metformin')]);
      expect(s['name'], 'Appa');
      expect(s['blood'], 'O+');
      expect(s['allergies'], 'Allergic to Penicillin');
      expect(s['dial'], {'label': 'Anita', 'number': '+919876543210'});
      expect(s.containsKey('medicines'), isFalse);
      expect(jsonEncode(s).contains('Metformin'), isFalse);
    });

    test('a field that is off is not in the output at all', () {
      final s = _build(
        allergies: [_allergy('Penicillin')],
        options: const CardOptions(bloodGroup: false, allergies: false, dial: false),
      );
      expect(s.keys.toSet(), {'v', 'name'});
      expect(jsonEncode(s).contains('Penicillin'), isFalse);
      expect(jsonEncode(s).contains('9876'), isFalse);
    });

    test('nothing added is said out loud, never left blank', () {
      final s = _build(person: _person(blood: null, contacts: const []));
      expect(s['allergies'], 'No allergies added to Amrutham');
      expect(s['bloodNote'], 'Blood group not added');
      expect(s.containsKey('blood'), isFalse);
      expect(s['dial'], isNull);
    });

    test('medicines, when on, show up to three and count the rest', () {
      final three = _build(
        medicines: [_med('A'), _med('B'), _med('C')],
        options: const CardOptions(medicines: true),
      );
      expect(three['medicines'], 'Takes A, B, C');
      final five = _build(
        medicines: [for (final n in 'ABCDE'.split('')) _med(n)],
        options: const CardOptions(medicines: true),
      );
      expect(five['medicines'], 'Takes A, B, C +2 more');
      expect(
        _build(options: const CardOptions(medicines: true))['medicines'],
        'No medicines added to Amrutham',
      );
    });

    test('the chosen contact is dialled, and a bad index falls back safely', () {
      expect(_build(options: const CardOptions(dialContact: 1))['dial'], {'label': 'Dr. Rao', 'number': '04023456789'});
      expect(_build(options: const CardOptions(dialContact: 9))['dial'], {'label': 'Dr. Rao', 'number': '04023456789'});
    });

    test('a phone number is cleaned for a tel: link, or dropped', () {
      expect(EmergencySnapshot.dialable('+91 (98765) 43210'), '+919876543210');
      expect(EmergencySnapshot.dialable('098765 43210'), '09876543210');
      expect(EmergencySnapshot.dialable('112'), '112');
      expect(EmergencySnapshot.dialable('ask Anita'), isNull);
      expect(EmergencySnapshot.dialable('12'), isNull);
      expect(EmergencySnapshot.dialable('1;DROP'), isNull);
      expect(EmergencySnapshot.dialable('tel:+91 1234 5678 ,,,#'), '9112345678');
    });
  });

  group('WidgetSettings', () {
    test('start off, with medicines off', () {
      const s = WidgetSettings();
      expect(s.enabled, isFalse);
      expect(s.optionsFor('any').medicines, isFalse);
      expect(s.optionsFor('any').bloodGroup, isTrue);
    });

    test('round-trip through the stored text', () {
      final s = const WidgetSettings()
          .withEnabled(true)
          .withOptions('p1', const CardOptions(medicines: true, dialContact: 2));
      final back = WidgetSettings.decode(s.encode());
      expect(back.enabled, isTrue);
      expect(back.optionsFor('p1').medicines, isTrue);
      expect(back.optionsFor('p1').dialContact, 2);
      expect(back.optionsFor('p2').medicines, isFalse);
    });

    test('missing or damaged storage means off', () {
      expect(WidgetSettings.decode(null).enabled, isFalse);
      expect(WidgetSettings.decode('{not json').enabled, isFalse);
      expect(WidgetSettings.decode('[]').enabled, isFalse);
    });
  });
}
