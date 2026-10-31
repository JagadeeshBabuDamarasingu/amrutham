import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/allergy.dart';
import '../model/certainty.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

class AddAllergyScreen extends ConsumerStatefulWidget {
  const AddAllergyScreen({super.key, required this.personId, this.editing});

  final PersonId personId;
  final AllergyRecord? editing;

  @override
  ConsumerState<AddAllergyScreen> createState() => _AddAllergyScreenState();
}

class _AddAllergyScreenState extends ConsumerState<AddAllergyScreen> {
  late final _substanceController = TextEditingController(text: widget.editing?.substance);
  late final _reactionController = TextEditingController(text: widget.editing?.reaction);
  late final _severityController = TextEditingController(text: widget.editing?.severity);
  late final _notesController = TextEditingController(text: widget.editing?.notes);
  late Certainty _certainty = widget.editing?.certainty ?? Certainty.reported;
  bool _saving = false;

  @override
  void dispose() {
    _substanceController.dispose();
    _reactionController.dispose();
    _severityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final repository = await ref.read(profileRepositoryProvider.future);
    final severity = _severityController.text.trim().isEmpty
        ? null
        : _severityController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final editing = widget.editing;
    if (editing == null) {
      await repository.addAllergyRecord(
        personId: widget.personId,
        substance: _substanceController.text.trim(),
        reaction: _reactionController.text.trim(),
        severity: severity,
        certainty: _certainty,
        notes: notes,
      );
    } else {
      await repository.updateAllergyRecord(
        editing.id,
        substance: _substanceController.text.trim(),
        reaction: _reactionController.text.trim(),
        severity: severity,
        certainty: _certainty,
        notes: notes,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool get _valid =>
      _substanceController.text.trim().isNotEmpty &&
      _reactionController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 88,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(
            widget.editing == null ? 'Add an allergy' : 'Edit allergy',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SectionLabel('Substance'),
          TextField(
            controller: _substanceController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What you are allergic to'),
          ),
          const SectionLabel('Reaction'),
          TextField(
            controller: _reactionController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'What happens'),
          ),
          const SectionLabel('How sure are you'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in Certainty.values)
                ChoiceChip(
                  label: Text(_certaintyLabel(c)),
                  selected: _certainty == c,
                  onSelected: (_) => setState(() => _certainty = c),
                ),
            ],
          ),
          const SectionLabel('Severity (optional)'),
          TextField(controller: _severityController),
          const SectionLabel('Notes (optional)'),
          TextField(controller: _notesController, maxLines: 3),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(label: widget.editing == null ? 'Save allergy' : 'Save changes', onPressed: _valid ? _save : null),
        ],
      ),
    );
  }

  static String _certaintyLabel(Certainty c) => switch (c) {
    Certainty.confirmed => 'Confirmed by a doctor',
    Certainty.reported => 'Reported',
    Certainty.suspected => 'Suspected',
  };
}
