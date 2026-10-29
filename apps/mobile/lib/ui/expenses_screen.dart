import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../model/expense.dart';
import '../model/ids.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import 'add_expense_screen.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

const _categoryColors = {
  ExpenseCategory.tests: Color(0xFFF0A91E),
  ExpenseCategory.consultation: Color(0xFFA9C4B6),
  ExpenseCategory.medicines: Color(0xFF6A9080),
  ExpenseCategory.procedure: Color(0xFFE8DAEF),
  ExpenseCategory.transport: Color(0xFFF5E3B0),
  ExpenseCategory.other: Color(0xFFB8C4BE),
};

int _sum(Iterable<Expense> e) => e.fold(0, (a, b) => a + b.amountPaise);

/// Family-wide medical expenses, one month at a time. A personal record, never
/// sent to an insurer.
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  PersonId? _only; // null = everyone

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    final all = ref.watch(expensesProvider).valueOrNull ?? [];
    final inMonth = [
      for (final e in all)
        if (e.spentOn.year == _month.year && e.spentOn.month == _month.month) e,
    ];
    final shown = [
      for (final e in inMonth)
        if (_only == null || e.personId == _only) e,
    ];
    final byCategory = <ExpenseCategory, int>{};
    for (final e in shown) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amountPaise;
    }
    final total = _sum(shown);
    final peopleInvolved = shown.map((e) => e.personId).toSet().length;
    int colorOf(PersonId id) => people.indexWhere((p) => p.id == id);

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const YearViewScreen()),
            ),
            child: Text('${_month.year} view ›'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(personId: _only ?? people.firstOrNull?.id)),
        ),
        backgroundColor: onboardInk,
        foregroundColor: Colors.white,
        label: const Text('+ Add expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          const Text(
            'Expenses',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          Row(
            children: [
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left)),
              Text(
                '${const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][_month.month - 1]} ${_month.year}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              IconButton(onPressed: () => _shift(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SPENT THIS MONTH',
                  style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupees(total),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${shown.length} ${shown.length == 1 ? 'entry' : 'entries'} · '
                  '$peopleInvolved ${peopleInvolved == 1 ? 'person' : 'people'}',
                  style: const TextStyle(color: Color(0xFFB8D0C5)),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        for (final c in byCategory.entries)
                          Expanded(
                            flex: c.value,
                            child: Container(height: 8, color: _categoryColors[c.key]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (final c in byCategory.entries)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, color: _categoryColors[c.key]),
                            const SizedBox(width: 6),
                            Text(
                              '${c.key.label} ${formatRupees(c.value)}',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Everyone'),
                    selected: _only == null,
                    onSelected: (_) => setState(() => _only = null),
                  ),
                ),
                for (final p in people)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        '${p.displayName} ${formatRupees(_sum(inMonth.where((e) => e.personId == p.id)))}',
                      ),
                      selected: _only == p.id,
                      onSelected: (_) => setState(() => _only = p.id),
                    ),
                  ),
              ],
            ),
          ),
          const SectionLabel('This month'),
          if (shown.isEmpty)
            const Text('Nothing logged this month.', style: TextStyle(color: onboardMuted)),
          for (final e in shown)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: PersonAvatar(
                  name: people.where((p) => p.id == e.personId).firstOrNull?.displayName ?? '?',
                  colorIndex: colorOf(e.personId) < 0 ? 0 : colorOf(e.personId),
                ),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  [?e.payee, '${e.spentOn.day} ${monthNames[e.spentOn.month - 1]}'].join(' · '),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatRupees(e.amountPaise), style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(e.category.label, style: const TextStyle(fontSize: 12, color: onboardMuted)),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: e)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == expense.personId)
        .firstOrNull;
    final e = expense;
    final receipt = ref.watch(expenseRepositoryProvider).valueOrNull?.receiptFor(e.id);
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.category.label.toUpperCase()} · ${e.spentOn.day} ${monthNames[e.spentOn.month - 1].toUpperCase()} ${e.spentOn.year}',
                  style: const TextStyle(color: Color(0xFFB8D0C5), fontSize: 12, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  formatRupees(e.amountPaise),
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                ),
                Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                if (e.payee != null) Text(e.payee!, style: const TextStyle(color: Color(0xFFB8D0C5))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _InfoRow('For', person?.displayName ?? '—'),
                if (e.paidBy != null) _InfoRow('Paid by', e.paidBy!),
                _InfoRow(
                  'Added',
                  '${e.addedAt.day} ${monthNames[e.addedAt.month - 1]}, ${TimeOfDay.fromDateTime(e.addedAt).format(context)}',
                ),
              ],
            ),
          ),
          if (receipt != null) ...[
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => Dialog(child: InteractiveViewer(child: Image.file(receipt))),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(receipt, width: 48, height: 56, fit: BoxFit.cover),
                  ),
                  title: const Text('Receipt attached', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${(receipt.lengthSync() / 1048576).toStringAsFixed(1)} MB · Stored in the vault'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => AddExpenseScreen(from: e)),
                  ),
                  child: const Text('Duplicate'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF9B3B2A)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete ${e.title}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    final repository = await ref.read(expenseRepositoryProvider.future);
                    await repository.delete(e.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Kept as a personal record. Amrutham does not submit claims or share this with any insurer.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(value, style: const TextStyle(color: onboardMuted)),
        ],
      ),
    );
  }
}

