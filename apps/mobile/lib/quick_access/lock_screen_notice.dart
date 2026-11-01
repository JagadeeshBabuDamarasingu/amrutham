import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../model/allergy.dart';
import '../model/medication.dart';
import '../model/person.dart';
import 'emergency_snapshot.dart';
import 'widget_settings.dart';

/// The emergency details as a pinned notification that shows on the phone's
/// lock screen, for the people who turned it on. What it says follows the same
/// choices as the home screen card; a detail turned off is not in the text.
class LockScreenNotice {
  static const _channelId = 'amrutham_emergency_info';

  /// Title and body, or null when the person turned everything off.
  static ({String title, String body})? text({
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
      lines.add(names.isEmpty ? 'No allergies added to Amrutham' : 'Allergic to ${names.join(', ')}');
    }
    if (options.medicines) {
      final names = <String>{for (final m in medicines) m.medicationName}.toList();
      lines.add(names.isEmpty ? 'No medicines added to Amrutham' : 'Takes ${names.join(', ')}');
    }
    if (options.dial) {
      for (final c in person.emergencyContacts) {
        lines.add('Call ${c.name}${c.relationship == null ? '' : ' (${c.relationship})'}: ${c.phone}');
      }
    }
    if (lines.isEmpty) return null;
    return (title: 'Emergency: ${person.displayName}', body: lines.join('\n'));
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

  static Future<void> show(FlutterLocalNotificationsPlugin plugin, String personId, ({String title, String body}) t) {
    return plugin.show(
      id: idFor(personId),
      title: t.title,
      body: t.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Emergency details on lock screen',
          channelDescription: 'Shows emergency details on the lock screen, for the people you chose',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          showWhen: false,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(t.body),
        ),
      ),
    );
  }

  static Future<void> hide(FlutterLocalNotificationsPlugin plugin, String personId) =>
      plugin.cancel(id: idFor(personId));
}
