import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/dose_log.dart';
import '../model/ids.dart';
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

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
  'September', 'October', 'November', 'December',
];

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPeople = ref.watch(profilesProvider).valueOrNull ?? const [];
    // Today is for the living; deceased members stay in Family.
    final people = allPeople.where((p) => !p.isDeceased).toList();
    final doses = ref.watch(todaysDosesProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final self = people
        .where((p) => p.relationship == RelationshipType.self)
        .firstOrNull;
    final selectedId = ref.watch(selectedPersonIdProvider);
    final selected =
        people.where((p) => p.id == selectedId).firstOrNull ?? self ?? people.firstOrNull;

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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}',
                        style: const TextStyle(color: onboardMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selected == null
                            ? _greeting(context, now)
                            : '${_greeting(context, now)},\n${selected.firstName}',
                        style: const TextStyle(
                          fontFamily: headingFont,
                          fontSize: 34,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          // The variable font needs its axes set explicitly;
                          // opsz follows the size, as the design's CSS does.
                          fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 34)],
                          letterSpacing: -0.68,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (people.length > 1) ...[
                      _AvatarStack(
                        people: people,
                        selectedId: selected?.id,
                        onSelect: (id) =>
                            ref.read(selectedPersonIdProvider.notifier).state = id,
                      ),
                      const SizedBox(height: 14),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RoundButton(
                          icon: Icons.add,
                          tooltip: 'Quick add',
                          dark: true,
                          onTap: () => _quickAdd(context, selected),
                        ),
                        const SizedBox(width: 8),
                        _RoundButton(
                          icon: Icons.settings_outlined,
                          tooltip: tr(context, 'Settings'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5E5DD),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.medication_outlined, size: 20, color: onboardInk),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.medicationName} ${d.doseAmount}'.trim(),
                              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              d.person.displayName,
                              style: const TextStyle(fontSize: 12.5, color: onboardMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        d.time.label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
            if (selected != null) ...[
              const SizedBox(height: 8),
              _NumbersCard(person: selected),
            ],
            if (lastAnswer != null && lastDose != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    Icon(
                      lastAnswer.status == DoseStatus.taken ? Icons.check : Icons.close,
                      size: 16,
                      color: onboardMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${lastAnswer.status == DoseStatus.taken ? 'Taken' : 'Missed'}: '
                        '${lastDose.medicationName} ${lastDose.doseAmount} · '
                        '${TimeOfDayLite(lastAnswer.loggedAt.hour, lastAnswer.loggedAt.minute).label}',
                        style: const TextStyle(color: onboardMuted, fontSize: 13),
                      ),
                    ),
                  ],
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
        Widget tile(int i) => InkWell(
          onTap: tiles[i].$4 == null ? null : () => go(sheet, tiles[i].$4!),
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: i == 0 ? const Color(0xFF244338) : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Opacity(
              opacity: tiles[i].$4 == null ? 0.4 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: i == 0 ? const Color(0xFF3B5A4D) : const Color(0xFFD5E5DD),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(tiles[i].$1, size: 20, color: i == 0 ? onboardAmber : onboardInk),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tiles[i].$2,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: i == 0 ? Colors.white : onboardInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tiles[i].$3,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: i == 0 ? const Color(0xFFB8D0C5) : onboardMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return SafeArea(
          // Scrolls instead of overflowing when the phone's text size is large.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: headingFont,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 28)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  person == null
                      ? 'Add a family member first.'
                      : 'For ${person.firstName}. Pick what you want to record.',
                  style: const TextStyle(color: onboardMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Tiles grow to fit their text; a fixed aspect ratio overflowed.
                for (var row = 0; row < tiles.length; row += 2)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: tile(row)),
                          const SizedBox(width: 10),
                          Expanded(child: tile(row + 1)),
                        ],
                      ),
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3B32),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dose.scheduledAt.isBefore(DateTime.now()) ? 'DUE' : 'NEXT DOSE'} · ${dose.time.label.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF9FC0B2),
              fontSize: 12.5,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dose.medicationName,
            style: const TextStyle(
              fontFamily: headingFont,
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w500,
              fontVariations: [FontVariation('wght', 500), FontVariation('opsz', 26)],
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${dose.doseAmount} · for ${dose.person.displayName}',
            style: const TextStyle(color: Color(0xFFB8D0C5), fontSize: 13.5),
          ),
          const SizedBox(height: 14),
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
                      backgroundColor: const Color(0x24FFFFFF),
                      minimumSize: const Size.fromHeight(46),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      side: const BorderSide(color: Color(0x38FFFFFF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
                  child: const Text(
                    "Today's numbers ›",
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LogMeasurementScreen(personId: person.id),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F3B32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '+ Log',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              for (final (i, kind) in shown.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final last = readings.where((m) => m.kind == kind).firstOrNull;
                      final tile = Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kind == MeasurementKind.bloodPressure ? 'BP' : kind.label,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: onboardMuted,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              last == null ? '+ Add' : last.display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: last == null ? 14 : 15.5,
                                fontWeight: FontWeight.w700,
                                color: last == null ? const Color(0xFF1F3B32) : null,
                              ),
                            ),
                          ],
                        ),
                      );
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LogMeasurementScreen(
                              personId: person.id,
                              initialKind: kind,
                            ),
                          ),
                        ),
                        child: last == null
                            ? CustomPaint(painter: _DashedBorder(), child: tile)
                            : Ink(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: tile,
                              ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The dashed outline of an empty reading tile in the Today frame.
class _DashedBorder extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC5D2CC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.75),
        const Radius.circular(12),
      ));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => false;
}

