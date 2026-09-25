import 'package:drift/drift.dart';
import 'app_database.dart';
import 'database_provider.dart';

/// یه تراکنش جدید (هزینه یا درآمد) به دیتابیس اضافه می‌کنه.
Future<int> addTransaction({
  required double amount,
  required int categoryId,
  required DateTime date,
  required String type,
  String note = '',
}) async {
  // این خط دقیقاً همون کد قبلی توئه (فقط await گرفتیم تا بشه بعدش کد اضافه کرد)
  final id = await database
      .into(database.transactions)
      .insert(
        TransactionsCompanion(
          amount: Value(amount),
          categoryId: Value(categoryId),
          date: Value(date),
          type: Value(type),
          note: Value(note),
        ),
      );

  // ← خط جدید: به همه‌ی صفحه‌هایی که لیست تراکنش‌ها رو نشون میدن خبر میده
  // که دیتا تغییر کرده، تا خودشون رو رفرش کنن.
  transactionsTicker.value++;

  return id;
}

/// یه تراکنش رو با شناسه‌ش (id) از دیتابیس حذف می‌کنه.
/// این تابع جدیده — برای مشکل #۴ (حذف با نگه‌داشتن روی تراکنش) لازمش داری.
Future<void> deleteTransaction(int id) async {
  await (database.delete(
    database.transactions,
  )..where((t) => t.id.equals(id))).go();

  // ← اینجا هم بعد از حذف، به همه خبر میدیم که دیتا تغییر کرد
  transactionsTicker.value++;
}

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;
  TransactionWithCategory(this.transaction, this.category);
}

/// همه‌ی تراکنش‌ها رو همراه با دسته‌بندی‌شون از دیتابیس می‌خونه
/// (این تابع دست نخورده باقی مونده، همون کد قبلی خودته)
Future<List<TransactionWithCategory>> getAllTransactions() async {
  final query = database.select(database.transactions).join([
    innerJoin(
      database.categories,
      database.categories.id.equalsExp(database.transactions.categoryId),
    ),
  ])..orderBy([OrderingTerm.desc(database.transactions.date)]);

  final rows = await query.get();

  return rows.map((row) {
    final t = row.readTable(database.transactions);
    final c = row.readTable(database.categories);
    return TransactionWithCategory(t, c);
  }).toList();
}
