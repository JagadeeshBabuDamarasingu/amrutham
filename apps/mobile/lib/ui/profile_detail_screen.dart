import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/family_history.dart';
import '../model/ids.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import 'add_allergy_screen.dart';
import 'add_family_history_screen.dart';
import 'add_medication_course_screen.dart';
import 'app_style.dart';
import 'course_detail_screen.dart';
import 'emergency_card_screen.dart';
import 'history_screen.dart';
import 'log_measurement_screen.dart';
import 'metrics_screen.dart';

class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyHistoryAsync = ref.watch(familyHistoryProvider(personId));
    final allergiesAsync = ref.watch(allergiesProvider(personId));
    final coursesAsync = ref.watch(medicationCoursesProvider(personId));

    final person = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == personId)
        .firstOrNull;
    final activeCount =
        ref.watch(activeCoursesProvider(personId)).valueOrNull?.length ?? 0;
    final allergyCount = allergiesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          if (person != null)
            Row(
              children: [
                PersonAvatar(name: person.displayName, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.displayName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        [
                          person.relationship.label,
                          if (person.dateOfBirth != null)
                            'b. ${person.dateOfBirth!.year}',
                          ?person.bloodGroup,
                        ].join(' · '),
                        style: const TextStyle(color: onboardMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Medicines',
                  value: activeCount == 0 ? 'None' : '$activeCount active',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'Allergies',
                  value: allergyCount == 0 ? 'None' : '$allergyCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.show_chart,
                  label: 'Metrics',
                  dark: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MetricsScreen(personId: personId),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(
                  icon: Icons.add_chart,
                  label: 'Log a reading',
                  dark: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LogMeasurementScreen(personId: personId),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Tile(
                  icon: Icons.history,
                  label: 'History',
                  dark: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(personId: personId),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(
                  icon: Icons.badge_outlined,
                  label: 'Emergency card',
                  dark: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EmergencyCardScreen(personId: personId),
                    ),
                  ),
                ),
              ),
            ],
          ),
          _SectionHeader(
            title: 'Active medicines',
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddMedicationCourseScreen(personId: personId),
              ),
            ),
          ),
          coursesAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No medications yet.'),
                );
              }
              return Column(
                children: courses
                    .map(
                      (course) => Card(
                        child: ListTile(
                          title: Text(course.medicationName),
                          subtitle: Text(course.status.name),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                personId: personId,
                                courseId: course.id,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Text('Something went wrong: $error'),
          ),
          _SectionHeader(
            title: 'Family history',
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddFamilyHistoryScreen(personId: personId),
              ),
            ),
          ),
          familyHistoryAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No family history recorded yet.'),
                );
              }
              return Column(
                children: entries
                    .map(
                      (entry) => Card(
                        child: ListTile(
                          title: Text(
                            '${entry.relationship}: ${entry.conditionText}',
                          ),
                          subtitle: Text(_familyHistorySubtitle(entry)),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Text('Something went wrong: $error'),
          ),
          _SectionHeader(
            title: 'Allergies',
            onAdd: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddAllergyScreen(personId: personId),
              ),
            ),
          ),
          allergiesAsync.when(
            data: (allergies) {
              if (allergies.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No allergies recorded yet.'),
                );
              }
              return Column(
                children: allergies
                    .map(
                      (allergy) => Card(
                        child: ListTile(
                          title: Text(allergy.substance),
                          subtitle: Text(allergy.reaction),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Text('Something went wrong: $error'),
          ),
        ],
      ),
    );
  }

  String _familyHistorySubtitle(FamilyHistoryEntry entry) {
    final parts = <String>[entry.certainty.name];
    final onsetAge = entry.onsetAgeApprox;
    if (onsetAge != null) parts.add('onset ~age $onsetAge');
    final outcome = entry.outcome;
    if (outcome != null && outcome.isNotEmpty) parts.add(outcome);
    return parts.join(' · ');
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionLabel(
      title,
      trailing: TextButton(onPressed: onAdd, child: const Text('+ Add')),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: onboardMuted)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        height: 88,
        decoration: BoxDecoration(
          color: dark ? onboardInk : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: dark ? onboardAmber : onboardInk),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: dark ? Colors.white : onboardInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
