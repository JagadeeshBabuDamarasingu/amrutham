import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/expense.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/repository/expense_repository.dart';

import 'realm_test_helper.dart';

void main() {
  test('rupees format with Indian grouping', () {
    expect(formatRupees(366200), '₹3,662');
    expect(formatRupees(4108000), '₹41,080');
    expect(formatRupees(12345600), '₹1,23,456');
    expect(formatRupees(185050), '₹1,850.50');
    expect(formatRupees(0), '₹0');
  });

  test('amounts parse to exact paise and reject nonsense', () {
    expect(parseRupees('1850'), 185000);
    expect(parseRupees('₹ 1,850.5'), 185050);
    expect(parseRupees('0.07'), 7);
    expect(parseRupees('0'), isNull);
    expect(parseRupees('12.345'), isNull);
    expect(parseRupees('abc'), isNull);
  });

  test('expenses store newest first and delete', () async {
    final realm = openInMemoryRealm();
    addTearDown(realm.close);
    final repo = ExpenseRepository(realm);
    const amma = PersonId('amma');
    final older = await repo.add(
      personId: amma,
      title: 'Blood panel',
      payee: 'Vijaya Diagnostics',
      amountPaise: 185000,
      category: ExpenseCategory.tests,
      paidBy: 'UPI',
      spentOn: DateTime(2026, 10, 24),
    );
    await repo.add(
      personId: amma,
      title: 'Consultation',
      amountPaise: 80000,
      category: ExpenseCategory.consultation,
      spentOn: DateTime(2026, 10, 28),
    );
    var all = await repo.watchAll().first;
    expect(all.map((e) => e.title), ['Consultation', 'Blood panel']);
    expect(all.last.amountPaise, 185000);
    await repo.delete(older.id);
    all = await repo.watchAll().first;
    expect(all.single.title, 'Consultation');
  });
}
