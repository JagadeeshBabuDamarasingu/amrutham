import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/medication.dart';
import '../providers/app_providers.dart';
import 'add_schedule_phase_screen.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// Step 1 of F2's "add a 3-phase taper in under 2 minutes" flow — the
/// course itself. Saving hands straight off to AddSchedulePhaseScreen for
/// the first phase, since a course with no phase yet has nothing to remind
/// anyone about. See specs/phase-1-v1/01-features.md F2.
class AddMedicationCourseScreen extends ConsumerStatefulWidget {
  const AddMedicationCourseScreen({super.key, required this.personId, this.editing});

  final PersonId personId;

  /// A saved course to change. Saving then just goes back instead of moving
  /// on to the schedule.
  final MedicationCourse? editing;

  @override
  ConsumerState<AddMedicationCourseScreen> createState() =>
      _AddMedicationCourseScreenState();
}

class _AddMedicationCourseScreenState
    extends ConsumerState<AddMedicationCourseScreen> {
  late final _nameController = TextEditingController(text: widget.editing?.medicationName);
  late final _prescriberController = TextEditingController(text: widget.editing?.prescriberName);
  late final _reasonController = TextEditingController(text: widget.editing?.reason);
  late DateTime _start = widget.editing?.startDate ?? DateTime.now();
  late DateTime? _end = widget.editing?.endDate;
  bool _saving = false;

  Future<void> _pick({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? _start,
      firstDate: start ? DateTime(1990) : _start,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = null;
      } else {
        _end = picked;
      }
    });
  }

  String _day(DateTime d) => '${d.day} ${monthNames[d.month - 1]} ${d.year}';

  Future<void> _saveEdit() async {
    setState(() => _saving = true);
    final repository = await ref.read(medicationRepositoryProvider.future);
    await repository.updateCourse(
      widget.editing!.id,
      medicationName: _nameController.text.trim(),
      startDate: _start,
      endDate: _end,
      prescriberName: _prescriberController.text.trim().isEmpty
          ? null
          : _prescriberController.text.trim(),
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    );
    // Reminders follow the course, so re-arm after any change.
    final reminders = await ref.read(reminderRepositoryProvider.future);
    await reminders.armRemindersForPerson(widget.personId);
    if (mounted) Navigator.of(context).pop();
  }

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
          Text(
            widget.editing == null ? 'Add a medicine' : 'Edit medicine',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          if (widget.editing == null) ...[
            const SizedBox(height: 6),
            const Text(
              'Next you set when to take it. Current medicines can send reminders.',
              style: TextStyle(color: onboardMuted),
            ),
          ],
          const SectionLabel('Name'),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Medicine name and strength'),
          ),
          const SectionLabel('Prescribed by (optional)'),
          TextField(controller: _prescriberController),
          const SectionLabel('Reason (optional)'),
          TextField(controller: _reasonController),
          if (widget.editing != null) ...[
            const SectionLabel('Started'),
            OutlinedButton(
              onPressed: () => _pick(start: true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                alignment: Alignment.centerLeft,
              ),
              child: Text(_day(_start)),
            ),
            const SectionLabel('Ends (optional)'),
            OutlinedButton(
              onPressed: () => _pick(start: false),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                alignment: Alignment.centerLeft,
              ),
              child: Text(_end == null ? 'No end date' : _day(_end!)),
            ),
            if (_end != null)
              TextButton(
                onPressed: () => setState(() => _end = null),
                child: const Text('Clear the end date'),
              ),
          ],
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: widget.editing == null ? 'Next: set the schedule' : 'Save changes',
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : widget.editing == null
                      ? _continue
                      : _saveEdit,
                ),
        ],
      ),
    );
  }
}
