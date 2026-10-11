import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()(); // مثلاً '#FF5733'
  TextColumn get type => text()(); // 'income' یا 'expense'
}

@TableIndex(name: 'transactions_sms_id', columns: {#smsId}, unique: true)
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get amount => real()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().withDefault(
    const Constant(''),
  )(); //with default means if user dont write any note this property use '' for default
  TextColumn get type => text()(); // 'income' یا 'expense'

  /// منبع تراکنش: 'sms' یا 'manual'
  TextColumn get source => text().nullable()();
  TextColumn get bankName => text().nullable()();

  /// فقط ۴ رقم آخر حساب/کارت
  TextColumn get accountLast4 => text().nullable()();

  /// مانده‌ی بعد از تراکنش (ریال)
  IntColumn get balanceAfterRial => integer().nullable()();

  /// ترکیب فرستنده + زمان + هش متن پیامک (یکتا؛ چند NULL مجازه)
  TextColumn get smsId => text().nullable()();
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

/// اعلان‌های درون‌برنامه‌ای
///
/// `@DataClassName('AppNotification')` رو گذاشتیم چون Drift به‌صورت
/// پیش‌فرض کلاس `Notification` می‌ساخت که با `Notification` خود Flutter
/// تداخل می‌کرد. با این annotation، کلاس دیتای ما `AppNotification` می‌شه.
@DataClassName('AppNotification')
class Notifications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// عنوان کوتاه (مثلاً: «هشدار بودجه»)
  TextColumn get title => text()();

  /// متن کامل اعلان
  TextColumn get body => text()();

  /// نوع اعلان: 'budget' | 'sms' | 'daily' | 'weekly' | 'monthly' | 'tips' | 'system'
  TextColumn get type => text()();

  /// اطلاعات اضافی (مثلاً id تراکنش یا دسته) — به‌صورت JSON
  TextColumn get payload => text().nullable()();

  /// خونده شده یا نه
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
}

/// پیامک‌های فرستنده‌ی انتخاب‌شده که شبیه تراکنش بودن ولی پارس نشدن
@DataClassName('UnparsedSms')
class UnparsedSmsMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// همون smsId تراکنش‌ها (فرستنده + زمان + هش متن)؛ برای جلوگیری از تکرار
  TextColumn get smsId => text().unique()();
  TextColumn get sender => text()();
  TextColumn get body => text()();
  DateTimeColumn get receivedAt => dateTime()();
}
