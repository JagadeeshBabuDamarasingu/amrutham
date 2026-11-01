import 'package:amrutham_widgets/amrutham_widgets.dart';

import '../model/allergy.dart';
import '../model/medication.dart';
import '../model/person.dart';
import 'emergency_snapshot.dart';
import 'widget_settings.dart';

/// The emergency details as a pinned notification that shows on the phone's
/// lock screen, for the people who turned it on. What it says follows the same
/// choices as the home screen card; a detail turned off is not in the text.
class LockScreenNotice {
  /// Title and body, or null when the person turned everything off.
  static ({String title, String short, String body})? text({
    required PersonProfile person,
    required List<AllergyRecord> allergies,
    required List<MedicationCourse> medicines,
    required CardOptions options,
  }) {
    final lines = <String>[];
    if (options.bloodGroup) {
      lines.add(person.bloodGroup == null ? 'Blood group not added' : 'Blood group ${shortBlood(person.bloodGroup)}');
    }
    if (options.allergies) {
      final names = [for (final a in allergies) a.substance];
      // Nothing is said when there are none: the card in the app says it plainly.
      if (names.isNotEmpty) lines.add('Allergic to ${names.join(', ')}');
    }
    if (options.medicines) {
      final names = <String>{for (final m in medicines) m.medicationName}.toList();
      if (names.isNotEmpty) lines.add('Takes ${names.join(', ')}');
    }
    // The buttons carry the contacts, so a person who only turned on dialling still gets a notice.
    if (lines.isEmpty && options.dial) lines.add('Call for help');
    if (lines.isEmpty) return null;
    // The collapsed notice is all that shows on some lock screens: name and blood group.
    final blood = options.bloodGroup && person.bloodGroup != null ? '\nBlood ${shortBlood(person.bloodGroup)}' : '';
    return (title: 'Emergency: ${person.displayName}', short: '${person.displayName}$blood', body: lines.join('\n'));
  }

  /// A stable id per person, in a range reminders do not use.
  static int idFor(String personId) {
    var hash = 0x811c9dc5;
    for (final byte in personId.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 0x40000000 | (hash & 0x3fffffff);
  }

  /// The buttons: the contacts the person chose to show (two at most, so the
  /// emergency number always fits in the three Android allows), then 112.
  static List<({String label, String number})> dials(PersonProfile person, CardOptions options) => [
    if (options.dial)
      for (final c in person.emergencyContacts.take(2))
        if (EmergencySnapshot.dialable(c.phone) != null) (label: 'Call ${c.name}', number: EmergencySnapshot.dialable(c.phone)!),
    (label: 'Emergency 112', number: '112'),
  ];

  static Future<void> show(String personId, PersonProfile person, CardOptions options, ({String title, String short, String body}) t) =>
      AmruthamWidgets.showLockNotice(id: idFor(personId), title: t.title, short: t.short, body: t.body, dials: dials(person, options));

  static Future<void> hide(String personId) => AmruthamWidgets.hideLockNotice(idFor(personId));
}
