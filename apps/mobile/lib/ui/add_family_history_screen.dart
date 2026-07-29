import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/certainty.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';

class AddFamilyHistoryScreen extends ConsumerStatefulWidget {
  const AddFamilyHistoryScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<AddFamilyHistoryScreen> createState() =>
      _AddFamilyHistoryScreenState();
}

class _AddFamilyHistoryScreenState
    extends ConsumerState<AddFamilyHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add family history')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship (e.g. mother, paternal uncle)',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Relationship is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _conditionController,
              decoration: const InputDecoration(labelText: 'Condition'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Condition is required'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Certainty>(
              initialValue: _certainty,
              decoration: const InputDecoration(labelText: 'Certainty'),
              items: Certainty.values
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _certainty = value ?? _certainty),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _onsetAgeController,
              decoration: const InputDecoration(
                labelText: 'Approx. age at onset (optional)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _outcomeController,
              decoration: const InputDecoration(
                labelText: 'Outcome (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save entry'),
            ),
          ],
        ),
      ),
    );
  }
}
