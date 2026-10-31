import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/history_event.dart';
import '../model/ids.dart';
import '../model/medication.dart';
import '../providers/app_providers.dart';
import 'add_history_event_screen.dart';
import 'app_style.dart';
import 'item_actions.dart';
import 'log_measurement_screen.dart' show monthNames;

enum _Filter {
  all('All'),
  visit('Visits'),
  medicine('Medicines'),
  procedure('Procedures'),
  scan('Scans');

  const _Filter(this.label);
  final String label;
}

class _Item {
  _Item({
    required this.date,
    required this.tag,
    required this.title,
    required this.filter,
    required this.color,
    this.subtitle,
    this.event,
  });

  final DateTime date;
  final String tag;
  final String title;
  final String? subtitle;
  final _Filter filter;
  final Color color;
  final HistoryEvent? event; // null for medicine rows, which aren't deletable here

  bool get planned => date.isAfter(DateTime.now());
}

/// One chronological view of a person's medical history: logged events plus
/// medicine courses, upcoming first, then by year.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Filter _filter = _Filter.all;

  List<_Item> _items(List<HistoryEvent> events, List<MedicationCourse> courses) {
    return [
      for (final e in events)
        _Item(
          date: e.eventDate,
          tag: e.kind.label.toUpperCase(),
          title: e.title,
          subtitle: e.provider,
          filter: switch (e.kind) {
            HistoryKind.visit => _Filter.visit,
            HistoryKind.procedure => _Filter.procedure,
            HistoryKind.scan => _Filter.scan,
            HistoryKind.vaccine || HistoryKind.other => _Filter.all,
          },
          color: switch (e.kind) {
            HistoryKind.visit => const Color(0xFF6A9080),
            HistoryKind.procedure => onboardInk,
            HistoryKind.scan => const Color(0xFFA9C4B6),
            HistoryKind.vaccine => const Color(0xFFD5E4DC),
            HistoryKind.other => onboardMuted,
          },
          event: e,
        ),
      for (final c in courses)
        _Item(
          date: c.startDate,
          tag: 'MEDICINE STARTED',
          title: c.medicationName,
          subtitle: c.endDate != null
              ? 'Ends ${c.endDate!.day} ${monthNames[c.endDate!.month - 1]}'
              : c.status == CourseStatus.active
              ? 'Ongoing'
              : c.status.name,
          filter: _Filter.medicine,
          color: onboardAmber,
        ),
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _actions(_Item item) async {
    final event = item.event;
    if (event == null) return;
    await showItemActions(
      context,
      title: event.title,
      onEdit: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddHistoryEventScreen(personId: widget.personId, editing: event),
        ),
      ),
      onDelete: () async {
        final repository = await ref.read(historyRepositoryProvider.future);
        await repository.deleteEvent(event.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(historyEventsProvider(widget.personId));
    final courses = ref.watch(medicationCoursesProvider(widget.personId));
    final all = _items(events.valueOrNull ?? [], courses.valueOrNull ?? []);
    final shown = [
      for (final i in all)
        if (_filter == _Filter.all || i.filter == _filter) i,
    ];
    final upcoming = shown.where((i) => i.planned).toList().reversed.toList();
    final past = shown.where((i) => !i.planned).toList();

    final children = <Widget>[];
    if (upcoming.isNotEmpty) {
      children.add(const SectionLabel('Upcoming'));
      children.addAll(upcoming.map((i) => _row(i)));
    }
    int? year;
    for (final i in past) {
      if (i.date.year != year) {
        year = i.date.year;
        children.add(SectionLabel('$year'));
      }
      children.add(_row(i));
    }

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddHistoryEventScreen(personId: widget.personId),
          ),
        ),
        backgroundColor: onboardInk,
        foregroundColor: Colors.white,
        label: const Text('+ Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const Text(
            'Medical history',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f.label),
                      selected: f == _filter,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'Nothing here yet. Tap "+ Add" for a visit, procedure or '
                'scan. Medicines appear on their own.',
                style: TextStyle(color: onboardMuted, height: 1.4),
              ),
            ),
          ...children,
        ],
      ),
    );
  }

  Widget _row(_Item item) {
    final d = item.date;
    final label =
        '${d.day} ${monthNames[d.month - 1].toUpperCase()}'
        '${item.planned || d.year != DateTime.now().year ? ' ${d.year}' : ''}';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: item.planned ? Colors.white : item.color,
                    shape: BoxShape.circle,
                    border: item.planned
                        ? Border.all(color: onboardAmber, width: 3)
                        : null,
                  ),
                ),
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFD5E4DC)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: item.event == null ? null : () => _actions(item),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: item.planned
                        ? const Color(0xFFFAEFD0)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: item.planned
                        ? Border.all(color: onboardAmber)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$label · ${item.planned && item.tag != 'MEDICINE STARTED' ? 'PLANNED' : item.tag}',
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: onboardMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          style: const TextStyle(
                            color: onboardMuted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
