import 'package:drift/drift.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'database_provider.dart';

class InsightsResult {
  final List<double> values;
  final double previousTotal;
  final List<CategoryShare> categories;

  InsightsResult({
    required this.values,
    required this.previousTotal,
    required this.categories,
  });
}

class CategoryShare {
  final String label;
  final double percent;
  CategoryShare(this.label, this.percent);
}

Future<double> _sumExpense(DateTime start, DateTime end) async {
  final q = database.selectOnly(database.transactions)
    ..addColumns([database.transactions.amount.sum()])
    ..where(database.transactions.type.equals('expense'))
    ..where(database.transactions.date.isBiggerOrEqualValue(start))
    ..where(database.transactions.date.isSmallerThanValue(end));
  final row = await q.getSingleOrNull();
  return row?.read(database.transactions.amount.sum()) ?? 0.0;
}

Future<List<CategoryShare>> _categoryBreakdown(
  DateTime start,
  DateTime end,
) async {
  final rows =
      await (database.select(database.transactions).join([
              innerJoin(
                database.categories,
                database.categories.id.equalsExp(
                  database.transactions.categoryId,
                ),
              ),
            ])
            ..where(database.transactions.type.equals('expense'))
            ..where(database.transactions.date.isBiggerOrEqualValue(start))
            ..where(database.transactions.date.isSmallerThanValue(end)))
          .get();

  final totals = <int, double>{};
  final names = <int, String>{};
  double grand = 0;

  for (final row in rows) {
    final t = row.readTable(database.transactions);
    final c = row.readTable(database.categories);
    totals[c.id] = (totals[c.id] ?? 0) + t.amount;
    names[c.id] = c.name;
    grand += t.amount;
  }

  if (grand == 0) return [];

  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return entries
      .map((e) => CategoryShare(names[e.key]!, ((e.value / grand) * 100)))
      .toList();
}

DateTime _startOfPersianWeek(DateTime ref) {
  // هفته‌ی فارسی از شنبه شروع میشه. weekday دارت: دوشنبه=۱ ... یکشنبه=۷
  const daysSinceSaturday = {6: 0, 7: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6};
  final day = DateTime(ref.year, ref.month, ref.day);
  return day.subtract(Duration(days: daysSinceSaturday[ref.weekday]!));
}

// ─── هفته ───
Future<InsightsResult> getWeekInsights(DateTime reference) async {
  final startOfWeek = _startOfPersianWeek(reference);
  final endOfWeek = startOfWeek.add(const Duration(days: 7));
  final prevStart = startOfWeek.subtract(const Duration(days: 7));

  final values = <double>[];
  for (var i = 0; i < 7; i++) {
    final dayStart = startOfWeek.add(Duration(days: i));
    values.add(
      await _sumExpense(dayStart, dayStart.add(const Duration(days: 1))),
    );
  }

  final previousTotal = await _sumExpense(prevStart, startOfWeek);
  final categories = await _categoryBreakdown(startOfWeek, endOfWeek);

  return InsightsResult(
    values: values,
    previousTotal: previousTotal,
    categories: categories,
  );
}

// ─── ماه (تقسیم به ۴ بازه‌ی تقریبی هفتگی) ───
Future<InsightsResult> getMonthInsights(DateTime reference) async {
  final j = Jalali.fromDateTime(reference);
  final firstDay = Jalali(j.year, j.month, 1);
  final monthLength = firstDay.monthLength;
  final monthStart = firstDay.toDateTime();
  final monthEnd = Jalali(
    j.year,
    j.month,
    monthLength,
  ).toDateTime().add(const Duration(days: 1));

  final chunk = (monthLength / 4).ceil();
  final values = <double>[];
  for (var w = 0; w < 4; w++) {
    final startDay = w * chunk + 1;
    if (startDay > monthLength) {
      values.add(0.0);
      continue;
    }
    final endDay = ((w + 1) * chunk).clamp(0, monthLength);
    final start = Jalali(j.year, j.month, startDay).toDateTime();
    final end = Jalali(
      j.year,
      j.month,
      endDay,
    ).toDateTime().add(const Duration(days: 1));
    values.add(await _sumExpense(start, end));
  }

  final prevJ = j.month == 1
      ? Jalali(j.year - 1, 12, 1)
      : Jalali(j.year, j.month - 1, 1);
  final prevLength = prevJ.monthLength;
  final prevStart = prevJ.toDateTime();
  final prevEnd = Jalali(
    prevJ.year,
    prevJ.month,
    prevLength,
  ).toDateTime().add(const Duration(days: 1));
  final previousTotal = await _sumExpense(prevStart, prevEnd);

  final categories = await _categoryBreakdown(monthStart, monthEnd);

  return InsightsResult(
    values: values,
    previousTotal: previousTotal,
    categories: categories,
  );
}

// ─── سال ───
Future<InsightsResult> getYearInsights(DateTime reference) async {
  final j = Jalali.fromDateTime(reference);
  final values = <double>[];
  for (var m = 1; m <= 12; m++) {
    final firstDay = Jalali(j.year, m, 1);
    final len = firstDay.monthLength;
    final start = firstDay.toDateTime();
    final end = Jalali(
      j.year,
      m,
      len,
    ).toDateTime().add(const Duration(days: 1));
    values.add(await _sumExpense(start, end));
  }

  final prevStart = Jalali(j.year - 1, 1, 1).toDateTime();
  final prevEnd = Jalali(j.year, 1, 1).toDateTime();
  final previousTotal = await _sumExpense(prevStart, prevEnd);

  final yearStart = Jalali(j.year, 1, 1).toDateTime();
  final yearEnd = Jalali(j.year + 1, 1, 1).toDateTime();
  final categories = await _categoryBreakdown(yearStart, yearEnd);

  return InsightsResult(
    values: values,
    previousTotal: previousTotal,
    categories: categories,
  );
}
