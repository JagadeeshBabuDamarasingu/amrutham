import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/family_history.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'add_allergy_screen.dart';
import 'add_family_history_screen.dart';

class ProfileDetailScreen extends ConsumerWidget {
  const ProfileDetailScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final familyHistoryAsync = ref.watch(familyHistoryProvider(personId));
    final allergiesAsync = ref.watch(allergiesProvider(personId));

    final displayName = profilesAsync.maybeWhen(
      data: (profiles) {
        for (final profile in profiles) {
          if (profile.id == personId) return profile.displayName;
        }
        return null;
      },
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(displayName ?? 'Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const SizedBox(height: 24),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    );
  }
}
