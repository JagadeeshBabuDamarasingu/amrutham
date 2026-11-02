import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../model/ids.dart';
import 'alarm_actions.dart';
import 'alarm_settings.dart';
import '../model/schedule_phase.dart';
import '../repository/medication_repository.dart';

/// See specs/phase-1-v1/02-architecture.md §6 — the single most important
/// design decision in phase 1. Does not use `workmanager`; wraps
/// OS-level scheduled notifications (`AlarmManager`/`UNUserNotificationCenter`)
/// via `flutter_local_notifications`, which survive app kill and aren't
/// subject to iOS background-execution throttling.
class ReminderRepository {
  static const String _channelId = 'meds_channel';
  static const String _channelName = 'Medication Reminders';

  /// Generous bound on (day, time) slot combinations ever scheduled for one
  /// phase — used only to sweep-cancel stale notification ids before a
  /// re-arm. Scheduling never actually approaches this; it exists so a
  /// re-arm can find and cancel ids from a phase that used to have more
  /// times/days than it does now, without persisting notification-id state
  /// anywhere.
  static const int _maxSlotsPerPhase = 64;

  final FlutterLocalNotificationsPlugin _notifications;
  final MedicationRepository _medicationRepository;

  /// Reads how alarms should ring each time they are armed.
  final Future<AlarmSettings> Function() _loadSettings;

  ReminderRepository(this._notifications, this._medicationRepository, [Future<AlarmSettings> Function()? loadSettings])
    : _loadSettings = loadSettings ?? (() async => const AlarmSettings());

