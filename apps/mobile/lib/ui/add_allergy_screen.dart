import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/certainty.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

class AddAllergyScreen extends ConsumerStatefulWidget {
  const AddAllergyScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<AddAllergyScreen> createState() => _AddAllergyScreenState();
}

class _AddAllergyScreenState extends ConsumerState<AddAllergyScreen> {
  final _substanceController = TextEditingController();
  final _reactionController = TextEditingController();
  final _severityController = TextEditingController();
  final _notesController = TextEditingController();
  Certainty _certainty = Certainty.reported;
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
    await repository.addAllergyRecord(
      personId: widget.personId,
      substance: _substanceController.text.trim(),
      reaction: _reactionController.text.trim(),
      severity: _severityController.text.trim().isEmpty
          ? null
          : _severityController.text.trim(),
      certainty: _certainty,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

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
          const Text(
            'Add an allergy',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SectionLabel('Substance'),
          TextField(
            controller: _substanceController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Penicillin, peanuts…'),
          ),
          const SectionLabel('Reaction'),
          TextField(
            controller: _reactionController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Rash'),
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
              : OnboardButton(label: 'Save allergy', onPressed: _valid ? _save : null),
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
