import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/care_provider.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'add_care_provider_screen.dart';
import 'app_style.dart';

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
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(p.isCurrent ? Icons.archive_outlined : Icons.unarchive_outlined),
              title: Text(p.isCurrent ? 'Move to Past' : 'Move to Current'),
              onTap: () => Navigator.pop(context, 'move'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    final repository = await ref.read(careTeamRepositoryProvider.future);
    if (action == 'move') {
      await repository.setCurrent(p.id, !p.isCurrent);
    } else if (action == 'delete' && mounted) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete ${p.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok == true) await repository.delete(p.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(careTeamProvider(widget.personId)).valueOrNull ?? [];
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
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddCareProviderScreen(personId: widget.personId),
          ),
        ),
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
