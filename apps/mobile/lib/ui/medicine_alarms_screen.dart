import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'app_style.dart';

class AlarmRow {
  const AlarmRow(this.person, this.medicine, this.dose, this.time, this.days);
  final String person, medicine, dose, time, days;
}

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String daysLabel(Set<int>? days) =>
    days == null || days.isEmpty || days.length == 7 ? 'Every day' : (days.toList()..sort()).map((d) => _dayNames[d - 1]).join(', ');

/// Every alarm that is set, earliest time first.
final alarmRowsProvider = FutureProvider<List<AlarmRow>>((ref) async {
  final people = await ref.watch(profilesProvider.future);
  final meds = await ref.watch(medicationRepositoryProvider.future);
  final rows = <AlarmRow>[];
  for (final person in people.where((p) => !p.isDeceased)) {
    final names = {for (final c in await ref.watch(medicationCoursesProvider(person.id).future)) c.id: c.medicationName};
    for (final phase in await meds.activeNonConflictedPhasesForPerson(person.id)) {
      for (final t in phase.timesOfDay) {
        rows.add(AlarmRow(person.displayName, names[phase.courseId] ?? 'Medicine', phase.doseAmount, t, daysLabel(phase.daysOfWeek)));
      }
    }
  }
  rows.sort((a, b) => a.time.compareTo(b.time));
  return rows;
});

final _healthProvider = FutureProvider.autoDispose<({bool notifications, bool exact})>((ref) async {
  final r = await ref.watch(reminderRepositoryProvider.future);
  return (notifications: await r.notificationsAllowed(), exact: await r.canScheduleExactReminders());
});

/// Where the person sees every medicine alarm that is set, checks the phone
/// will let it ring, and tries one.
class MedicineAlarmsScreen extends ConsumerWidget {
  const MedicineAlarmsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(alarmRowsProvider).valueOrNull ?? const <AlarmRow>[];
    final health = ref.watch(_healthProvider).valueOrNull;

    Widget check(String title, String ok, String bad, bool? good, Future<void> Function() fix) => ListTile(
      leading: Icon(good == false ? Icons.error_outline : Icons.check_circle_outline,
          color: good == false ? const Color(0xFFB3261E) : const Color(0xFF2E9B6B)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(good == false ? bad : ok),
      trailing: good == false
          ? TextButton(
              onPressed: () async {
                await fix();
                ref.invalidate(_healthProvider);
              },
              child: const Text('Allow'),
            )
          : null,
    );

    return Scaffold(
      backgroundColor: onboardBg,
      appBar: AppBar(backgroundColor: onboardBg, title: const Text('Medicine alarms')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'An alarm rings at each time you set for a medicine, even with the app closed. It has Taken and Snooze buttons, and stops by itself after 10 minutes.',
            style: TextStyle(height: 1.45),
          ),
          const SectionLabel('Will it ring?'),
          Card(
            child: Column(
              children: [
                check(
                  'Notifications',
                  'Allowed',
                  'Off. No alarm can show until you allow them.',
                  health?.notifications,
                  () async => (await ref.read(reminderRepositoryProvider.future)).requestNotificationPermission(),
                ),
                const Divider(height: 1),
                check(
                  'Exact times',
                  'Alarms ring at the minute you set',
                  'Alarms may come late. Allow exact alarms for Amrutham.',
                  health?.exact,
                  () async => (await ref.read(reminderRepositoryProvider.future)).requestExactAlarmPermission(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('Over the lock screen', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Let an alarm light up the screen when the phone is locked'),
                  trailing: TextButton(
                    onPressed: () async => (await ref.read(reminderRepositoryProvider.future)).requestFullScreenAlarms(),
                    child: const Text('Allow'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "If alarms are late or missing, also check your phone's Do Not Disturb and battery saver settings: some phones stop apps that are closed.",
            style: TextStyle(color: onboardMuted, fontSize: 12.5, height: 1.4),
          ),
          SectionLabel(rows.isEmpty ? 'Your alarms' : 'Your alarms (${rows.length})'),
          if (rows.isEmpty)
            const Card(
              child: ListTile(
                title: Text('No alarms yet'),
                subtitle: Text('Add a medicine with times of day, and an alarm is set for each time.'),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Text(rows[i].time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      title: Text('${rows[i].medicine} ${rows[i].dose}'.trim(), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${rows[i].person} · ${rows[i].days}'),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () async {
              await (await ref.read(reminderRepositoryProvider.future)).testAlarm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A test alarm will ring in 10 seconds. You can lock the phone.')),
                );
              }
            },
            child: const Text('Ring a test alarm in 10 seconds'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () async {
              final people = await ref.read(profilesProvider.future);
              await (await ref.read(reminderRepositoryProvider.future)).rearm([for (final p in people) if (!p.isDeceased) p.id]);
              ref.invalidate(alarmRowsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All alarms set again.')));
              }
            },
            child: const Text('Set all alarms again'),
          ),
        ],
      ),
    );
  }
}
