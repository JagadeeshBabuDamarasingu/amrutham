import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/expense.dart';
import '../model/ids.dart';

class ExpenseRepository {
  final Realm _realm;

  ExpenseRepository(this._realm);

  /// Every expense for the whole family, newest first.
  Stream<List<Expense>> watchAll() {
    return _realm
        .query<ExpenseRow>('TRUEPREDICATE SORT(spentOn DESC, addedAt DESC)')
        .changes
        .map((c) => c.results.map(_fromRow).toList());
  }

  Future<Expense> add({
    required PersonId personId,
    required String title,
    String? payee,
    required int amountPaise,
    required ExpenseCategory category,
    String? paidBy,
    required DateTime spentOn,
  }) async {
    final id = ExpenseId(Ulid().toString());
    final addedAt = DateTime.now();
    _realm.write(() {
      _realm.add(
        ExpenseRow(
          id.value,
          personId.value,
          title,
          amountPaise,
          category.name,
          spentOn,
          addedAt,
          payee: payee,
          paidBy: paidBy,
        ),
      );
    });
    return Expense(
      id: id,
      personId: personId,
      title: title,
      payee: payee,
      amountPaise: amountPaise,
      category: category,
      paidBy: paidBy,
      spentOn: spentOn,
      addedAt: addedAt,
    );
  }

  Future<void> delete(ExpenseId id) async {
    final row = _realm.find<ExpenseRow>(id.value);
    if (row != null) _realm.write(() => _realm.delete(row));
  }

  Expense _fromRow(ExpenseRow row) => Expense(
    id: ExpenseId(row.id),
    personId: PersonId(row.personId),
    title: row.title,
    payee: row.payee,
    amountPaise: row.amountPaise,
    category: ExpenseCategory.values.byName(row.category),
    paidBy: row.paidBy,
    spentOn: row.spentOn,
    addedAt: row.addedAt,
  );
}
