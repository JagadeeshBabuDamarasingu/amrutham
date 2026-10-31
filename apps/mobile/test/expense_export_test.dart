// The year's expenses leave the app as a CSV and a printable page. Both must be
// exact, because someone will hand them to an accountant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/model/person.dart';
import 'package:amrutham/providers/app_providers.dart';
import 'package:amrutham/ui/expense_export.dart';
import 'package:amrutham/ui/expenses_screen.dart';

PersonProfile _p(String id, String name) => PersonProfile(
  id: PersonId(id),
  displayName: name,
  relationship: RelationshipType.self,
  createdAt: DateTime(2025),
);

Expense _e(String id, String person, String title, int paise, DateTime on, {String? payee, ExpenseCategory c = ExpenseCategory.tests}) => Expense(
  id: ExpenseId(id),
  personId: PersonId(person),
  title: title,
  payee: payee,
  amountPaise: paise,
  category: c,
  spentOn: on,
  addedAt: on,
);

void main() {
  final people = [_p('a', 'Appa'), _p('m', 'Amma')];
  final expenses = [
    _e('2', 'm', 'Eye test, "dilated"', 80000, DateTime(2026, 5, 3), payee: 'Sankara, Eye Care'),
    _e('1', 'a', 'Blood panel', 185050, DateTime(2026, 2, 14), payee: 'City Lab'),
  ];

  test('the CSV has a header, oldest first, quoted text and rupees to two places', () {
    final lines = expensesCsv(expenses, people).trim().split('\n');
    expect(lines.first, 'Date,Person,Category,What,Paid to,Paid by,Amount (INR)');
    expect(lines[1], '2026-02-14,"Appa",Tests,"Blood panel","City Lab","",1850.50');
    expect(lines[2], '2026-05-03,"Amma",Tests,"Eye test, ""dilated""","Sankara, Eye Care","",800.00');
    expect(lines, hasLength(3));
  });

  test('the printable page has the year, each entry, each person and the total, escaped', () {
    final tricky = [...expenses, _e('3', 'a', 'X-ray <back> & knee', 50000, DateTime(2026, 7, 1))];
    final html = expensesPdfHtml(2026, tricky, people);
    expect(html, contains('Medical expenses 2026'));
    expect(html, contains('Blood panel'));
    expect(html, contains('X-ray &lt;back&gt; &amp; knee'));
    expect(html, isNot(contains('<back>')));
    expect(html, contains('₹2,350.50')); // Appa: 1850.50 + 500
    expect(html, contains('₹800')); // Amma
    expect(html, contains('Total: ₹3,150.50'));
    expect(html.indexOf('2026-02-14'), lessThan(html.indexOf('2026-05-03')));
  });

  test('an empty year still prints a valid page with a zero total', () {
    expect(expensesPdfHtml(2026, const [], people), contains('Total: ₹0'));
  });

  testWidgets('the year view offers both exports when there is something to export', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profilesProvider.overrideWith((ref) => Stream.value(people)),
          // The year view opens on the current year, so use dates in it.
          expensesProvider.overrideWith(
            (ref) => Stream.value([_e('9', 'a', 'Blood panel', 100000, DateTime(DateTime.now().year, 1, 5))]),
          ),
        ],
        child: const MaterialApp(home: YearViewScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Export PDF'), 200);
    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
  });
}
