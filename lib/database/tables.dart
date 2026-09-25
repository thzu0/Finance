import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()(); // مثلاً '#FF5733'
  TextColumn get type => text()(); // 'income' یا 'expense'
}

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(
    const Constant(''),
  )(); //with default means if user dont write any note this property use '' for default
  TextColumn get type => text()(); // 'income' یا 'expense'
}

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId =>
      integer().nullable().references(Categories, #id)();
  RealColumn get amount => real()();
  TextColumn get period => text()(); // 'week' / 'month' / 'year'
  DateTimeColumn get startDate => dateTime()();
  // ← ستون جدید: فقط برای حالت 'custom' مقدار داره.
  // برای بودجه‌ی ماهانه، نیازی نیست چون خودمون از startDate
  // بازه‌ی همون ماه رو حساب می‌کنیم.
  DateTimeColumn get endDate => dateTime().nullable()();
}
