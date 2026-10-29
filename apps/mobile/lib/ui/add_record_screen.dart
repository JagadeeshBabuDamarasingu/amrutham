import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../model/health_record.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// File a document: scan with the camera, pick photos, or pick files.
class AddRecordScreen extends ConsumerStatefulWidget {
  const AddRecordScreen({super.key, this.personId, this.type, this.title});

  final PersonId? personId;
  final RecordType? type;
  final String? title;

  @override
  ConsumerState<AddRecordScreen> createState() => _State();
}

class _State extends ConsumerState<AddRecordScreen> {
  final List<File> _files = [];
  PersonId? _person;
  RecordType _type = RecordType.prescription;
  final _title = TextEditingController();
  final _source = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _person = widget.personId;
    if (widget.type != null) _type = widget.type!;
    if (widget.title != null) _title.text = widget.title!;
  }

  @override
  void dispose() {
    _title.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final shot = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 90);
    if (shot != null) setState(() => _files.add(File(shot.path)));
  }

  Future<void> _photos() async {
    final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
    setState(() => _files.addAll(picked.map((x) => File(x.path))));
  }

  Future<void> _pickFiles() async {
    final picked = await FilePicker.pickFiles();
    setState(
      () => _files.addAll(picked.map((f) => f.path).whereType<String>().map(File.new)),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  bool get _valid => _files.isNotEmpty && _person != null && _title.text.trim().isNotEmpty;

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(recordRepositoryProvider.future);
    await repository.add(
      personId: _person!,
      type: _type,
      title: _title.text.trim(),
      recordDate: _date,
      source: _source.text.trim().isEmpty ? null : _source.text.trim(),
      sources: _files,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    Widget source(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 76,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Icon(icon), const SizedBox(height: 4), Text(label, style: const TextStyle(fontWeight: FontWeight.w700))],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        leadingWidth: 88,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const Text('Add a record', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 16),
          Row(
            children: [
              source(Icons.photo_camera_outlined, 'Scan', _scan),
              const SizedBox(width: 10),
              source(Icons.image_outlined, 'Photos', _photos),
              const SizedBox(width: 10),
              source(Icons.insert_drive_file_outlined, 'Files', _pickFiles),
            ],
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFE3ECE7), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_files.length} ${_files.length == 1 ? 'page' : 'pages'} added',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(onPressed: () => setState(_files.clear), child: const Text('Clear')),
                ],
              ),
            ),
          ],
          const SectionLabel('For'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in people)
                ChoiceChip(
                  label: Text(p.displayName),
                  selected: _person == p.id,
                  onSelected: (_) => setState(() => _person = p.id),
                ),
            ],
          ),
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
            decoration: const InputDecoration(hintText: 'Blood panel report'),
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
            decoration: const InputDecoration(hintText: 'Vijaya Diagnostics'),
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(label: 'Save to vault', onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}
