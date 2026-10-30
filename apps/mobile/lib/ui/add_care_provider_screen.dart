import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/care_provider.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

/// Adds a doctor or place, or edits one when [editing] is given.
class AddCareProviderScreen extends ConsumerStatefulWidget {
  const AddCareProviderScreen({super.key, required this.personId, this.editing});

  final PersonId personId;
  final CareProvider? editing;

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
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e == null) return;
    _kind = e.kind;
    _current = e.isCurrent;
    _name.text = e.name;
    _specialty.text = e.specialty ?? '';
    _worksAt.text = e.worksAt ?? '';
    _phone.text = e.phone ?? '';
    _location.text = e.location ?? '';
    _consultsFor
      ..clear()
      ..addAll(e.personIds);
  }

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
    final repository = await ref.read(careTeamRepositoryProvider.future);
    final editing = widget.editing;
    if (editing == null) {
      // The same doctor is often added for a second family member: offer the
      // saved one instead of a second copy.
      final all = ref.read(careProvidersAllProvider).valueOrNull ?? [];
      final dup = sameProvider(all, _kind, _name.text);
      if (dup != null) {
        if (!mounted) return;
        final choice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${dup.name} is already saved'),
            content: const Text(
              "They're already in your family's care team. Use the saved one "
              'instead of adding a second copy?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'new'),
                child: const Text('Add anyway'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'use'),
                child: const Text('Use saved'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        if (choice == 'use') {
          for (final person in _consultsFor) {
            await repository.linkPerson(dup.id, person);
          }
          if (mounted) Navigator.of(context).pop();
          return;
        }
      }
    }
    setState(() => _saving = true);
    final isDoctor = _kind == CareKind.doctor;
    final specialty = isDoctor ? _opt(_specialty) : null;
    final worksAt = isDoctor ? _opt(_worksAt) : null;
    if (editing == null) {
      await repository.add(
        kind: _kind,
        name: _name.text.trim(),
        specialty: specialty,
        worksAt: worksAt,
        phone: _opt(_phone),
        location: _opt(_location),
        personIds: _consultsFor.toList(),
        isCurrent: _current,
      );
    } else {
      await repository.update(
        editing.id,
        kind: _kind,
        name: _name.text.trim(),
        specialty: specialty,
        worksAt: worksAt,
        phone: _opt(_phone),
        location: _opt(_location),
        personIds: _consultsFor.toList(),
        isCurrent: _current,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    // Watched so the saved list is loaded by the time Save checks for a
    // duplicate (a plain ref.read would still be loading).
    ref.watch(careProvidersAllProvider);
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
          Text(
            widget.editing == null ? 'Add to care team' : 'Edit',
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
              hintText: isDoctor ? 'Name of the doctor' : 'Name of the hospital',
            ),
          ),
          if (isDoctor) ...[
            const SectionLabel('Specialty'),
            TextField(
              controller: _specialty,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Specialty'),
            ),
            const SectionLabel('Works at (optional)'),
            TextField(
              controller: _worksAt,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Clinic or address'),
            ),
          ],
          const SectionLabel('Phone (stays on this phone)'),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Phone number'),
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
