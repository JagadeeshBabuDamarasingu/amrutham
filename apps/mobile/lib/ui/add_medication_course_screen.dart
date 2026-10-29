import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/medication.dart';
import '../providers/app_providers.dart';
import 'add_schedule_phase_screen.dart';
import 'app_style.dart';

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
            'Add a medicine',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Next you set when to take it. Current medicines can send reminders.',
            style: TextStyle(color: onboardMuted),
          ),
          const SectionLabel('Name'),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Amoxicillin 500 mg'),
          ),
          const SectionLabel('Prescribed by (optional)'),
          TextField(controller: _prescriberController),
          const SectionLabel('Reason (optional)'),
          TextField(controller: _reasonController),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: 'Next: set the schedule',
                  onPressed: _nameController.text.trim().isEmpty ? null : _continue,
                ),
        ],
      ),
    );
  }
}