/// Overlapping circles for the family, with a "+N" bubble past three people.
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.people, required this.selectedId, required this.onSelect});

  final List<PersonProfile> people;
  final PersonId? selectedId;
  final ValueChanged<PersonId> onSelect;

  @override
  Widget build(BuildContext context) {
    final overflow = people.length > 3;
    final visible = overflow ? people.take(2).toList() : people;
    Widget circle(Color bg, Color fg, String text, bool selected, VoidCallback onTap) =>
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? onboardInk : onboardBg, width: 2),
            ),
            child: Text(text, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        );
    final count = visible.length + (overflow ? 1 : 0);
    return SizedBox(
      width: 38.0 + 28 * (count - 1),
      height: 38,
      child: Stack(
        children: [
          // Selected last, so its ring is never covered by a neighbour.
          for (final (i, p) in [...visible.indexed]
            ..sort((a, b) => (a.$2.id == selectedId ? 1 : 0) - (b.$2.id == selectedId ? 1 : 0)))
            Positioned(
              left: 28.0 * i,
              child: () {
                final (bg, fg) = avatarColors(i);
                final name = p.displayName.trim();
                return circle(bg, fg, name.isEmpty ? '?' : name[0].toUpperCase(),
                    p.id == selectedId, () => onSelect(p.id));
              }(),
            ),
          if (overflow)
            Positioned(
              left: 28.0 * visible.length,
              child: circle(
                const Color(0xFF1F3B32),
                Colors.white,
                '+${people.length - 2}',
                false,
                () => _pick(context),
              ),
            ),
        ],
      ),
    );
  }

  void _pick(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in people)
              ListTile(
                leading: PersonAvatar(name: p.displayName, size: 40),
                title: Text(p.displayName),
                selected: p.id == selectedId,
                onTap: () {
                  Navigator.pop(sheet);
                  onSelect(p.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: dark ? const Color(0xFF1F3B32) : Colors.white,
        elevation: dark ? 0 : 1,
        shadowColor: const Color(0x1414201C),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: dark ? Colors.white : const Color(0xFF1F3B32)),
          ),
        ),
      ),
    );
  }
}
