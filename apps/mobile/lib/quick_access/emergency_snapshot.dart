import 'dart:convert';

import '../model/allergy.dart';
import '../model/medication.dart';
import '../model/person.dart';
import 'widget_settings.dart';

/// "O positive" -> "O+". Shared with the emergency card screen.
String shortBlood(String? group) {
  if (group == null) return '—';
  return group.replaceAll(' positive', '+').replaceAll(' negative', '−');
}

/// What the home screen widget is allowed to show for one person, as JSON the
/// native widget renders as it is. The redaction happens here, in one place:
/// a field the person turned off is simply not in the output, so it never
/// reaches the phone's preferences file. The wording for "nothing added" is
/// explicit, so a blank can't be mistaken for "no allergies".
class EmergencySnapshot {
  static const version = 1;

  static String build({
    required PersonProfile person,
    required List<AllergyRecord> allergies,
    required List<MedicationCourse> medicines,
    required CardOptions options,
  }) {
    final out = <String, Object?>{'v': version, 'name': person.displayName};

    if (options.bloodGroup) {
      out['blood'] = person.bloodGroup == null
          ? 'Blood group not added'
          : shortBlood(person.bloodGroup);
    }
    if (options.allergies) {
      final names = [for (final a in allergies) a.substance];
      out['allergies'] = names.isEmpty
          ? 'No allergies added to Amrutham'
          : 'Allergic to ${names.join(', ')}';
    }
    if (options.medicines) {
      final names = [for (final m in medicines) m.medicationName];
      out['medicines'] = names.isEmpty
          ? 'No medicines added to Amrutham'
          : names.length <= 3
          ? 'Takes ${names.join(', ')}'
          : 'Takes ${names.take(3).join(', ')} +${names.length - 3} more';
    }
    if (options.dial) {
      final contacts = person.emergencyContacts;
      final contact = contacts.isEmpty
          ? null
          : contacts[options.dialContact.clamp(0, contacts.length - 1)];
      final number = contact == null ? null : dialable(contact.phone);
      out['dial'] = number == null ? null : {'label': contact!.name, 'number': number};
    }
    return jsonEncode(out);
  }

  /// A phone number safe to put in a `tel:` link: digits and a leading plus.
  /// The field is free text, so anything else is dropped; fewer than three
  /// digits is not a number.
  static String? dialable(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 3) return null;
    return raw.trim().startsWith('+') ? '+$digits' : digits;
  }
}
