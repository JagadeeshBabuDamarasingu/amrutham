import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/medication.dart';
import '../model/schedule_phase.dart';
import '../providers/app_providers.dart';
import 'add_schedule_phase_screen.dart';

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({
    super.key,
    required this.personId,
    required this.courseId,
  });

  final PersonId personId;
  final MedicationCourseId courseId;

  Future<void> _setStatus(
    WidgetRef ref,
    CourseStatus status,
  ) async {
    final medicationRepository = await ref.read(
      medicationRepositoryProvider.future,
    );
    await medicationRepository.updateCourseStatus(courseId, status);
    // Re-arm is the single entry point that keeps reminders correct after
    // any course/phase change — see reminder/reminder_repository.dart.
    final reminderRepository = await ref.read(
      reminderRepositoryProvider.future,
    );
    await reminderRepository.armRemindersForPerson(personId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(medicationCoursesProvider(personId));
    final phasesAsync = ref.watch(schedulePhasesProvider(courseId));

    final course = coursesAsync.maybeWhen(
      data: (courses) {
        for (final c in courses) {
          if (c.id == courseId) return c;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(course?.medicationName ?? 'Medication')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddSchedulePhaseScreen(
              personId: personId,
              courseId: courseId,
              isFirstPhase: false,
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add taper phase'),
      ),
      body: course == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CourseSummary(
                  course: course,
                  onStatusChanged: (status) => _setStatus(ref, status),
                ),
                const SizedBox(height: 24),
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                phasesAsync.when(
                  data: (phases) {
                    if (phases.isEmpty) {
                      return const Text('No schedule phases yet.');
                    }
                    return Column(
                      children: phases
                          .map((phase) => _PhaseCard(phase: phase))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) =>
                      Text('Something went wrong: $error'),
                ),
              ],
            ),
    );
  }
}

class _CourseSummary extends StatelessWidget {
  const _CourseSummary({required this.course, required this.onStatusChanged});

  final MedicationCourse course;
  final ValueChanged<CourseStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.reason != null) Text('Reason: ${course.reason}'),
            if (course.prescriberName != null)
              Text('Prescriber: ${course.prescriberName}'),
            Text('Started: ${_formatDate(course.startDate)}'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status: '),
                DropdownButton<CourseStatus>(
                  value: course.status,
                  items: CourseStatus.values
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (status) {
                    if (status != null) onStatusChanged(status);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.phase});

  final SchedulePhase phase;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(phase.doseAmount),
        subtitle: Text(_subtitle()),
      ),
    );
  }

  String _subtitle() {
    if (phase.isPrn) {
      final parts = <String>['PRN'];
      if (phase.prnMaxFrequency != null) parts.add(phase.prnMaxFrequency!);
      if (phase.prnReason != null) parts.add(phase.prnReason!);
      return parts.join(' · ');
    }
    final cadence =
        '${phase.frequency}x every ${phase.period} ${phase.periodUnit.name}';
    final times = phase.timesOfDay.join(', ');
    final days = phase.daysOfWeek == null || phase.daysOfWeek!.isEmpty
        ? 'every day'
        : (phase.daysOfWeek!.toList()..sort()).join(',');
    return '$cadence at $times ($days)';
  }
}
