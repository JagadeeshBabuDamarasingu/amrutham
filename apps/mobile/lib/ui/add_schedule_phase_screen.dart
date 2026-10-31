import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/schedule_phase.dart';
import '../providers/app_providers.dart';

const List<String> _dayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// One phase of a schedule — used both for a brand-new course's first phase
/// and for adding a taper's later phases to an existing course. See
/// specs/phase-1-v1/01-features.md F2 ("ordered phase rows support tapers").
class AddSchedulePhaseScreen extends ConsumerStatefulWidget {
  const AddSchedulePhaseScreen({
    super.key,
    required this.personId,
    required this.courseId,
    required this.isFirstPhase,
    this.editing,
  });

  final PersonId personId;
  final MedicationCourseId courseId;
  final bool isFirstPhase;

  /// A saved phase to change instead of adding a new one.
  final SchedulePhase? editing;

  @override
  ConsumerState<AddSchedulePhaseScreen> createState() =>
      _AddSchedulePhaseScreenState();
}

class _AddSchedulePhaseScreenState
    extends ConsumerState<AddSchedulePhaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doseAmountController = TextEditingController();
  final _frequencyController = TextEditingController(text: '1');
  final _periodController = TextEditingController(text: '1');
  final _prnReasonController = TextEditingController();
  final _prnMaxFrequencyController = TextEditingController();

  PeriodUnit _periodUnit = PeriodUnit.day;
  final List<String> _times = [];
  final Set<int> _selectedDays = {};
  bool _isPrn = false;
  DateTime _phaseStart = DateTime.now();
  DateTime? _phaseEnd;
  String? _timesError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e == null) return;
    _doseAmountController.text = e.doseAmount;
    _frequencyController.text = '${e.frequency}';
    _periodController.text = '${e.period}';
    _prnReasonController.text = e.prnReason ?? '';
    _prnMaxFrequencyController.text = e.prnMaxFrequency ?? '';
    _periodUnit = e.periodUnit;
    _times.addAll(e.timesOfDay);
    _selectedDays.addAll(e.daysOfWeek ?? const {});
    _isPrn = e.isPrn;
    _phaseStart = e.phaseStart;
    _phaseEnd = e.phaseEnd;
  }

  @override
  void dispose() {
    _doseAmountController.dispose();
    _frequencyController.dispose();
    _periodController.dispose();
    _prnReasonController.dispose();
    _prnMaxFrequencyController.dispose();
    super.dispose();
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    if (_times.contains(formatted)) return;
    setState(() {
      _times.add(formatted);
      _times.sort();
      _timesError = null;
    });
  }

  Future<void> _pickPhaseStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _phaseStart,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _phaseStart = picked);
  }

  Future<void> _pickPhaseEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _phaseEnd ?? _phaseStart,
      firstDate: _phaseStart,
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _phaseEnd = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPrn && _times.isEmpty) {
      setState(() => _timesError = 'Add at least one time');
      return;
    }
    setState(() => _saving = true);

    final medicationRepository = await ref.read(
      medicationRepositoryProvider.future,
    );
    final editing = widget.editing;
    final doseAmount = _doseAmountController.text.trim();
    final frequency = _isPrn ? 1 : int.parse(_frequencyController.text.trim());
    final period = _isPrn ? 1 : int.parse(_periodController.text.trim());
    final prnReason = _isPrn && _prnReasonController.text.trim().isNotEmpty
        ? _prnReasonController.text.trim()
        : null;
    final prnMax = _isPrn && _prnMaxFrequencyController.text.trim().isNotEmpty
        ? _prnMaxFrequencyController.text.trim()
        : null;
    if (editing == null) {
      await medicationRepository.addSchedulePhase(
        courseId: widget.courseId,
        doseAmount: doseAmount,
        // frequency/period are unused for PRN rows but the column is NOT
        // NULL — see specs/phase-1-v1/02-architecture.md §4.
        frequency: frequency,
        period: period,
        periodUnit: _periodUnit,
        daysOfWeek: _selectedDays.isEmpty ? null : _selectedDays,
        timesOfDay: _isPrn ? const [] : _times,
        isPrn: _isPrn,
        prnReason: prnReason,
        prnMaxFrequency: prnMax,
        phaseStart: _phaseStart,
        phaseEnd: _phaseEnd,
      );
    } else {
      await medicationRepository.updateSchedulePhase(
        editing.id,
        doseAmount: doseAmount,
        frequency: frequency,
        period: period,
        periodUnit: _periodUnit,
        daysOfWeek: _selectedDays.isEmpty ? null : _selectedDays,
        timesOfDay: _isPrn ? const [] : _times,
        isPrn: _isPrn,
        prnReason: prnReason,
        prnMaxFrequency: prnMax,
        phaseStart: _phaseStart,
        phaseEnd: _phaseEnd,
      );
    }

    final reminderRepository = await ref.read(
      reminderRepositoryProvider.future,
    );
    await reminderRepository.requestNotificationPermission();
    var exactAllowed = await reminderRepository.canScheduleExactReminders();
    if (!exactAllowed && !_isPrn) {
      exactAllowed = await reminderRepository.requestExactAlarmPermission();
    }
    await reminderRepository.armRemindersForPerson(widget.personId);

    if (!mounted) return;
    if (!exactAllowed && !_isPrn) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Reminders may be delayed'),
          content: const Text(
            "This phone doesn't allow exact-time alarms for this app right "
            'now. The reminder was still scheduled, but may fire a little '
            'late. You can allow exact alarms from your phone\'s settings '
            'at any time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editing != null
              ? 'Edit schedule'
              : widget.isFirstPhase
              ? 'Set the schedule'
              : 'Add a taper phase',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _doseAmountController,
              decoration: const InputDecoration(
                labelText: 'Dose each time',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Dose is required'
                  : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('PRN (as-needed)'),
              subtitle: const Text(
                'No fixed times — just a maximum-frequency ceiling',
              ),
              value: _isPrn,
              onChanged: (value) => setState(() => _isPrn = value),
            ),
            if (_isPrn) ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _prnReasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prnMaxFrequencyController,
                decoration: const InputDecoration(
                  labelText: 'Most times in a day',
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _frequencyController,
                      decoration: const InputDecoration(labelText: 'Times'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          int.tryParse(value?.trim() ?? '') == null
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('every'),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _periodController,
                      decoration: const InputDecoration(labelText: 'Period'),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          int.tryParse(value?.trim() ?? '') == null
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<PeriodUnit>(
                    value: _periodUnit,
                    items: PeriodUnit.values
                        .map(
                          (u) =>
                              DropdownMenuItem(value: u, child: Text(u.name)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _periodUnit = value ?? _periodUnit),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Times of day', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in _times)
                    Chip(
                      label: Text(time),
                      onDeleted: () => setState(() => _times.remove(time)),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add time'),
                    onPressed: _addTime,
                  ),
                ],
              ),
              if (_timesError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _timesError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Days of week (optional — leave blank for every day)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var i = 0; i < 7; i++)
                    FilterChip(
                      label: Text(_dayLabels[i]),
                      selected: _selectedDays.contains(i + 1),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _selectedDays.add(i + 1);
                        } else {
                          _selectedDays.remove(i + 1);
                        }
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Starts'),
              subtitle: Text(_formatDate(_phaseStart)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickPhaseStart,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ends (optional)'),
              subtitle: Text(
                _phaseEnd == null ? 'Ongoing' : _formatDate(_phaseEnd!),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_phaseEnd != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _phaseEnd = null),
                    ),
                  const Icon(Icons.edit_calendar),
                ],
              ),
              onTap: _pickPhaseEnd,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save schedule'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
