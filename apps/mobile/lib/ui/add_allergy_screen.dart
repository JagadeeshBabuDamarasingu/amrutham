import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/certainty.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';

class AddAllergyScreen extends ConsumerStatefulWidget {
  const AddAllergyScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<AddAllergyScreen> createState() => _AddAllergyScreenState();
}

class _AddAllergyScreenState extends ConsumerState<AddAllergyScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add allergy')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _substanceController,
              decoration: const InputDecoration(
                labelText: 'Substance (e.g. penicillin, peanuts)',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Substance is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reactionController,
              decoration: const InputDecoration(labelText: 'Reaction'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Reaction is required'
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
              controller: _severityController,
              decoration: const InputDecoration(
                labelText: 'Severity (optional)',
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
                  : const Text('Save allergy'),
            ),
          ],
        ),
      ),
    );
  }
}
