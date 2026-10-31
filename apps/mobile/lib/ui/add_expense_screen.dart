import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../model/expense.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// Add an expense. Pass [from] to start from an existing one ("Duplicate"),
/// or [editing] to change one in place.
class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, this.personId, this.from, this.editing});

  final PersonId? personId;
  final Expense? from;
  final Expense? editing;

  @override
  ConsumerState<AddExpenseScreen> createState() => _State();
}

class _State extends ConsumerState<AddExpenseScreen> {
  static const _methods = ['Cash', 'UPI', 'Card', 'Insurance', 'Other'];

  /// The expense the form starts from: the one being edited, or the one being
  /// duplicated.
  Expense? get _base => widget.editing ?? widget.from;

  late final _amount = TextEditingController(
    text: _base == null ? '' : (_base!.amountPaise / 100).toString().replaceFirst(RegExp(r'\.0$'), ''),
  );
  late final _title = TextEditingController(text: _base?.title ?? '');
  late final _payee = TextEditingController(text: _base?.payee ?? '');
  late PersonId? _person = _base?.personId ?? widget.personId;
  late ExpenseCategory _category = _base?.category ?? ExpenseCategory.consultation;
  late String? _paidBy = _base?.paidBy;
  File? _receipt;
  late DateTime _date = widget.editing?.spentOn ?? DateTime.now();
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

  Future<void> _addReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final shot = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (shot != null) setState(() => _receipt = File(shot.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repository = await ref.read(expenseRepositoryProvider.future);
    final payee = _payee.text.trim().isEmpty ? null : _payee.text.trim();
    final editing = widget.editing;
    if (editing == null) {
      await repository.add(
        personId: _person!,
        title: _title.text.trim(),
        payee: payee,
        amountPaise: parseRupees(_amount.text)!,
        category: _category,
        paidBy: _paidBy,
        spentOn: _date,
        receipt: _receipt,
      );
    } else {
      await repository.update(
        editing.id,
        personId: _person!,
        title: _title.text.trim(),
        payee: payee,
        amountPaise: parseRupees(_amount.text)!,
        category: _category,
        paidBy: _paidBy,
        spentOn: _date,
        receipt: _receipt,
      );
    }
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
          Text(
            widget.editing == null ? 'Add expense' : 'Edit expense',
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
            decoration: const InputDecoration(hintText: 'What it was for'),
          ),
          const SectionLabel('Paid to (optional)'),
          TextField(
            controller: _payee,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Who was paid'),
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
          const SectionLabel('Receipt (optional)'),
          OutlinedButton.icon(
            onPressed: _addReceipt,
            icon: Icon(_receipt == null ? Icons.photo_camera_outlined : Icons.check),
            label: Text(_receipt == null ? (widget.editing == null ? 'Add a photo of the bill' : 'Replace the photo of the bill') : 'Photo added. Tap to change'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 28),
          _saving
              ? const Center(child: CircularProgressIndicator())
              : OnboardButton(label: widget.editing == null ? 'Save expense' : 'Save changes', onPressed: _valid ? _save : null),
        ],
      ),
    );
  }
}
