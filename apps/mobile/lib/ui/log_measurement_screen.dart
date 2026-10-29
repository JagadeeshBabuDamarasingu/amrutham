import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/ids.dart';
import '../model/measurement.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

/// Log one reading. Built for speed: the kind and the last value are one tap
/// away, and date/time default to now.
class LogMeasurementScreen extends ConsumerStatefulWidget {
  const LogMeasurementScreen({
    super.key,
    required this.personId,
    this.initialKind = MeasurementKind.weight,
  });

  final PersonId personId;
  final MeasurementKind initialKind;

  @override
  ConsumerState<LogMeasurementScreen> createState() =>
      _LogMeasurementScreenState();
}

class _LogMeasurementScreenState extends ConsumerState<LogMeasurementScreen> {
  late MeasurementKind _kind = widget.initialKind;
  final _first = TextEditingController();
  final _second = TextEditingController();
  late DateTime _when = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  double? get _firstValue => double.tryParse(_first.text.trim());
  double? get _secondValue => double.tryParse(_second.text.trim());

  bool get _valid =>
      (_firstValue ?? 0) > 0 &&
      (!_kind.hasSecondValue || (_secondValue ?? 0) > 0);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () => _when = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _when.hour,
          _when.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (picked != null) {
      setState(
        () => _when = DateTime(
          _when.year,
          _when.month,
          _when.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(measurementRepositoryProvider.future);
    await repository.addMeasurement(
      personId: widget.personId,
      kind: _kind,
      value: _firstValue!,
      value2: _kind.hasSecondValue ? _secondValue : null,
      measuredAt: _when,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final readings =
        ref.watch(measurementsProvider(widget.personId)).valueOrNull ?? [];
    final last = readings.where((m) => m.kind == _kind).firstOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: onboardBg,
      appBar: AppBar(
        backgroundColor: onboardBg,
        title: const Text('Log a measurement'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('WHAT', style: _label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in MeasurementKind.values)
                ChoiceChip(
                  label: Text(kind.label),
                  selected: kind == _kind,
                  onSelected: (_) => setState(() {
                    _kind = kind;
                    _first.clear();
                    _second.clear();
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('READING', style: _label),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          controller: _first,
                          label: _kind.firstLabel,
                          onChanged: () => setState(() {}),
                        ),
                      ),
                      if (_kind.hasSecondValue) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('/', style: TextStyle(fontSize: 32)),
                        ),
                        Expanded(
                          child: _NumberField(
                            controller: _second,
                            label: _kind.secondLabel!,
                            onChanged: () => setState(() {}),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_kind.unit, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          if (last != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3ECE7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Last: ${last.display} · ${ago(last.measuredAt)}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _first.text = _plain(last.value);
                      _second.text = last.value2 == null
                          ? ''
                          : _plain(last.value2!);
                    }),
                    child: const Text('Same as last'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('WHEN', style: _label),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickDate,
                  child: Text(dateLabel(_when)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTime,
                  child: Text(TimeOfDay.fromDateTime(_when).format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(
                  label: 'Save reading',
                  onPressed: _valid ? _save : null,
                ),
        ],
      ),
    );
  }
}

const _label = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  letterSpacing: 1,
  color: onboardMuted,
);

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      autofocus: false,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
      decoration: InputDecoration(labelText: label),
    );
  }
}

String _plain(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

const monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String dateLabel(DateTime d) {
  final now = DateTime.now();
  final today = d.year == now.year && d.month == now.month && d.day == now.day;
  return '${today ? 'Today, ' : ''}${d.day} ${monthNames[d.month - 1]}';
}

String ago(DateTime d) {
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}
