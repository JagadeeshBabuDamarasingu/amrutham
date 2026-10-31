import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/health_record.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// Changes a filed record's type, title, date and source. The files and the
/// person stay as they are.
class EditRecordScreen extends ConsumerStatefulWidget {
  const EditRecordScreen({super.key, required this.record});

  final HealthRecord record;

  @override
  ConsumerState<EditRecordScreen> createState() => _State();
}

class _State extends ConsumerState<EditRecordScreen> {
  late RecordType _type = widget.record.type;
  late final _title = TextEditingController(text: widget.record.title);
  late final _source = TextEditingController(text: widget.record.source);
  late DateTime _date = widget.record.recordDate;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(recordRepositoryProvider.future);
    await repository.update(
      widget.record.id,
      type: _type,
      title: _title.text.trim(),
      recordDate: _date,
      source: _source.text.trim().isEmpty ? null : _source.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        leadingWidth: 88,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const Text('Edit record', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SectionLabel('Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in RecordType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SectionLabel('Title and date'),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Title'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), alignment: Alignment.centerLeft),
            child: Text('${_date.day} ${monthNames[_date.month - 1]} ${_date.year}'),
          ),
          const SectionLabel('From (optional)'),
          TextField(
            controller: _source,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Where it was done'),
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: 'Save changes',
                  onPressed: _title.text.trim().isEmpty ? null : _save,
                ),
        ],
      ),
    );
  }
}
