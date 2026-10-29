import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/expense.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// Add an expense. Pass [from] to start from an existing one ("Duplicate").
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.personId, this.from});

  final PersonId? personId;
  final Expense? from;

  @override
  ConsumerState<AddExpenseScreen> createState() => _State();
}

class _State extends ConsumerState<AddExpenseScreen> {
  static const _methods = ['Cash', 'UPI', 'Card', 'Insurance', 'Other'];

  late final _amount = TextEditingController(
    text: widget.from == null ? '' : (widget.from!.amountPaise / 100).toString().replaceFirst(RegExp(r'\.0$'), ''),
  );
  late final _title = TextEditingController(text: widget.from?.title ?? '');
  late final _payee = TextEditingController(text: widget.from?.payee ?? '');
  late PersonId? _person = widget.from?.personId ?? widget.personId;
  late ExpenseCategory _category = widget.from?.category ?? ExpenseCategory.consultation;
  late String? _paidBy = widget.from?.paidBy;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _payee.dispose();
    super.dispose();
  }

  bool get _valid =>
      parseRupees(_amount.text) != null &&
      _title.text.trim().isNotEmpty &&
      _person != null;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(expenseRepositoryProvider.future);
    await repository.add(
      personId: _person!,
      title: _title.text.trim(),
      payee: _payee.text.trim().isEmpty ? null : _payee.text.trim(),
      amountPaise: parseRupees(_amount.text)!,
      category: _category,
      paidBy: _paidBy,
      spentOn: _date,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
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
            'Add expense',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: onboardMuted),
                  ),
                  TextField(
                    controller: _amount,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      filled: false,
                      border: InputBorder.none,
                      hintText: '0',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('What was it for'),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Blood panel'),
          ),
          const SectionLabel('Paid to (optional)'),
          TextField(
            controller: _payee,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Vijaya Diagnostics'),
          ),
          const SectionLabel('For'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in people)
                ChoiceChip(
                  label: Text(p.displayName),
                  selected: _person == p.id,
                  onSelected: (_) => setState(() => _person = p.id),
                ),
            ],
          ),
          const SectionLabel('Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ExpenseCategory.values)
                ChoiceChip(
                  label: Text(c.label),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SectionLabel('When and how'),
          OutlinedButton(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              alignment: Alignment.centerLeft,
            ),
            child: Text('${_date.day} ${monthNames[_date.month - 1]} ${_date.year}'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _methods)
                ChoiceChip(
                  label: Text(m),
                  selected: _paidBy == m,
                  onSelected: (on) => setState(() => _paidBy = on ? m : null),
                ),
            ],
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(label: 'Save expense', onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}
