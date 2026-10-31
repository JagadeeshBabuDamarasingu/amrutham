import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/person.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;
import 'profile_detail_screen.dart';
import 'recovery_flow_screen.dart';

/// F1 acceptance: a full profile can be created in under 5 minutes on a
/// phone, with no field mandatory except display name. See
/// specs/phase-1-v1/01-features.md F1.
class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key, this.editing});

  /// A saved person to change instead of adding a new one.
  final PersonProfile? editing;

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  static const _sexes = ['Female', 'Male', 'Other', 'Not stated'];
  static const _bloodGroups = [
    'A positive', 'A negative', 'B positive', 'B negative',
    'AB positive', 'AB negative', 'O positive', 'O negative',
  ];

  late final _given = TextEditingController(
    text: widget.editing?.givenName ?? widget.editing?.displayName,
  );
  late final _surname = TextEditingController(text: widget.editing?.surname);
  late RelationshipType? _relationship = widget.editing?.relationship;
  late String? _sex = widget.editing?.sex;
  late String? _bloodGroup = widget.editing?.bloodGroup;
  late DateTime? _dateOfBirth = widget.editing?.dateOfBirth;
  late bool _deceased = widget.editing?.isDeceased ?? false;
  late DateTime? _dateOfDeath = widget.editing?.dateOfDeath;
  late final _cause = TextEditingController(text: widget.editing?.causeOfDeath);
  bool _saving = false;

  @override
  void dispose() {
    _given.dispose();
    _surname.dispose();
    _cause.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    setState(() => _saving = true);
    final repository = await ref.read(profileRepositoryProvider.future);
    await repository.updateProfile(
      widget.editing!.id,
      displayName: [_given.text.trim(), _surname.text.trim()]
          .where((part) => part.isNotEmpty)
          .join(' '),
      givenName: _given.text.trim(),
      surname: _surname.text.trim().isEmpty ? null : _surname.text.trim(),
      relationship: _relationship ?? RelationshipType.otherDependent,
      dateOfBirth: _dateOfBirth,
      sex: _sex == 'Not stated' ? null : _sex,
      bloodGroup: _bloodGroup,
      isDeceased: _deceased,
      dateOfDeath: _deceased ? _dateOfDeath : null,
      causeOfDeath: _deceased && _cause.text.trim().isNotEmpty
          ? _cause.text.trim()
          : null,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    // The first record can't be saved until a recovery code is confirmed.
    if (!await ensureRecoverySetUp(context, ref)) return;
    if (!mounted) return;
    setState(() => _saving = true);

    final repository = await ref.read(profileRepositoryProvider.future);
    final profile = await repository.createProfile(
      displayName: [_given.text.trim(), _surname.text.trim()]
          .where((part) => part.isNotEmpty)
          .join(' '),
      givenName: _given.text.trim(),
      surname: _surname.text.trim().isEmpty ? null : _surname.text.trim(),
      relationship: _relationship ?? RelationshipType.otherDependent,
      dateOfBirth: _dateOfBirth,
      sex: _sex == 'Not stated' ? null : _sex,
      bloodGroup: _bloodGroup,
      isDeceased: _deceased,
      dateOfDeath: _deceased ? _dateOfDeath : null,
      causeOfDeath: _deceased && _cause.text.trim().isNotEmpty
          ? _cause.text.trim()
          : null,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProfileDetailScreen(personId: profile.id),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: _dateOfBirth ?? DateTime(1990),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickDateOfDeath() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: _dateOfBirth ?? DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: _dateOfDeath ?? DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfDeath = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dob = _dateOfBirth;
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
            widget.editing == null ? 'Add a family member' : 'Edit details',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          if (widget.editing == null) ...[
            const SizedBox(height: 6),
            const Text(
              'Only a name is required. Add the rest when you know it.',
              style: TextStyle(color: onboardMuted),
            ),
          ],
          const SectionLabel('Name'),
          TextField(
            controller: _given,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Given name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _surname,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Surname (optional)'),
          ),
          const SectionLabel('Relationship to you'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in RelationshipType.values)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _relationship == r,
                  onSelected: (_) => setState(() => _relationship = r),
                ),
            ],
          ),
          const SectionLabel('Sex'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _sexes)
                ChoiceChip(
                  label: Text(s),
                  selected: _sex == s,
                  onSelected: (_) => setState(() => _sex = s),
                ),
            ],
          ),
          const SectionLabel('Date of birth'),
          OutlinedButton(
            onPressed: _pickDateOfBirth,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              dob == null
                  ? 'Choose a date (optional)'
                  : '${dob.day} ${monthNames[dob.month - 1]} ${dob.year}',
            ),
          ),
          const SectionLabel('Blood group'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _bloodGroups)
                ChoiceChip(
                  label: Text(g),
                  selected: _bloodGroup == g,
                  onSelected: (_) => setState(
                    () => _bloodGroup = _bloodGroup == g ? null : g,
                  ),
                ),
            ],
          ),
          const SectionLabel('Status'),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Living')),
              ButtonSegment(value: true, label: Text('Deceased')),
            ],
            selected: {_deceased},
            onSelectionChanged: (s) => setState(() => _deceased = s.first),
          ),
          if (_deceased) ...[
            const SectionLabel('Date of death (optional)'),
            OutlinedButton(
              onPressed: _pickDateOfDeath,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                _dateOfDeath == null
                    ? 'Choose a date, or leave it blank'
                    : '${_dateOfDeath!.day} ${monthNames[_dateOfDeath!.month - 1]} ${_dateOfDeath!.year}',
              ),
            ),
            const SectionLabel('Cause, in your words (optional)'),
            TextField(
              controller: _cause,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'What happened, if you know'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kept as you wrote it. Unverified.',
              style: TextStyle(fontSize: 13, color: onboardMuted),
            ),
          ],
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: widget.editing == null ? 'Save' : 'Save changes',
                  onPressed: _given.text.trim().isEmpty
                      ? null
                      : widget.editing == null
                      ? _save
                      : _saveEdit,
                ),
        ],
      ),
    );
  }
}
