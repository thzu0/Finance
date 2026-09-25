import 'package:drift/drift.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'app_database.dart';
import 'database_provider.dart';

Future<int> addBudget({
  required int categoryId,
  required double amount,
  required String period,
  required DateTime startDate,
  DateTime? endDate,
}) async {
  final id = await database
      .into(database.budgets)
      .insert(
        BudgetsCompanion.insert(
          categoryId: Value(categoryId),
          amount: amount,
          period: period,
          startDate: startDate,
          endDate: Value(endDate),
        ),
      );
  budgetsTicker.value++;
  return id;
}

// ← تابع جدید: به‌جای ساختن یه ردیف جدید، یه بودجه‌ی موجود رو
// آپدیت می‌کنه (برای صفحه‌ی ویرایش لازمه).
Future<void> updateBudget({
  required int id,
  required int categoryId,
  required double amount,
  required String period,
  required DateTime startDate,
  DateTime? endDate,
}) async {
  await (database.update(
    database.budgets,
  )..where((b) => b.id.equals(id))).write(
    BudgetsCompanion(
      categoryId: Value(categoryId),
      amount: Value(amount),
      period: Value(period),
      startDate: Value(startDate),
      endDate: Value(endDate),
    ),
  );
  budgetsTicker.value++;
}

Future<void> deleteBudget(int id) async {
  await (database.delete(database.budgets)..where((b) => b.id.equals(id))).go();
  budgetsTicker.value++;
}

class BudgetWithSpent {
  final Budget budget;
  final Category category;
  final double spent;

  BudgetWithSpent({
    required this.budget,
    required this.category,
    required this.spent,
  });
}

(DateTime, DateTime) _effectiveRange(Budget b) {
  if (b.period == 'monthly') {
    final j = Jalali.fromDateTime(b.startDate);
    final jFirstDay = Jalali(j.year, j.month, 1);
    final start = jFirstDay.toDateTime();
    final lastDay = jFirstDay.monthLength;
    final end = Jalali(
      j.year,
      j.month,
      lastDay,
    ).toDateTime().add(const Duration(hours: 23, minutes: 59, seconds: 59));
    return (start, end);
  } else {
    final end = b.endDate ?? b.startDate;
    return (b.startDate, end);
  }
}

Future<List<BudgetWithSpent>> getBudgetsForMonth(int jYear, int jMonth) async {
  final jFirstDay = Jalali(jYear, jMonth, 1);
  final monthStart = jFirstDay.toDateTime();
  final lastDay = jFirstDay.monthLength;
  final monthEnd = Jalali(
    jYear,
    jMonth,
    lastDay,
  ).toDateTime().add(const Duration(hours: 23, minutes: 59, seconds: 59));

  final rows = await (database.select(database.budgets).join([
    innerJoin(
      database.categories,
      database.categories.id.equalsExp(database.budgets.categoryId),
    ),
  ])).get();

  final result = <BudgetWithSpent>[];

  for (final row in rows) {
    final b = row.readTable(database.budgets);
    final c = row.readTable(database.categories);

    final (start, end) = _effectiveRange(b);

    final overlaps = start.isBefore(monthEnd) && end.isAfter(monthStart);
    if (!overlaps) continue;

    final sumQuery = database.selectOnly(database.transactions)
      ..addColumns([database.transactions.amount.sum()])
      ..where(database.transactions.categoryId.equals(b.categoryId ?? -1))
      ..where(database.transactions.type.equals('expense'))
      ..where(database.transactions.date.isBiggerOrEqualValue(start))
      ..where(database.transactions.date.isSmallerOrEqualValue(end));

    final sumRow = await sumQuery.getSingleOrNull();
    final spent = sumRow?.read(database.transactions.amount.sum()) ?? 0.0;

    result.add(BudgetWithSpent(budget: b, category: c, spent: spent));
  }

  return result;
}
