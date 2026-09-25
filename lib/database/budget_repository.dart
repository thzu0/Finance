import 'package:drift/drift.dart';
import 'app_database.dart';
import 'database_provider.dart';

/// یه بودجه‌ی جدید (برای یه دسته‌ی خاص، در یه بازه‌ی زمانی) ذخیره می‌کنه.
/// period باید 'monthly' یا 'custom' باشه.
/// برای 'monthly'، فقط startDate مهمه (بازه‌ش خودکار میشه کل همون ماه).
/// برای 'custom'، endDate هم باید پر شده باشه.
Future<int> addBudget({
  required int categoryId,
  required double amount,
  required String period, // 'monthly' | 'custom'
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

  // ← به همه‌ی صفحه‌هایی که لیست بودجه‌ها رو نشون میدن خبر میده
  budgetsTicker.value++;

  return id;
}

Future<void> deleteBudget(int id) async {
  await (database.delete(database.budgets)..where((b) => b.id.equals(id))).go();
  budgetsTicker.value++;
}

/// نتیجه‌ی نهایی هر بودجه: خودِ بودجه + دسته‌ش + مقدار «خرج‌شده»‌ی
/// واقعی (محاسبه‌شده از جمع تراکنش‌های هزینه‌ی همون دسته توی همون بازه).
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

/// بازه‌ی زمانی مؤثر یه بودجه رو برمی‌گردونه.
/// برای ماهانه: از اول تا آخر همون ماهی که startDate توشه.
/// برای سفارشی: خودِ startDate تا endDate (اگه endDate نال بود، یعنی داده خرابه، همون startDate رو برمی‌گردونیم).
(DateTime, DateTime) _effectiveRange(Budget b) {
  if (b.period == 'monthly') {
    final start = DateTime(b.startDate.year, b.startDate.month, 1);
    final end = DateTime(
      b.startDate.year,
      b.startDate.month + 1,
      1,
    ).subtract(const Duration(milliseconds: 1));
    return (start, end);
  } else {
    final end = b.endDate ?? b.startDate;
    return (b.startDate, end);
  }
}

/// همه‌ی بودجه‌هایی که بازه‌شون با ماه/سال داده‌شده هم‌پوشانی داره رو برمی‌گردونه،
/// همراه با دسته و مقدار خرج‌شده‌ی واقعی (از جدول transactions).
Future<List<BudgetWithSpent>> getBudgetsForMonth(int year, int month) async {
  final monthStart = DateTime(year, month, 1);
  final monthEnd = DateTime(
    year,
    month + 1,
    1,
  ).subtract(const Duration(milliseconds: 1));

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

    // فقط بودجه‌هایی که بازه‌شون توی ماه انتخاب‌شده افته یا باهاش تداخل داره
    final overlaps = start.isBefore(monthEnd) && end.isAfter(monthStart);
    if (!overlaps) continue;

    // جمع تراکنش‌های هزینه‌ی همین دسته، توی بازه‌ی خودِ بودجه (نه کل ماه)
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
