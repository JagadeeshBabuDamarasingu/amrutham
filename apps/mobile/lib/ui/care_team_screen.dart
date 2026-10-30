import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/care_provider.dart';
import '../model/ids.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import 'add_care_provider_screen.dart';
import 'app_style.dart';
import 'care_provider_picker_screen.dart';

/// Doctors and places one person consults, with a call button for each.
class CareTeamScreen extends ConsumerStatefulWidget {
  const CareTeamScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends ConsumerState<CareTeamScreen> {
  bool _current = true;

  Future<void> _call(String phone) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't open the dialer for $phone")),
      );
    }
  }

  Future<void> _more(CareProvider p) async {
    final others = p.personIds.where((id) => id != widget.personId).length;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(p.isCurrent ? Icons.archive_outlined : Icons.unarchive_outlined),
              title: Text(p.isCurrent ? 'Move to Past' : 'Move to Current'),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: Text(others > 0 ? 'Remove from this care team' : 'Delete'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
            if (others > 0)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete for everyone'),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    final repository = await ref.read(careTeamRepositoryProvider.future);
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddCareProviderScreen(personId: widget.personId, editing: p),
          ),
        );
      case 'move':
        await repository.setCurrent(p.id, !p.isCurrent);
      case 'remove':
        if (await _confirm(
          'Remove ${p.name}?',
          others > 0
              ? 'They stay on the care team of the $others other '
                  '${others == 1 ? 'person' : 'people'}.'
              : 'This deletes the entry.',
        )) {
          await repository.unlinkPerson(p.id, widget.personId);
        }
      case 'delete':
        if (await _confirm(
          'Delete ${p.name} for everyone?',
          'They are removed from the care team of all ${p.personIds.length} people.',
        )) {
          await repository.delete(p.id);
        }
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(careTeamProvider(widget.personId)).valueOrNull ?? [];
    // Watched so the "+ Add" button knows whether there is anyone to reuse.
    ref.watch(careProvidersAllProvider);
    final name = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == widget.personId)
        .firstOrNull
        ?.displayName;
    final current = all.where((p) => p.isCurrent).toList();
    final past = all.where((p) => !p.isCurrent).toList();
    final shown = _current ? current : past;
    final doctors = shown.where((p) => p.kind == CareKind.doctor).toList();
    final places = shown.where((p) => p.kind == CareKind.facility).toList();

    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          // Offer the doctors already saved for the family before a blank form.
          final saved = ref.read(careProvidersAllProvider).valueOrNull ?? [];
          final reusable = saved.any((p) => !p.personIds.contains(widget.personId));
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => reusable
                  ? CareProviderPickerScreen(personId: widget.personId)
                  : AddCareProviderScreen(personId: widget.personId),
            ),
          );
        },
        backgroundColor: onboardInk,
        foregroundColor: Colors.white,
        label: const Text('+ Add'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const Text(
            'Care team',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          Text(
            'Doctors and places ${name ?? 'this person'} consults.',
            style: const TextStyle(color: onboardMuted),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text('Current · ${current.length}')),
              ButtonSegment(value: false, label: Text('Past · ${past.length}')),
            ],
            selected: {_current},
            onSelectionChanged: (s) => setState(() => _current = s.first),
          ),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Text(
                'Nobody here yet. Tap "+ Add" for a doctor or hospital.',
                style: TextStyle(color: onboardMuted),
              ),
            ),
          if (doctors.isNotEmpty) ...[
            const SectionLabel('Doctors'),
            for (final p in doctors) _row(p),
          ],
          if (places.isNotEmpty) ...[
            const SectionLabel('Hospitals and clinics'),
            for (final p in places) _row(p),
          ],
        ],
      ),
    );
  }

  Widget _row(CareProvider p) {
    final subtitle = [
      ?p.specialty,
      ?p.worksAt,
      if (p.kind == CareKind.facility) ?p.location,
    ].join(' · ');
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    final alsoSees = [
      for (final person in people)
        if (person.id != widget.personId && p.personIds.contains(person.id)) person.firstName,
    ];
    final initials = p.name
        .replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onLongPress: () => _more(p),
        onTap: () => _more(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5E4DC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: p.kind == CareKind.doctor
                    ? Text(initials, style: const TextStyle(fontWeight: FontWeight.w800))
                    : const Icon(Icons.local_hospital_outlined, color: onboardInk),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(color: onboardMuted, fontSize: 13),
                      ),
                    if (alsoSees.isNotEmpty)
                      Text(
                        'Also sees ${alsoSees.join(', ')}',
                        style: const TextStyle(color: onboardMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
              if (p.phone != null)
                IconButton.filled(
                  tooltip: 'Call ${p.name}',
                  onPressed: () => _call(p.phone!),
                  icon: const Icon(Icons.call, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
