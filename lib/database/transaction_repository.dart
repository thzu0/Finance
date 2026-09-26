import 'package:drift/drift.dart';
import 'package:finance/widget/spending_donut_chart.dart';
import 'app_database.dart';
import 'database_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart'; // ← اضافه شد

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

Future<double> getTotalBalance() async {
  final incomeQ = database.selectOnly(database.transactions)
    ..addColumns([database.transactions.amount.sum()])
    ..where(database.transactions.type.equals('income'));

  final expenseQ = database.selectOnly(database.transactions)
    ..addColumns([database.transactions.amount.sum()])
    ..where(database.transactions.type.equals('expense'));

  final incomeRow = await incomeQ.getSingleOrNull();
  final expenseRow = await expenseQ.getSingleOrNull();

  final income = incomeRow?.read(database.transactions.amount.sum()) ?? 0.0;
  final expense = expenseRow?.read(database.transactions.amount.sum()) ?? 0.0;

  return income - expense;
}

// ── کمکی: جمع یه نوع خاص (income/expense) توی یه بازه‌ی زمانی ──
Future<double> _sumByType(String type, DateTime start, DateTime end) async {
  final q = database.selectOnly(database.transactions)
    ..addColumns([database.transactions.amount.sum()])
    ..where(database.transactions.type.equals(type))
    ..where(database.transactions.date.isBiggerOrEqualValue(start))
    ..where(database.transactions.date.isSmallerThanValue(end));
  final row = await q.getSingleOrNull();
  return row?.read(database.transactions.amount.sum()) ?? 0.0;
}

// ── کمکی: جمع یه نوع خاص، قبل از یه تاریخ مشخص (برای موجودی اول ماه) ──
Future<double> _sumByTypeBefore(String type, DateTime date) async {
  final q = database.selectOnly(database.transactions)
    ..addColumns([database.transactions.amount.sum()])
    ..where(database.transactions.type.equals(type))
    ..where(database.transactions.date.isSmallerThanValue(date));
  final row = await q.getSingleOrNull();
  return row?.read(database.transactions.amount.sum()) ?? 0.0;
}

/// موجودی حساب درست *قبل* از یه تاریخ مشخص (برای مقایسه‌ی «نسبت به ماه قبل»)
Future<double> getBalanceBeforeDate(DateTime date) async {
  final income = await _sumByTypeBefore('income', date);
  final expense = await _sumByTypeBefore('expense', date);
  return income - expense;
}

class MonthSummary {
  final double income;
  final double expense;
  final double prevIncome;
  final double prevExpense;

  MonthSummary({
    required this.income,
    required this.expense,
    required this.prevIncome,
    required this.prevExpense,
  });

  double get savings => income - expense;
}

/// خلاصه‌ی درآمد/هزینه‌ی ماه جاری (شمسی) + ماه قبل، برای کارت «این ماه»
Future<MonthSummary> getMonthSummary(DateTime reference) async {
  final j = Jalali.fromDateTime(reference);
  final firstDay = Jalali(j.year, j.month, 1);
  final monthStart = firstDay.toDateTime();
  final monthEnd = Jalali(
    j.year,
    j.month,
    firstDay.monthLength,
  ).toDateTime().add(const Duration(days: 1));

  final prevJ = j.month == 1
      ? Jalali(j.year - 1, 12, 1)
      : Jalali(j.year, j.month - 1, 1);
  final prevStart = prevJ.toDateTime();
  final prevEnd = Jalali(
    prevJ.year,
    prevJ.month,
    prevJ.monthLength,
  ).toDateTime().add(const Duration(days: 1));

  final income = await _sumByType('income', monthStart, monthEnd);
  final expense = await _sumByType('expense', monthStart, monthEnd);
  final prevIncome = await _sumByType('income', prevStart, prevEnd);
  final prevExpense = await _sumByType('expense', prevStart, prevEnd);

  return MonthSummary(
    income: income,
    expense: expense,
    prevIncome: prevIncome,
    prevExpense: prevExpense,
  );
}

class TrendPoint {
  final DateTime date;
  final double balance;
  TrendPoint(this.date, this.balance);
}

/// موجودی تجمعی برای هر یک از N روز اخیر (شامل امروز)، همراه با تاریخ هر نقطه
Future<List<TrendPoint>> getBalanceTrend(int days) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final result = <TrendPoint>[];

  for (int i = days - 1; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final endOfDay = day.add(const Duration(days: 1));
    final income = await _sumByTypeBefore('income', endOfDay);
    final expense = await _sumByTypeBefore('expense', endOfDay);
    result.add(TrendPoint(day, income - expense));
  }

  return result;
}

/// درصد تغییر بین مقدار فعلی و قبلی رو حساب می‌کنه.
/// برمی‌گردونه: (متن درصد فرمت‌شده, آیا افزایش داشته؟)
({String text, bool isIncrease}) calculatePercentChange(
  double current,
  double previous,
) {
  if (previous == 0) {
    // ماه قبل چیزی نبوده؛ اگه الان چیزی هست یعنی ۱۰۰٪ افزایش، وگرنه بدون تغییر
    if (current == 0) return (text: '۰٪', isIncrease: true);
    return (text: '۱۰۰٪', isIncrease: true);
  }

  final change = ((current - previous) / previous) * 100;
  final isIncrease = change >= 0;
  final text = '${change.abs().toStringAsFixed(0)}٪';
  return (text: text, isIncrease: isIncrease);
}

/// هزینه‌های ماه جاری (شمسی) رو بر اساس دسته‌بندی جمع می‌کنه
/// و به‌صورت درصد از کل برمی‌گردونه (برای دونات صفحه‌ی اصلی)
Future<List<SpendingCategory>> getExpenseByCategory(DateTime reference) async {
  final j = Jalali.fromDateTime(reference);
  final firstDay = Jalali(j.year, j.month, 1);
  final monthStart = firstDay.toDateTime();
  final monthEnd = Jalali(
    j.year,
    j.month,
    firstDay.monthLength,
  ).toDateTime().add(const Duration(days: 1));

  final query =
      database.selectOnly(database.transactions).join([
          innerJoin(
            database.categories,
            database.categories.id.equalsExp(database.transactions.categoryId),
          ),
        ])
        ..addColumns([
          database.categories.name,
          database.transactions.amount.sum(),
        ])
        ..where(database.transactions.type.equals('expense'))
        ..where(database.transactions.date.isBiggerOrEqualValue(monthStart))
        ..where(database.transactions.date.isSmallerThanValue(monthEnd))
        ..groupBy([database.categories.id]);

  final rows = await query.get();

  final raw = rows
      .map((row) {
        final name = row.read(database.categories.name)!;
        final sum = row.read(database.transactions.amount.sum()) ?? 0.0;
        return MapEntry(name, sum);
      })
      .where((e) => e.value > 0)
      .toList();

  final total = raw.fold<double>(0, (a, b) => a + b.value);
  if (total == 0) return [];

  raw.sort((a, b) => b.value.compareTo(a.value));

  // ← اگه بیش از ۴ دسته داشتیم، بقیه رو زیر «سایر» جمع می‌کنیم
  List<MapEntry<String, double>> grouped;
  if (raw.length > 4) {
    final top = raw.take(4).toList();
    final restSum = raw.skip(4).fold<double>(0, (a, b) => a + b.value);
    grouped = [...top, MapEntry('سایر', restSum)];
  } else {
    grouped = raw;
  }

  return grouped
      .map(
        (e) => SpendingCategory(label: e.key, percent: (e.value / total) * 100),
      )
      .toList();
}
