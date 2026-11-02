import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../crypto/key_manager.dart';
import '../db/connection.dart';
import '../model/dose_log.dart';
import '../model/ids.dart';
import '../repository/dose_log_repository.dart';

const alarmChannelId = 'meds_alarm_channel';
const actionTaken = 'taken';
const actionSnooze = 'snooze';
const snoozeMinutes = 10;

/// A medicine alarm rings like an alarm clock: loud, repeating, over the lock
/// screen, with Taken and Snooze on the notification itself. It stops by
/// itself after ten minutes so it never rings forever in an empty room.
AndroidNotificationDetails alarmDetails() => AndroidNotificationDetails(
  alarmChannelId,
  'Medicine alarms',
  channelDescription: 'Rings at the times you set to take a medicine',
  importance: Importance.max,
  priority: Priority.max,
  category: AndroidNotificationCategory.alarm,
  fullScreenIntent: true,
  audioAttributesUsage: AudioAttributesUsage.alarm,
  additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT: keep ringing
  timeoutAfter: 10 * 60 * 1000,
  visibility: NotificationVisibility.public,
  actions: const [
    AndroidNotificationAction(actionTaken, 'Taken', cancelNotification: true),
    AndroidNotificationAction(actionSnooze, 'Snooze $snoozeMinutes min', cancelNotification: true),
  ],
);

/// What an alarm needs to remember to act on a button, kept in the
/// notification itself so a tap works with the app closed.
class AlarmPayload {
  const AlarmPayload(this.personId, this.courseId, this.time, this.name, this.dose);
  final String personId, courseId, time, name, dose;

  String encode() => jsonEncode({'p': personId, 'c': courseId, 't': time, 'n': name, 'd': dose});

  static AlarmPayload? parse(String? raw) {
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return AlarmPayload(m['p'] as String, m['c'] as String, m['t'] as String, m['n'] as String, m['d'] as String);
    } catch (_) {
      return null; // some other notification (a visit reminder)
    }
  }
}

/// The dose an alarm at "HH:mm" is for: today's time, or yesterday's if the
/// alarm was left until after midnight.
DateTime doseTimeFor(String hhmm, DateTime now) {
  final parts = hhmm.split(':');
  final today = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  return today.isAfter(now.add(const Duration(hours: 1))) ? today.subtract(const Duration(days: 1)) : today;
}

int snoozeIdFor(AlarmPayload p) => ((p.courseId + p.time).hashCode & 0x3fffffff) | 0x40000000;

/// An alarm that is ringing and should be shown full screen.
class AlarmRing {
  const AlarmRing(this.payload, this.notificationId);
  final AlarmPayload payload;
  final int? notificationId;
}

/// Set when the person opens an alarm (or the phone opens it over the lock
/// screen); the lock gate shows the alarm page for it.
final pendingRing = ValueNotifier<AlarmRing?>(null);

Future<void> answerDose(AlarmPayload payload, DoseStatus status) async {
  final realm = await openRealm(await const SecureStorageDbKeyProvider().getOrCreateDbKey());
  try {
    await DoseLogRepository(realm).logDose(
      personId: PersonId(payload.personId),
      courseId: MedicationCourseId(payload.courseId),
      scheduledAt: doseTimeFor(payload.time, DateTime.now()),
      status: status,
    );
  } finally {
    realm.close();
  }
}

Future<void> snoozeAlarm(AlarmPayload payload) async {
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
  await FlutterLocalNotificationsPlugin().zonedSchedule(
    id: snoozeIdFor(payload),
    title: 'Take ${payload.name}',
    body: payload.dose,
    scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(minutes: snoozeMinutes)),
    notificationDetails: NotificationDetails(android: alarmDetails()),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: payload.encode(),
  );
}

/// Runs from a notification button, with the app open or closed.
@pragma('vm:entry-point')
Future<void> alarmActionBackground(NotificationResponse response) => handleAlarmAction(response);

Future<void> handleAlarmAction(NotificationResponse response) async {
  final payload = AlarmPayload.parse(response.payload);
  if (payload == null) return;
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  switch (response.actionId) {
    case actionTaken:
      await answerDose(payload, DoseStatus.taken);
    case actionSnooze:
      await snoozeAlarm(payload);
  }
}
