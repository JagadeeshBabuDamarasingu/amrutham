import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/person.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'create_profile_screen.dart';
import 'profile_detail_screen.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(profilesProvider);
    return SafeArea(
      child: Stack(
        children: [
          people.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Something went wrong: $e')),
            data: (list) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const Text(
                  'Family',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  list.length == 1 ? '1 person' : '${list.length} people',
                  style: const TextStyle(color: onboardMuted),
                ),
                const SizedBox(height: 16),
                if (list.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No profiles yet. Add your first one.'),
                    ),
                  ),
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PersonCard(person: list[i], colorIndex: i),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
              ),
              backgroundColor: onboardInk,
              foregroundColor: Colors.white,
              label: const Text('+ Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends ConsumerWidget {
  const _PersonCard({required this.person, required this.colorIndex});

  final PersonProfile person;
  final int colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meds = ref.watch(activeCoursesProvider(person.id)).valueOrNull;
    final parts = [
      person.relationship.label,
      ?person.ageYears?.toString(),
      if (meds != null && meds.isNotEmpty)
        '${meds.length} active medication${meds.length == 1 ? '' : 's'}',
    ];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProfileDetailScreen(personId: person.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              PersonAvatar(
                name: person.displayName,
                colorIndex: colorIndex,
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      parts.join(' · '),
                      style: const TextStyle(color: onboardMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: onboardMuted),
            ],
          ),
        ),
      ),
    );
  }
}
