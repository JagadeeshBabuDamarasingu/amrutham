import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/care_provider.dart';
import '../model/ids.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import 'add_care_provider_screen.dart';
import 'app_style.dart';

/// First step of "Add to care team": reuse a doctor or place already saved for
/// the family, or start a new one. Saves retyping a family doctor each time.
class CareProviderPickerScreen extends ConsumerWidget {
  const CareProviderPickerScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(careProvidersAllProvider).valueOrNull ?? [];
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    final candidates = saved.where((p) => !p.personIds.contains(personId)).toList();
    final name = people.where((p) => p.id == personId).firstOrNull?.firstName;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const Text(
            'Add to care team',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          Text(
            candidates.isEmpty
                ? 'Everyone saved is already on ${name ?? 'this'} care team.'
                : 'Pick someone already saved, or add a new doctor or place.',
            style: const TextStyle(color: onboardMuted),
          ),
          const SizedBox(height: 16),
          OnboardButton(
            label: '+ New doctor or hospital',
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => AddCareProviderScreen(personId: personId)),
            ),
          ),
          if (candidates.isNotEmpty) const SectionLabel('Already saved'),
          for (final p in candidates)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(
                  p.kind == CareKind.doctor ? Icons.person_outline : Icons.local_hospital_outlined,
                  color: onboardInk,
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  [
                    ?p.specialty,
                    ?p.worksAt,
                    if (!p.isCurrent) 'Past',
                    'Sees ${[
                      for (final person in people)
                        if (p.personIds.contains(person.id)) person.firstName,
                    ].join(', ')}',
                  ].join(' · '),
                ),
                trailing: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final repository = await ref.read(careTeamRepositoryProvider.future);
                  await repository.linkPerson(p.id, personId);
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('${p.name} added${name == null ? '' : ' for $name'}.')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
