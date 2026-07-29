import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/person.dart';
import '../providers/app_providers.dart';
import 'profile_detail_screen.dart';

/// F1 acceptance: a full profile can be created in under 5 minutes on a
/// phone, with no field mandatory except display name. See
/// specs/phase-1-v1/01-features.md F1.
class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _sexController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  RelationshipType _relationship = RelationshipType.self;
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _sexController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = await ref.read(profileRepositoryProvider.future);
    final profile = await repository.createProfile(
      displayName: _displayNameController.text.trim(),
      relationship: _relationship,
      dateOfBirth: _dateOfBirth,
      sex: _sexController.text.trim().isEmpty
          ? null
          : _sexController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim().isEmpty
          ? null
          : _bloodGroupController.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(personId: profile.id),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: _dateOfBirth ?? DateTime(1990),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RelationshipType>(
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: RelationshipType.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(_relationshipLabel(r)),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _relationship = value ?? _relationship),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _dateOfBirth == null
                    ? 'Date of birth (optional)'
                    : 'Date of birth: ${_dateOfBirth!.toIso8601String().split('T').first}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateOfBirth,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sexController,
              decoration: const InputDecoration(labelText: 'Sex (optional)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bloodGroupController,
              decoration: const InputDecoration(
                labelText: 'Blood group (optional)',
              ),
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
                  : const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }

  String _relationshipLabel(RelationshipType type) {
    switch (type) {
      case RelationshipType.self:
        return 'Myself';
      case RelationshipType.child:
        return 'Child';
      case RelationshipType.parent:
        return 'Parent';
      case RelationshipType.otherDependent:
        return 'Other dependent';
    }
  }
}
