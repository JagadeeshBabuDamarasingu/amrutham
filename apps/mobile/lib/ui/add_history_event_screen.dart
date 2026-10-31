import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/history_event.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// A visit, procedure or scan. Pick a future date for something planned.
/// Pass [editing] to change a saved one.
class AddHistoryEventScreen extends ConsumerStatefulWidget {
  const AddHistoryEventScreen({super.key, required this.personId, this.editing});

  final PersonId personId;
  final HistoryEvent? editing;

  @override
  ConsumerState<AddHistoryEventScreen> createState() => _State();
}

class _State extends ConsumerState<AddHistoryEventScreen> {
  late HistoryKind _kind = widget.editing?.kind ?? HistoryKind.visit;
  late final _title = TextEditingController(text: widget.editing?.title);
  late final _provider = TextEditingController(text: widget.editing?.provider);
  late final _notes = TextEditingController(text: widget.editing?.notes);
  late DateTime _date = widget.editing?.eventDate ?? DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _provider.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String? _nullIfEmpty(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(historyRepositoryProvider.future);
    final editing = widget.editing;
    if (editing == null) {
      await repository.addEvent(
        personId: widget.personId,
        kind: _kind,
        title: _title.text.trim(),
        eventDate: _date,
        provider: _nullIfEmpty(_provider),
        notes: _nullIfEmpty(_notes),
      );
    } else {
      await repository.updateEvent(
        editing.id,
        kind: _kind,
        title: _title.text.trim(),
        eventDate: _date,
        provider: _nullIfEmpty(_provider),
        notes: _nullIfEmpty(_notes),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final planned = _date.isAfter(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: Text(widget.editing == null ? 'Add to history' : 'Edit history entry')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const SectionLabel('What'),
          Wrap(
            spacing: 8,
            children: [
              for (final k in HistoryKind.values)
                ChoiceChip(
                  label: Text(k.label),
                  selected: k == _kind,
                  onSelected: (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SectionLabel('Title'),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Short title'),
          ),
          const SectionLabel('Date'),
          OutlinedButton(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              '${_date.day} ${monthNames[_date.month - 1]} ${_date.year}'
              '${planned ? ' · planned' : ''}',
            ),
          ),
          const SectionLabel('Doctor or hospital (optional)'),
          TextField(
            controller: _provider,
            decoration: const InputDecoration(hintText: 'Doctor or hospital'),
          ),
          const SectionLabel('Notes (optional)'),
          TextField(
            controller: _notes,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: widget.editing == null ? 'Save' : 'Save changes',
                  onPressed: _title.text.trim().isEmpty ? null : _save,
                ),
        ],
      ),
    );
  }
}
