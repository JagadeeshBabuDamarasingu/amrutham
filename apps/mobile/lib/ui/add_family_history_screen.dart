import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/certainty.dart';
import '../model/family_history.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

class AddFamilyHistoryScreen extends ConsumerStatefulWidget {
  const AddFamilyHistoryScreen({super.key, required this.personId, this.editing});

  final PersonId personId;
  final FamilyHistoryEntry? editing;

  @override
  ConsumerState<AddFamilyHistoryScreen> createState() =>
      _AddFamilyHistoryScreenState();
}

class _AddFamilyHistoryScreenState
    extends ConsumerState<AddFamilyHistoryScreen> {
  late final _relationshipController = TextEditingController(text: widget.editing?.relationship);
  late final _conditionController = TextEditingController(text: widget.editing?.conditionText);
  late final _onsetAgeController = TextEditingController(text: widget.editing?.onsetAgeApprox?.toString());
  late final _outcomeController = TextEditingController(text: widget.editing?.outcome);
  late final _notesController = TextEditingController(text: widget.editing?.notes);
  late Certainty _certainty = widget.editing?.certainty ?? Certainty.reported;
  bool _saving = false;

  @override
  void dispose() {
    _relationshipController.dispose();
    _conditionController.dispose();
    _onsetAgeController.dispose();
    _outcomeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final repository = await ref.read(profileRepositoryProvider.future);
    final outcome = _outcomeController.text.trim().isEmpty
        ? null
        : _outcomeController.text.trim();
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final onset = int.tryParse(_onsetAgeController.text.trim());
    final editing = widget.editing;
    if (editing == null) {
      await repository.addFamilyHistoryEntry(
        personId: widget.personId,
        relationship: _relationshipController.text.trim(),
        conditionText: _conditionController.text.trim(),
        onsetAgeApprox: onset,
        outcome: outcome,
        certainty: _certainty,
        notes: notes,
      );
    } else {
      await repository.updateFamilyHistoryEntry(
        editing.id,
        relationship: _relationshipController.text.trim(),
        conditionText: _conditionController.text.trim(),
        onsetAgeApprox: onset,
        outcome: outcome,
        certainty: _certainty,
        notes: notes,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool get _valid =>
      _relationshipController.text.trim().isNotEmpty &&
      _conditionController.text.trim().isNotEmpty;

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
            widget.editing == null ? 'Add family history' : 'Edit family history',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Recorded as you know it. Never scored or turned into a risk.',
            style: TextStyle(color: onboardMuted),
          ),
          const SectionLabel('Which relative'),
          TextField(
            controller: _relationshipController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Which relative'),
          ),
          const SectionLabel('Condition'),
          TextField(
            controller: _conditionController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SectionLabel('How sure are you'),
          Wrap(
            spacing: 8,
            children: [
              for (final c in Certainty.values)
                ChoiceChip(
                  label: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                  selected: _certainty == c,
                  onSelected: (_) => setState(() => _certainty = c),
                ),
            ],
          ),
          const SectionLabel('Approx. age at onset (optional)'),
          TextField(
            controller: _onsetAgeController,
            keyboardType: TextInputType.number,
          ),
          const SectionLabel('Outcome (optional)'),
          TextField(controller: _outcomeController),
          const SectionLabel('Notes (optional)'),
          TextField(controller: _notesController, maxLines: 3),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(label: widget.editing == null ? 'Save' : 'Save changes', onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}
