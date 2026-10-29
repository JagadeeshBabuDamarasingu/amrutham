import 'ids.dart';

enum ExpenseCategory {
  consultation('Consultation'),
  medicines('Medicines'),
  tests('Tests'),
  procedure('Procedure'),
  transport('Transport'),
  other('Other');

  const ExpenseCategory(this.label);
  final String label;
}

class Expense {
  final ExpenseId id;
  final PersonId personId;
  final String title;
  final String? payee;
  final int amountPaise;
  final ExpenseCategory category;
  final String? paidBy;
  final DateTime spentOn;
  final DateTime addedAt;

  const Expense({
    required this.id,
    required this.personId,
    required this.title,
    this.payee,
    required this.amountPaise,
    required this.category,
    this.paidBy,
    required this.spentOn,
    required this.addedAt,
  });
}

/// ₹1,23,456 — Indian digit grouping (last three, then pairs). Paise are shown
/// only when there are any.
String formatRupees(int paise) {
  final negative = paise < 0;
  final abs = paise.abs();
  final rupees = (abs ~/ 100).toString();
  final rest = abs % 100;
  String grouped;
  if (rupees.length <= 3) {
    grouped = rupees;
  } else {
    final head = rupees.substring(0, rupees.length - 3);
    final tail = rupees.substring(rupees.length - 3);
    final pairs = RegExp(r'(\d)(?=(\d\d)+$)');
    grouped = '${head.replaceAllMapped(pairs, (m) => '${m[1]},')},$tail';
  }
  final cents = rest == 0 ? '' : '.${rest.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}₹$grouped$cents';
}

/// "1850", "1,850.50" or "₹ 1850" to paise; null if it isn't a positive amount.
int? parseRupees(String input) {
  final cleaned = input.replaceAll(RegExp(r'[₹,\s]'), '');
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final paise =
      int.parse(match[1]!) * 100 + int.parse((match[2] ?? '').padRight(2, '0'));
  return paise > 0 ? paise : null;
}
