import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/medication.dart';
import '../providers/app_providers.dart';
import 'add_schedule_phase_screen.dart';

/// Step 1 of F2's "add a 3-phase taper in under 2 minutes" flow — the
/// course itself. Saving hands straight off to AddSchedulePhaseScreen for
/// the first phase, since a course with no phase yet has nothing to remind
/// anyone about. See specs/phase-1-v1/01-features.md F2.
class AddMedicationCourseScreen extends ConsumerStatefulWidget {
  const AddMedicationCourseScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<AddMedicationCourseScreen> createState() =>
      _AddMedicationCourseScreenState();
}

class _AddMedicationCourseScreenState
    extends ConsumerState<AddMedicationCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _prescriberController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _prescriberController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repository = await ref.read(medicationRepositoryProvider.future);
    final course = await repository.createCourse(
      personId: widget.personId,
      medicationName: _nameController.text.trim(),
      status: CourseStatus.active,
      startDate: DateTime.now(),
      prescriberName: _prescriberController.text.trim().isEmpty
          ? null
          : _prescriberController.text.trim(),
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AddSchedulePhaseScreen(
          personId: widget.personId,
          courseId: course.id,
          isFirstPhase: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add medication')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Medication name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Medication name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prescriberController,
              decoration: const InputDecoration(
                labelText: 'Prescriber (optional)',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _continue,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Next: set the schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