/// One year: total, a bar per month, a split by person, and a CSV copy.
class YearViewScreen extends ConsumerStatefulWidget {
  const YearViewScreen({super.key});

  @override
  ConsumerState<YearViewScreen> createState() => _YearViewState();
}

class _YearViewState extends ConsumerState<YearViewScreen> {
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? <PersonProfile>[];
    final all = ref.watch(expensesProvider).valueOrNull ?? [];
    final years = {DateTime.now().year, ...all.map((e) => e.spentOn.year)}.toList()..sort();
    final inYear = all.where((e) => e.spentOn.year == _year).toList();
    final perMonth = List.generate(12, (m) => _sum(inYear.where((e) => e.spentOn.month == m + 1)));
    final peak = perMonth.fold(0, (a, b) => a > b ? a : b);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text('$_year', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [for (final y in years) ButtonSegment(value: y, label: Text('$y'))],
            selected: {_year},
            onSelectionChanged: (s) => setState(() => _year = s.first),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL SO FAR',
                    style: TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: onboardMuted),
                  ),
                  Text(
                    formatRupees(_sum(inYear)),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var m = 0; m < 12; m++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: peak == 0 ? 2 : 4 + 110 * perMonth[m] / peak,
                                    decoration: BoxDecoration(
                                      color: _year == now.year && m + 1 == now.month
                                          ? onboardAmber
                                          : onboardInk,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'JFMAMJJASOND'[m],
                                    style: const TextStyle(fontSize: 11, color: onboardMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SectionLabel('By person'),
          Card(
            child: Column(
              children: [
                for (final p in people)
                  _InfoRow(p.displayName, formatRupees(_sum(inYear.where((e) => e.personId == p.id)))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OnboardButton(
            label: 'Export CSV',
            onPressed: inYear.isEmpty
                ? null
                : () => SharePlus.instance.share(
                    ShareParams(
                      subject: 'amrutham-expenses-$_year.csv',
                      text: _csv(inYear, people),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Exports are a copy for you, an accountant or whoever you choose. Amrutham does not file claims.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _csv(List<Expense> expenses, List<PersonProfile> people) {
    String q(String? s) => '"${(s ?? '').replaceAll('"', '""')}"';
    final b = StringBuffer('Date,Person,Category,What,Paid to,Paid by,Amount (INR)\n');
    for (final e in expenses.reversed) {
      final name = people.where((p) => p.id == e.personId).firstOrNull?.displayName;
      final d = e.spentOn;
      b.writeln(
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')},'
        '${q(name)},${e.category.label},${q(e.title)},${q(e.payee)},${q(e.paidBy)},'
        '${(e.amountPaise / 100).toStringAsFixed(2)}',
      );
    }
    return b.toString();
  }
}
