import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/certainty.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

class AddFamilyHistoryScreen extends ConsumerStatefulWidget {
  const AddFamilyHistoryScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<AddFamilyHistoryScreen> createState() =>
      _AddFamilyHistoryScreenState();
}

class _AddFamilyHistoryScreenState
    extends ConsumerState<AddFamilyHistoryScreen> {
  final _relationshipController = TextEditingController();
  final _conditionController = TextEditingController();
  final _onsetAgeController = TextEditingController();
  final _outcomeController = TextEditingController();
  final _notesController = TextEditingController();
  Certainty _certainty = Certainty.reported;
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
    await repository.addFamilyHistoryEntry(
      personId: widget.personId,
      relationship: _relationshipController.text.trim(),
      conditionText: _conditionController.text.trim(),
      onsetAgeApprox: int.tryParse(_onsetAgeController.text.trim()),
      outcome: _outcomeController.text.trim().isEmpty
          ? null
          : _outcomeController.text.trim(),
      certainty: _certainty,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

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
          const Text(
            'Add family history',
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
              : OnboardButton(label: 'Save', onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}
