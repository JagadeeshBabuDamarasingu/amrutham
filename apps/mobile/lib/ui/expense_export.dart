import '../model/expense.dart';
import '../model/person.dart';

String _date(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _personName(List<PersonProfile> people, Expense e) =>
    people.where((p) => p.id == e.personId).firstOrNull?.displayName ?? '';

/// One row per expense, oldest first, in plain CSV. A spreadsheet or an
/// accountant can open it; amounts are rupees with two decimals.
String expensesCsv(List<Expense> expenses, List<PersonProfile> people) {
  String q(String? s) => '"${(s ?? '').replaceAll('"', '""')}"';
  final b = StringBuffer('Date,Person,Category,What,Paid to,Paid by,Amount (INR)\n');
  final oldestFirst = [...expenses]..sort((a, b) => a.spentOn.compareTo(b.spentOn));
  for (final e in oldestFirst) {
    b.writeln(
      '${_date(e.spentOn)},${q(_personName(people, e))},${e.category.label},'
      '${q(e.title)},${q(e.payee)},${q(e.paidBy)},'
      '${(e.amountPaise / 100).toStringAsFixed(2)}',
    );
  }
  return b.toString();
}

String escapeHtml(String s) =>
    s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

/// The printable year: a table of every entry, the total for each person and the
/// grand total. HTML, not drawn PDF text, so the phone's own renderer has the
/// fonts for names in Telugu, Hindi and Urdu.
String expensesPdfHtml(int year, List<Expense> expenses, List<PersonProfile> people) {
  final oldestFirst = [...expenses]..sort((a, b) => a.spentOn.compareTo(b.spentOn));
  final byPerson = <String, int>{};
  var total = 0;
  for (final e in oldestFirst) {
    final name = _personName(people, e);
    byPerson[name] = (byPerson[name] ?? 0) + e.amountPaise;
    total += e.amountPaise;
  }
  String cell(String s, {bool right = false}) =>
      '<td style="padding:4px 8px;border-bottom:1px solid #ddd;${right ? 'text-align:right;' : ''}">${escapeHtml(s)}</td>';
  final rows = StringBuffer();
  for (final e in oldestFirst) {
    rows.write(
      '<tr>${cell(_date(e.spentOn))}${cell(_personName(people, e))}${cell(e.category.label)}'
      '${cell(e.title)}${cell(e.payee ?? '')}${cell(formatRupees(e.amountPaise), right: true)}</tr>',
    );
  }
  final people_ = byPerson.entries
      .map((p) => '<tr>${cell(p.key)}${cell(formatRupees(p.value), right: true)}</tr>')
      .join();
  return '<html><body style="font-family:sans-serif;font-size:13px">'
      '<h1>Medical expenses $year</h1>'
      '<table style="border-collapse:collapse;width:100%">'
      '<tr><th align="left">Date</th><th align="left">Person</th><th align="left">Category</th>'
      '<th align="left">What</th><th align="left">Paid to</th><th align="right">Amount</th></tr>'
      '$rows</table>'
      '<h2>By person</h2><table style="border-collapse:collapse">$people_</table>'
      '<h2>Total: ${escapeHtml(formatRupees(total))}</h2>'
      '<p style="font-size:11px">A personal record kept in Amrutham. It is a copy for you, an accountant '
      'or whoever you choose; Amrutham does not file claims.</p>'
      '</body></html>';
}