  Future<void> requestNotificationPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Whether exact-time delivery is available right now. If false, the UI
  /// must show a visible warning before arming reminders in degraded mode —
  /// silent degradation of a medication reminder is unacceptable. See
  /// specs/phase-1-v1/02-architecture.md §6's Android 14+ exact-alarm gotcha.
  Future<bool> canScheduleExactReminders() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true; // not Android; no such gate on iOS
    return await android.canScheduleExactNotifications() ?? false;
  }

  Future<bool> notificationsAllowed() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  /// Lets an alarm come up over the lock screen (Android 14+ may ask).
  /// True when it is already allowed (nothing opens); otherwise the phone's
  /// own settings page opens.
  Future<bool> requestFullScreenAlarms() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestFullScreenIntentPermission() ?? true;
  }

  /// Rings one alarm in ten seconds, so the person can hear what it does.
  Future<void> testAlarm() async {
    await _scheduleOne(
      notificationId: 0x3fffffff,
      title: 'Take Test medicine',
      body: 'This is a test alarm',
      scheduledDate: tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      matchComponents: null,
      exactAllowed: await canScheduleExactReminders(),
      alarm: const AlarmPayload('test', 'test', '00:00', 'Test medicine', 'This is a test alarm').encode(),
      alarmSettings: await _loadSettings(),
    );
  }

  /// Removes the sound channels the current choice no longer uses.
  Future<void> removeUnusedAlarmChannels(AlarmSettings current) async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    for (final id in [...AlarmSettings.allChannelIds, 'meds_alarm_v2', 'meds_alarm_channel']) {
      if (id != current.channelId) await android?.deleteNotificationChannel(channelId: id);
    }
  }

  /// Re-arms every living person's alarms, e.g. after the phone's settings changed.
  Future<void> rearm(Iterable<PersonId> people) async {
    for (final id in people) {
      await armRemindersForPerson(id);
    }
  }

  /// Opens the OS's "allow exact alarms" flow. Returns whether it ended up
  /// granted.
  Future<bool> requestExactAlarmPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestExactAlarmsPermission() ?? false;
  }

  /// The ONLY entry point the app uses to (re-)arm reminders for a person.
  /// Always cancels every notification this person could plausibly have had
  /// armed, then reads only active, non-conflicted, non-PRN schedule phases
  /// via MedicationRepository.activeNonConflictedPhasesForPerson — there is
  /// no code path here that can reach a draft (phase 2) or an
  /// unresolved-conflict phase. Call this after any course or phase
  /// create/update, so it is always idempotent and never leaves a stale
  /// reminder behind.
  Future<void> armRemindersForPerson(PersonId personId) async {
    final allPhases = await _medicationRepository.allPhasesForPerson(
      personId,
    );
    for (final phase in allPhases) {
      await _cancelAllSlotsFor(phase.id);
    }

    final activePhases = await _medicationRepository
        .activeNonConflictedPhasesForPerson(personId);
    final exactAllowed = await canScheduleExactReminders();
    final alarmSettings = await _loadSettings();

    for (final phase in activePhases) {
      final course = await _medicationRepository.courseById(phase.courseId);
      final medicationName = course?.medicationName ?? 'medication';
      await _scheduleInstances(
        personId: personId,
        phase: phase,
        medicationName: medicationName,
        exactAllowed: exactAllowed,
        alarmSettings: alarmSettings,
      );
    }
  }

  Future<void> _scheduleInstances({
    required PersonId personId,
    required SchedulePhase phase,
    required String medicationName,
    required bool exactAllowed,
    required AlarmSettings alarmSettings,
  }) async {
    final days = phase.daysOfWeek;
    var slot = 0;
    for (final time in phase.timesOfDay) {
      final payload = AlarmPayload(personId.value, phase.courseId.value, time, medicationName, phase.doseAmount).encode();
      if (days == null || days.isEmpty) {
        await _scheduleOne(
          notificationId: _notificationId(phase.id, slot++),
          title: 'Take $medicationName',
          body: phase.doseAmount,
          scheduledDate: _nextInstanceOfTime(time),
          matchComponents: DateTimeComponents.time,
          exactAllowed: exactAllowed,
          alarm: payload,
          alarmSettings: alarmSettings,
        );
      } else {
        for (final isoWeekday in days) {
          await _scheduleOne(
            notificationId: _notificationId(phase.id, slot++),
            title: 'Take $medicationName',
            body: phase.doseAmount,
            scheduledDate: _nextInstanceOfWeekdayAndTime(isoWeekday, time),
            matchComponents: DateTimeComponents.dayOfWeekAndTime,
            exactAllowed: exactAllowed,
            alarm: payload,
          alarmSettings: alarmSettings,
          );
        }
      }
    }
  }

  Future<void> _scheduleOne({
    required int notificationId,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents? matchComponents,
    required bool exactAllowed,
    String? alarm, // the payload of a medicine alarm; null for a plain reminder
    AlarmSettings? alarmSettings,
  }) async {
    await _notifications.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: alarm,
      notificationDetails: NotificationDetails(
        android: alarm != null
            ? alarmDetails(alarmSettings ?? const AlarmSettings())
            : const AndroidNotificationDetails(
                _channelId,
                _channelName,
                channelDescription: 'Scheduled reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
    );
  }

  static int _visitId(HistoryEventId id) =>
      _fnv1a32('visit#${id.value}') & 0x7fffffff;

  /// Whether a "day before" reminder is armed for this planned visit. The
  /// armed notification is the only record, so nothing extra is stored.
  Future<bool> hasVisitReminder(HistoryEventId id) async =>
      (await _notifications.pendingNotificationRequests()).any(
        (n) => n.id == _visitId(id),
      );

  /// Turns the 9 am day-before reminder for a visit on or off. Returns false
  /// if it could not be armed because that moment has already passed.
  Future<bool> setVisitReminder({
    required HistoryEventId id,
    required String title,
    required DateTime visit,
    required bool on,
  }) async {
    await _notifications.cancel(id: _visitId(id));
    if (!on) return true;
    final at = tz.TZDateTime(tz.local, visit.year, visit.month, visit.day - 1, 9);
    if (at.isBefore(tz.TZDateTime.now(tz.local))) return false;
    await _scheduleOne(
      notificationId: _visitId(id),
      title: 'Tomorrow: $title',
      body: 'You set a reminder for this visit.',
      scheduledDate: at,
      matchComponents: null,
      exactAllowed: await canScheduleExactReminders(),
    );
    return true;
  }

  Future<void> _cancelAllSlotsFor(SchedulePhaseId phaseId) async {
    for (var slot = 0; slot < _maxSlotsPerPhase; slot++) {
      await _notifications.cancel(id: _notificationId(phaseId, slot));
    }
  }

  /// A stable (cross-run) 31-bit id — NOT Dart's built-in `String.hashCode`,
  /// which is not guaranteed stable across VM/app restarts.
  static int _notificationId(SchedulePhaseId phaseId, int slot) {
    return _fnv1a32('${phaseId.value}#$slot') & 0x7fffffff;
  }

  static int _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final byte in input.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static tz.TZDateTime _nextInstanceOfTime(String hhmm) {
    final now = tz.TZDateTime.now(tz.local);
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// `isoWeekday` follows Dart's `DateTime.weekday` convention (1=Mon..7=Sun)
  /// — same convention as SchedulePhase.daysOfWeek. See
  /// specs/phase-1-v1/02-architecture.md §3.
  static tz.TZDateTime _nextInstanceOfWeekdayAndTime(
    int isoWeekday,
    String hhmm,
  ) {
    var scheduled = _nextInstanceOfTime(hhmm);
    while (scheduled.weekday != isoWeekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
