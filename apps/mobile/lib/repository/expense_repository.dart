import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:realm/realm.dart';
import 'package:ulid/ulid.dart';

import '../db/realm_schemas.dart';
import '../model/expense.dart';
import '../model/ids.dart';

class ExpenseRepository {
  final Realm _realm;

  /// Where receipt photos live (`<vault>/receipts/<expenseId>.<ext>`). Null in
  /// tests that don't deal with photos.
  final Directory? vaultDir;

  ExpenseRepository(this._realm, [this.vaultDir]);

  /// The receipt photo for an expense, or null if none was attached.
  File? receiptFor(ExpenseId id) {
    final dir = vaultDir == null ? null : Directory(p.join(vaultDir!.path, receiptsDir));
    if (dir == null || !dir.existsSync()) return null;
    return dir
        .listSync()
        .whereType<File>()
        .where((f) => p.basenameWithoutExtension(f.path) == id.value)
        .firstOrNull;
  }

  static const receiptsDir = 'receipts';

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
    File? receipt,
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
    if (receipt != null && vaultDir != null) {
      final dir = Directory(p.join(vaultDir!.path, receiptsDir));
      await dir.create(recursive: true);
      await receipt.copy(p.join(dir.path, '${id.value}${p.extension(receipt.path).toLowerCase()}'));
    }
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

  /// Replaces every editable field. A new [receipt] replaces the old photo;
  /// null keeps what is there.
  Future<void> update(
    ExpenseId id, {
    required PersonId personId,
    required String title,
    String? payee,
    required int amountPaise,
    required ExpenseCategory category,
    String? paidBy,
    required DateTime spentOn,
    File? receipt,
  }) async {
    final row = _realm.find<ExpenseRow>(id.value);
    if (row == null) return;
    _realm.write(() {
      row
        ..personId = personId.value
        ..title = title
        ..payee = payee
        ..amountPaise = amountPaise
        ..category = category.name
        ..paidBy = paidBy
        ..spentOn = spentOn;
    });
    if (receipt != null && vaultDir != null) {
      await receiptFor(id)?.delete();
      final dir = Directory(p.join(vaultDir!.path, receiptsDir));
      await dir.create(recursive: true);
      await receipt.copy(p.join(dir.path, '${id.value}${p.extension(receipt.path).toLowerCase()}'));
    }
  }

  Future<void> delete(ExpenseId id) async {
    final row = _realm.find<ExpenseRow>(id.value);
    if (row != null) _realm.write(() => _realm.delete(row));
    await receiptFor(id)?.delete();
  }

  Expense _fromRow(ExpenseRow row) => Expense(
    id: ExpenseId(row.id),
    personId: PersonId(row.personId),
    title: row.title,
    payee: row.payee,
    amountPaise: row.amountPaise,
    category: ExpenseCategory.values.byName(row.category),
    paidBy: row.paidBy,
    spentOn: row.spentOn.toLocal(),
    addedAt: row.addedAt.toLocal(),
  );
}
