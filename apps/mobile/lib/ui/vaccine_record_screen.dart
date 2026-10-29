import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/health_record.dart';
import '../model/history_event.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'add_record_screen.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show dateLabel;

/// Vaccines a person has had, as the vaccination card states them. Amrutham
/// never says what is due: the schedule changes, so it points to the official
/// source instead.
class VaccineRecordScreen extends ConsumerWidget {
  const VaccineRecordScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == personId)
        .firstOrNull;
    final vaccines = (ref.watch(historyEventsProvider(personId)).valueOrNull ?? [])
        .where((e) => e.kind == HistoryKind.vaccine)
        .toList();
    final given = vaccines.where((e) => !e.isPlanned).toList();
    final next = (vaccines.where((e) => e.isPlanned).toList()
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate)))
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Vaccines')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (person != null)
            Row(
              children: [
                PersonAvatar(name: person.displayName, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    person.displayName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD5E4DC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'You enter what the vaccination card says. Amrutham does not know '
              "the schedule, so it never says what is due.",
              style: TextStyle(color: onboardMuted, height: 1.4),
            ),
          ),
          const SectionLabel('Given'),
          if (given.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nothing recorded yet.'),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final e in given)
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFD5E4DC),
                        child: Icon(Icons.check, color: onboardInk),
                      ),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [dateLabel(e.eventDate), if (e.provider != null) e.provider!].join(' · '),
                      ),
                      onLongPress: () => _confirmDelete(context, ref, e),
                    ),
                ],
              ),
            ),
          if (next != null) ...[
            const SectionLabel('Next visit'),
            GestureDetector(
              onLongPress: () => _confirmDelete(context, ref, next),
              child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEFD0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DATE YOU SET',
                    style: TextStyle(fontSize: 11, color: Color(0xFF5A4300), letterSpacing: 0.6),
                  ),
                  Text(
                    dateLabel(next.eventDate),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  if (next.title.isNotEmpty) Text(next.title),
                  _VisitReminder(event: next),
                ],
              ),
            ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OnboardButton(
                  label: '+ Add a vaccine',
                  onPressed: () => _add(context, ref),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddRecordScreen(
                        personId: personId,
                        type: RecordType.vaccineCard,
                        title: 'Vaccination card',
                      ),
                    ),
                  ),
                  child: const Text('Photo of card'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => launchUrl(
              Uri.parse('https://www.mohfw.gov.in'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'For what is due, check the official schedule ›',
                style: TextStyle(color: onboardInk, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_NewVaccine>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddVaccineSheet(),
    );
    if (result == null) return;
    final repository = await ref.read(historyRepositoryProvider.future);
    await repository.addEvent(
      personId: personId,
      kind: HistoryKind.vaccine,
      title: result.name,
      eventDate: result.date,
      provider: result.place,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, HistoryEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this vaccine?'),
        content: Text(e.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final repository = await ref.read(historyRepositoryProvider.future);
    await repository.deleteEvent(e.id);
    final reminders = await ref.read(reminderRepositoryProvider.future);
    await reminders.setVisitReminder(id: e.id, title: e.title, visit: e.eventDate, on: false);
  }
}

class _NewVaccine {
  const _NewVaccine(this.name, this.date, this.place);
  final String name;
  final DateTime date;
  final String? place;
}

/// Pick a future date to note an upcoming visit instead of a given dose.
class _AddVaccineSheet extends StatefulWidget {
  const _AddVaccineSheet();

  @override
  State<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends State<_AddVaccineSheet> {
  final _name = TextEditingController();
  final _place = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Vaccine, as written on the card'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _place,
            decoration: const InputDecoration(labelText: 'Where (optional)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _pickDate,
            child: Text(
              _date.isAfter(DateTime.now())
                  ? 'Next visit · ${dateLabel(_date)}'
                  : 'Given on ${dateLabel(_date)}',
            ),
          ),
          const SizedBox(height: 12),
          OnboardButton(
            label: 'Save',
            onPressed: _name.text.trim().isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    _NewVaccine(
                      _name.text.trim(),
                      _date,
                      _place.text.trim().isEmpty ? null : _place.text.trim(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// "Remind me the day before": off until the person turns it on.
class _VisitReminder extends ConsumerStatefulWidget {
  const _VisitReminder({required this.event});

  final HistoryEvent event;

  @override
  ConsumerState<_VisitReminder> createState() => _VisitReminderState();
}

class _VisitReminderState extends ConsumerState<_VisitReminder> {
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final reminders = await ref.read(reminderRepositoryProvider.future);
    final on = await reminders.hasVisitReminder(widget.event.id);
    if (mounted) setState(() => _on = on);
  }

  Future<void> _toggle(bool value) async {
    final reminders = await ref.read(reminderRepositoryProvider.future);
    if (value) await reminders.requestNotificationPermission();
    final ok = await reminders.setVisitReminder(
      id: widget.event.id,
      title: widget.event.title,
      visit: widget.event.eventDate,
      on: value,
    );
    if (!mounted) return;
    setState(() => _on = value && ok);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That is too soon to remind you the day before.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Remind me the day before'),
      value: _on,
      onChanged: _toggle,
    );
  }
}
