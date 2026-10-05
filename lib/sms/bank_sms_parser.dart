import 'package:drift/drift.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

/// نتیجه‌ی پارس یک پیامک بانکی (مبلغ‌ها همه ریال خام)
class ParsedSms {
  final String accountNo;
  final bool isDeposit;
  final int amountRial;
  final int balanceRial;
  final DateTime dateTime;

  ParsedSms({
    required this.accountNo,
    required this.isDeposit,
    required this.amountRial,
    required this.balanceRial,
    required this.dateTime,
  });
}

/// پایه‌ی همه‌ی پارسرها؛ هر بانک یک کلاس
abstract class BankSmsParser {
  String get bankName;
  List<String> get nameKeywords; // برای تطبیق با بانک کارت ذخیره‌شده
  ParsedSms? parse(String body);

  bool matchesBank(String name) => nameKeywords.any(name.contains);
}

/// ارقام فارسی/عربی → انگلیسی، و جداکننده‌های هزارگان → ,
String normalizeSmsDigits(String s) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    final i = fa.indexOf(ch);
    final j = ar.indexOf(ch);
    if (i >= 0) {
      sb.write(i);
    } else if (j >= 0) {
      sb.write(j);
    } else if (ch == '٬' || ch == '،') {
      sb.write(',');
    } else {
      sb.write(ch);
    }
  }
  return sb.toString();
}

int _toInt(String s) => int.parse(s.replaceAll(',', ''));

/// پاسارگاد:
/// 777.888.24814772.1
/// -900,000
/// 07/12_19:46
/// مانده: 304,309
class PasargadSmsParser extends BankSmsParser {
  @override
  String get bankName => 'پاسارگاد';

  @override
  List<String> get nameKeywords => ['پاسارگاد', 'pasargad'];

  static final _re = RegExp(
    r'(?<acc>[\d.]+)\s*\n\s*(?<sign>[+-])(?<amt>[\d,]+)\s*\n\s*'
    r'(?<mo>\d{1,2})/(?<d>\d{1,2})_(?<h>\d{1,2}):(?<mi>\d{2})\s*\n\s*'
    r'مانده:\s*(?<bal>[\d,]+)',
  );

  @override
  ParsedSms? parse(String body) {
    final m = _re.firstMatch(normalizeSmsDigits(body));
    if (m == null) return null;
    try {
      final dt = _resolveDate(
        int.parse(m.namedGroup('mo')!),
        int.parse(m.namedGroup('d')!),
        int.parse(m.namedGroup('h')!),
        int.parse(m.namedGroup('mi')!),
      );
      return ParsedSms(
        accountNo: m.namedGroup('acc')!,
        isDeposit: m.namedGroup('sign') == '+',
        amountRial: _toInt(m.namedGroup('amt')!),
        balanceRial: _toInt(m.namedGroup('bal')!),
        dateTime: dt,
      );
    } catch (_) {
      return null; // تاریخ نامعتبر و ...
    }
  }

  /// پیامک سال نداره: سال شمسی فعلی؛ اگه تاریخ آینده شد یعنی سال قبل
  DateTime _resolveDate(int mo, int d, int h, int mi) {
    final now = DateTime.now();
    final nowJ = Jalali.fromDateTime(now);
    DateTime build(int y) {
      final g = Jalali(y, mo, d).toDateTime();
      return DateTime(g.year, g.month, g.day, h, mi);
    }

    var dt = build(nowJ.year);
    if (dt.isAfter(now)) dt = build(nowJ.year - 1);
    return dt;
  }
}

/// رجیستری بانک‌های پشتیبانی‌شده (لیست کارت‌ها دست نخورده می‌مونه)
class SmsParserRegistry {
  static final List<BankSmsParser> _parsers = [
    PasargadSmsParser(),
    // بانک جدید = فقط یک کلاس جدید اینجا
  ];

  static BankSmsParser? forBank(String bankName) {
    for (final p in _parsers) {
      if (p.matchesBank(bankName)) return p;
    }
    return null;
  }

  /// برای روشن/خاموش بودن سوییچ پیامک
  static bool isSupported(String bankName) => forBank(bankName) != null;
}

/// یک پیامک رو پارس می‌کنه و اگه تکراری نبود ثبت می‌کنه.
/// true یعنی تراکنش جدید ثبت شد.
Future<bool> importSmsForBank(String cardBankName, String body) async {
  final parser = SmsParserRegistry.forBank(cardBankName);
  if (parser == null) return false;

  final sms = parser.parse(body);
  if (sms == null) return false;

  final type = sms.isDeposit ? 'income' : 'expense';
  final amount = sms.amountRial.toDouble(); // ریال خام، بدون تقسیم

  // جلوگیری از تکراری: همون نوع + مبلغ + دقیقه
  final dup =
      await (database.select(database.transactions)..where(
            (t) =>
                t.date.equals(sms.dateTime) &
                t.amount.equals(amount) &
                t.type.equals(type),
          ))
          .get();
  if (dup.isNotEmpty) return false;

  // دسته‌ی پیش‌فرض: «سایر» اگه بود، وگرنه اولین دسته‌ی همون نوع
  final cats = await getCategoriesByType(type);
  if (cats.isEmpty) return false;
  final cat = cats.firstWhere(
    (c) => c.name == 'سایر' || c.name == 'سایر درآمدها',
    orElse: () => cats.first,
  );

  await addTransaction(
    amount: amount,
    categoryId: cat.id,
    date: sms.dateTime,
    type: type,
    note: 'پیامک ${parser.bankName}',
  );
  return true;
}
