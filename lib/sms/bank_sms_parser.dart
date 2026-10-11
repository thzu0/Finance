import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/sms/sms_parser.dart';

/// شناسه‌ی یکتای پیامک: فرستنده + زمان دریافت + هش متن (نه SmsMessage.id)
String buildSmsId(String sender, DateTime receivedAt, String body) {
  final hash = sha1.convert(utf8.encode(body)).toString().substring(0, 16);
  return '$sender|${receivedAt.millisecondsSinceEpoch}|$hash';
}

/// یک پیامک رو پارس می‌کنه و اگه تکراری نبود ثبت می‌کنه.
/// true یعنی تراکنش جدید ثبت شد.
///
/// [bankName] همون فرستنده‌ی انتخاب‌شده‌ست.
/// [accountLast4Filter] خالی یعنی فیلتر حساب خاموشه؛ وگرنه پیامکی که شناسه‌ی
/// حسابش با این مقدار فرق داره رد می‌شه (پیامک بدون شناسه قبول می‌شه).
Future<bool> importSmsForBank(
  String bankName,
  String body, {
  required DateTime receivedAt,
  required String sender,
  String accountLast4Filter = '',
}) async {
  final sms = parseBankSms(body, receivedAt: receivedAt);
  if (sms == null) {
    // شبیه تراکنشه ولی خونده نشد: دور ریخته نشه
    if (looksLikeBankTransaction(body)) {
      await _saveUnparsed(sender, receivedAt, body);
    }
    return false;
  }

  if (accountLast4Filter.isNotEmpty &&
      sms.accountLast4 != null &&
      sms.accountLast4 != accountLast4Filter) {
    return false;
  }

  // لنگر موجودی (فقط وقتی مانده‌ی سالم داریم)
  final st = AppSettings.instance;
  final balance = sms.balanceRial;
  final ts = sms.timestamp.millisecondsSinceEpoch;
  if (balance != null && ts >= st.get<int>('sms_bal_ts', 0)) {
    await st.set('sms_bal_ts', ts);
    await st.set('sms_bal_rial', balance);
  }

  final smsId = buildSmsId(sender, receivedAt, body);
  final amount = sms.amountRial.toDouble();

  // چک اول: همین پیامک قبلاً ثبت شده؟
  final sameSms = await (database.select(
    database.transactions,
  )..where((t) => t.smsId.equals(smsId))).get();
  if (sameSms.isNotEmpty) return false;

  // چک دوم (ردیف‌های قدیمی بدون smsId): تاریخ + مبلغ + نوع
  final dup =
      await (database.select(database.transactions)..where(
            (t) =>
                t.smsId.isNull() &
                t.date.equals(sms.timestamp) &
                t.amount.equals(amount) &
                t.type.equals(sms.type),
          ))
          .get();
  if (dup.isNotEmpty) return false;

  final cats = await getCategoriesByType(sms.type);
  if (cats.isEmpty) return false;
  final cat = cats.firstWhere(
    (c) => c.name == 'سایر' || c.name == 'سایر درآمدها',
    orElse: () => cats.first,
  );

  await addTransaction(
    amount: amount,
    categoryId: cat.id,
    date: sms.timestamp,
    type: sms.type,
    note: 'پیامک $bankName',
    source: 'sms',
    bankName: bankName,
    accountLast4: sms.accountLast4,
    balanceAfterRial: balance,
    smsId: smsId,
  );
  return true;
}

Future<void> _saveUnparsed(
  String sender,
  DateTime receivedAt,
  String body,
) async {
  await database
      .into(database.unparsedSmsMessages)
      .insert(
        UnparsedSmsMessagesCompanion.insert(
          smsId: buildSmsId(sender, receivedAt, body),
          sender: sender,
          body: body,
          receivedAt: receivedAt,
        ),
        mode: InsertMode.insertOrIgnore,
      );
  unparsedSmsTicker.value++;
}

Future<int> countUnparsedSms() async {
  final count = countAll();
  final row = await (database.selectOnly(
    database.unparsedSmsMessages,
  )..addColumns([count])).getSingle();
  return row.read(count) ?? 0;
}
