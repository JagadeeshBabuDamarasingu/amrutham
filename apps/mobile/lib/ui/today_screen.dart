import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/dose_log.dart';
import '../model/measurement.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'strings.dart';
import 'add_expense_screen.dart';
import 'add_history_event_screen.dart';
import 'add_medication_course_screen.dart';
import 'add_record_screen.dart';
import 'create_profile_screen.dart';
import 'log_measurement_screen.dart';
import 'metrics_screen.dart';
import 'settings_screen.dart';

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(profilesProvider).valueOrNull ?? const [];
    final doses = ref.watch(todaysDosesProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final self = people
        .where((p) => p.relationship == RelationshipType.self)
        .firstOrNull;
    final selectedId = ref.watch(selectedPersonIdProvider);
    final selected =
        people.where((p) => p.id == selectedId).firstOrNull ??
        people.firstOrNull;

    final logs = ref.watch(todaysDoseLogsProvider).valueOrNull ?? const [];
    final answered = {for (final l in logs) l.key};
    final pending = [
      for (final d in doses)
        if (!answered.contains(DoseLog.keyFor(d.courseId, d.scheduledAt))) d,
    ];
    final next = pending.firstOrNull;
    final later = pending.skip(1).toList();
    final lastAnswer = logs.firstOrNull;
    final lastDose = lastAnswer == null
        ? null
        : doses
              .where(
                (d) =>
                    DoseLog.keyFor(d.courseId, d.scheduledAt) == lastAnswer.key,
              )
              .firstOrNull;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weekdays[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}',
                      style: const TextStyle(color: onboardMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      self == null
                          ? _greeting(context, now)
                          : '${_greeting(context, now)},\n${self.displayName.split(' ').first}',
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: () => _quickAdd(context, selected),
                icon: const Icon(Icons.add),
                tooltip: 'Quick add',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings_outlined),
                tooltip: tr(context, 'Settings'),
              ),
            ],
          ),
          if (people.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < people.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(selectedPersonIdProvider.notifier)
                            .state = people[i].id,
                        child: Opacity(
                          opacity: people[i].id == selected?.id ? 1 : 0.55,
                          child: PersonAvatar(
                            name: people[i].displayName,
                            colorIndex: i,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (people.isEmpty)
            _EmptyToday(onAdd: () => _addPerson(context))
          else ...[
            if (next != null)
              _NextDoseCard(
                dose: next,
                onAnswer: (status) async {
                  final repository = await ref.read(
                    doseLogRepositoryProvider.future,
                  );
                  await repository.logDose(
                    personId: next.person.id,
                    courseId: next.courseId,
                    scheduledAt: next.scheduledAt,
                    status: status,
                  );
                },
              ),
            if (next == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    doses.isEmpty
                        ? 'No doses scheduled today.'
                        : 'All of today\'s doses are answered.',
                  ),
                ),
              ),
            if (later.isNotEmpty) ...[
              SectionLabel(tr(context, 'Later today')),
              for (final d in later)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFD5E4DC),
                        child: Icon(Icons.medication_outlined, color: onboardInk),
                      ),
                      title: Text(
                        '${d.medicationName} ${d.doseAmount}'.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(d.person.displayName),
                      trailing: Text(
                        d.time.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
            if (selected != null) ...[
              const SizedBox(height: 8),
              _NumbersCard(person: selected),
            ],
            if (lastAnswer != null && lastDose != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4),
                child: Text(
                  '${lastAnswer.status == DoseStatus.taken ? 'Taken' : 'Missed'}: '
                  '${lastDose.medicationName} ${lastDose.doseAmount} · '
                  '${TimeOfDayLite(lastAnswer.loggedAt.hour, lastAnswer.loggedAt.minute).label}',
                  style: const TextStyle(color: onboardMuted, fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _greeting(BuildContext context, DateTime now) => tr(
    context,
    now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening',
  );

  void _addPerson(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
  );

  void _quickAdd(BuildContext context, PersonProfile? person) {
    void go(BuildContext sheet, Widget screen) {
      Navigator.pop(sheet);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }

    final id = person?.id;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        final tiles = <(IconData, String, String, Widget?)>[
          (Icons.monitor_heart_outlined, 'Log a measurement', 'Weight, BP, sugar',
              id == null ? null : LogMeasurementScreen(personId: id)),
          (Icons.medication_outlined, 'Add a medicine', 'Sets reminders',
              id == null ? null : AddMedicationCourseScreen(personId: id)),
          (Icons.photo_camera_outlined, 'Scan a document', 'Report, bill, prescription',
              id == null ? null : AddRecordScreen(personId: id)),
          (Icons.schedule, 'Add a visit or event', 'Doctor visit, surgery',
              id == null ? null : AddHistoryEventScreen(personId: id)),
          (Icons.currency_rupee, 'Add an expense', 'Bill or payment',
              id == null ? null : AddExpenseScreen(personId: id)),
          (Icons.person_add_alt, 'Add a family member', 'Name is enough', const CreateProfileScreen()),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                Text(
                  person == null
                      ? 'Add a family member first.'
                      : 'For ${person.displayName}. Pick what you want to record.',
                  style: const TextStyle(color: onboardMuted),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    for (var i = 0; i < tiles.length; i++)
                      InkWell(
                        onTap: tiles[i].$4 == null ? null : () => go(sheet, tiles[i].$4!),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: i == 0 ? onboardInk : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Opacity(
                            opacity: tiles[i].$4 == null ? 0.4 : 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: i == 0 ? const Color(0xFF3B5A4D) : const Color(0xFFD5E4DC),
                                  child: Icon(tiles[i].$1, size: 18, color: i == 0 ? onboardAmber : onboardInk),
                                ),
                                const Spacer(),
                                Text(
                                  tiles[i].$2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: i == 0 ? Colors.white : onboardInk,
                                  ),
                                ),
                                Text(
                                  tiles[i].$3,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: i == 0 ? const Color(0xFFB8D0C5) : onboardMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyToday extends StatelessWidget {
  const _EmptyToday({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Start with yourself, or anyone in the family.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Doses, measurements and history all hang off a person.',
              style: TextStyle(color: onboardMuted),
            ),
            const SizedBox(height: 16),
            OnboardButton(label: 'Add a person', onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}

class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard({required this.dose, required this.onAnswer});

  final TodayDose dose;
  final ValueChanged<DoseStatus> onAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: onboardInk,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dose.scheduledAt.isBefore(DateTime.now()) ? 'DUE' : 'NEXT DOSE'} · ${dose.time.label.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFFB8D0C5),
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dose.medicationName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${dose.doseAmount} · for ${dose.person.displayName}',
            style: const TextStyle(color: Color(0xFFB8D0C5), fontSize: 15),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (label, status) in [
                ('Taken', DoseStatus.taken),
                ('Missed', DoseStatus.missed),
              ]) ...[
                Expanded(
                  child: FilledButton(
                    onPressed: () => onAnswer(status),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5A4D),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(tr(context, label)),
                  ),
                ),
                if (status == DoseStatus.taken) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NumbersCard extends ConsumerWidget {
  const _NumbersCard({required this.person});

  final PersonProfile person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(measurementsProvider(person.id)).valueOrNull ?? [];
    const shown = [
      MeasurementKind.weight,
      MeasurementKind.bloodPressure,
      MeasurementKind.bloodSugar,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MetricsScreen(personId: person.id),
                      ),
                    ),
                    child: Text(
                      "${person.displayName}'s numbers ›",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LogMeasurementScreen(personId: person.id),
                    ),
                  ),
                  child: const Text('+ Log'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final kind in shown)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final last = readings
                            .where((m) => m.kind == kind)
                            .firstOrNull;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => LogMeasurementScreen(
                                personId: person.id,
                                initialKind: kind,
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: last == null ? null : onboardBg,
                              border: last == null
                                  ? Border.all(color: const Color(0xFFD5E4DC))
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kind == MeasurementKind.bloodPressure
                                      ? 'BP'
                                      : kind.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: onboardMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  last == null ? '+ Add' : last.display,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
