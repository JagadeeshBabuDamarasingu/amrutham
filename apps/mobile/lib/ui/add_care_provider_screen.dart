import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/care_provider.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

class AddCareProviderScreen extends ConsumerStatefulWidget {
  const AddCareProviderScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  ConsumerState<AddCareProviderScreen> createState() => _State();
}

class _State extends ConsumerState<AddCareProviderScreen> {
  CareKind _kind = CareKind.doctor;
  bool _current = true;
  final _name = TextEditingController();
  final _specialty = TextEditingController();
  final _worksAt = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  late final Set<PersonId> _consultsFor = {widget.personId};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _specialty, _worksAt, _phone, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _opt(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(careTeamRepositoryProvider.future);
    final isDoctor = _kind == CareKind.doctor;
    await repository.add(
      kind: _kind,
      name: _name.text.trim(),
      specialty: isDoctor ? _opt(_specialty) : null,
      worksAt: isDoctor ? _opt(_worksAt) : null,
      phone: _opt(_phone),
      location: _opt(_location),
      personIds: _consultsFor.toList(),
      isCurrent: _current,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    final isDoctor = _kind == CareKind.doctor;
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
            'Add to care team',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          SegmentedButton<CareKind>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: CareKind.doctor, label: Text('Doctor')),
              ButtonSegment(value: CareKind.facility, label: Text('Hospital or clinic')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SectionLabel('Name'),
          TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: isDoctor ? 'Dr. Lakshmi Iyer' : 'Apollo Hospitals',
            ),
          ),
          if (isDoctor) ...[
            const SectionLabel('Specialty'),
            TextField(
              controller: _specialty,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'General physician'),
            ),
            const SectionLabel('Works at (optional)'),
            TextField(
              controller: _worksAt,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Iyer Clinic, Kondapur'),
            ),
          ],
          const SectionLabel('Phone (stays on this phone)'),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+91 98480 55012'),
          ),
          const SectionLabel('Location (optional)'),
          TextField(
            controller: _location,
            textCapitalization: TextCapitalization.words,
          ),
          const SectionLabel('Consults for'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in people)
                FilterChip(
                  label: Text(p.displayName),
                  selected: _consultsFor.contains(p.id),
                  showCheckmark: false,
                  selectedColor: onboardInk,
                  labelStyle: TextStyle(
                    color: _consultsFor.contains(p.id) ? Colors.white : null,
                  ),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _consultsFor.add(p.id);
                    } else if (_consultsFor.length > 1) {
                      _consultsFor.remove(p.id);
                    }
                  }),
                ),
            ],
          ),
          const SectionLabel('Status'),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Current')),
              ButtonSegment(value: false, label: Text('Past')),
            ],
            selected: {_current},
            onSelectionChanged: (s) => setState(() => _current = s.first),
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: 'Save',
                  onPressed: _name.text.trim().isEmpty ? null : _save,
                ),
        ],
      ),
    );
  }
}
