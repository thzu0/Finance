import 'package:drift/drift.dart';

import 'package:finance/database/app_setting.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

// ═══════════════════════════════════════════════════════════════
// مدل نتیجه
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
// کلاس پایه
// ═══════════════════════════════════════════════════════════════

abstract class BankSmsParser {
  String get bankName;
  List<String> get nameKeywords; // برای تطبیق با بانک کارت ذخیره‌شده
  ParsedSms? parse(String body);

  bool matchesBank(String name) => nameKeywords.any(name.contains);
}

// ═══════════════════════════════════════════════════════════════
// ابزارهای مشترک
// ═══════════════════════════════════════════════════════════════

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

/// تاریخ شمسی بدون سال: سال جاری شمسی؛ اگه تاریخ آینده شد یعنی سال قبل
DateTime _jalaliNoYear(int mo, int d, int h, int mi) {
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

/// تاریخ شمسی با سال کامل (۴ رقمی)
DateTime _jalaliFull(int y, int mo, int d, int h, int mi) {
  final g = Jalali(y, mo, d).toDateTime();
  return DateTime(g.year, g.month, g.day, h, mi);
}

// ═══════════════════════════════════════════════════════════════
// پارسرهای بانک‌ها
// ═══════════════════════════════════════════════════════════════

/// فرمت مشترک پاسارگاد و رسالت:
///
/// 10.14299754.1
/// +40,000,000
/// 06/01_17:53
/// مانده: 66,160,630
///
/// فقط اسم بانک و sender ID فرق می‌کنه.
abstract class _SignAccountBalanceParser extends BankSmsParser {
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
      final dt = _jalaliNoYear(
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
      return null;
    }
  }
}

class PasargadSmsParser extends _SignAccountBalanceParser {
  @override
  String get bankName => 'پاسارگاد';

  @override
  List<String> get nameKeywords => ['پاسارگاد', 'pasargad'];
}

class ResalatSmsParser extends _SignAccountBalanceParser {
  @override
  String get bankName => 'رسالت';

  @override
  List<String> get nameKeywords => ['رسالت', 'resalat'];
}

/// مسکن:
/// انتقال:‎-10,000,000‎
/// حساب:710178492595
/// مانده:44,756,624
/// 0504-20:38
class MaskanSmsParser extends BankSmsParser {
  @override
  String get bankName => 'مسکن';

  @override
  List<String> get nameKeywords => ['مسکن', 'maskan', 'BankMaskan'];

  // علامت‌های کنترلی چپ‌به‌راست/راست‌به‌چپ که توی پیامک مسکن هستن
  static const _lrm = r'[\s\u200e\u200f]*';

  static final _re = RegExp(
    r'(?<type>[^\n:]+):'
    '$_lrm'
    r'(?<sign>[+-])(?<amt>[\d,]+)\s*\n\s*'
    r'حساب:'
    '$_lrm'
    r'(?<acc>\d+)\s*\n\s*'
    r'مانده:'
    '$_lrm'
    r'(?<bal>[\d,]+)\s*\n\s*'
    r'(?<mo>\d{2})(?<d>\d{2})-(?<h>\d{2}):(?<mi>\d{2})',
  );

  @override
  ParsedSms? parse(String body) {
    final m = _re.firstMatch(normalizeSmsDigits(body));
    if (m == null) return null;
    try {
      final dt = _jalaliNoYear(
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
      return null;
    }
  }
}

/// بلو:
/// بلو
/// برداشت پول
/// سمیه عزیز، 13,000,000ریال از حساب شما پرید.
/// موجودی: 31,041,102 ریال
/// ۱۵:۲۰
/// ۱۴۰۵.۰۷.۱۳
///
/// نکته: خط دوم گاهی «پوزش بابت اختلال» هم می‌شه، پس تشخیص جهت
/// از روی فعل «پرید» (خروج) و «نشست» (ورود) انجام می‌شه.
class BluSmsParser extends BankSmsParser {
  @override
  String get bankName => 'بلو';

  @override
  List<String> get nameKeywords => ['بلو', 'blu'];

  static final _re = RegExp(
    r'(?<amt>\d[\d,]*)\s*ریال[^\n]*?(?<verb>پرید|نشست)'
    r'[\s\S]*?موجودی[:\s]*(?<bal>\d[\d,]*)\s*ریال'
    r'[\s\S]*?(?<h>\d{1,2}):(?<mi>\d{2})'
    r'[\s\S]*?(?<y>\d{4})\.(?<mo>\d{1,2})\.(?<d>\d{1,2})',
  );

  @override
  ParsedSms? parse(String body) {
    final m = _re.firstMatch(normalizeSmsDigits(body));
    if (m == null) return null;
    try {
      final dt = _jalaliFull(
        int.parse(m.namedGroup('y')!),
        int.parse(m.namedGroup('mo')!),
        int.parse(m.namedGroup('d')!),
        int.parse(m.namedGroup('h')!),
        int.parse(m.namedGroup('mi')!),
      );
      return ParsedSms(
        accountNo: '',
        isDeposit: m.namedGroup('verb') == 'نشست',
        amountRial: _toInt(m.namedGroup('amt')!),
        balanceRial: _toInt(m.namedGroup('bal')!),
        dateTime: dt,
      );
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// رجیستری
// ═══════════════════════════════════════════════════════════════

/// رجیستری بانک‌های پشتیبانی‌شده
class SmsParserRegistry {
  static final List<BankSmsParser> _parsers = [
    PasargadSmsParser(),
    ResalatSmsParser(),
    MaskanSmsParser(),
    BluSmsParser(),
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

// ═══════════════════════════════════════════════════════════════
// ورود پیامک به دیتابیس
// ═══════════════════════════════════════════════════════════════

/// یک پیامک رو پارس می‌کنه و اگه تکراری نبود ثبت می‌کنه.
/// true یعنی تراکنش جدید ثبت شد.
Future<bool> importSmsForBank(String cardBankName, String body) async {
  final parser = SmsParserRegistry.forBank(cardBankName);
  if (parser == null) return false;

  final sms = parser.parse(body);
  if (sms == null) return false;

  // لنگر موجودی
  final st = AppSettings.instance;
  final ts = sms.dateTime.millisecondsSinceEpoch;
  if (ts >= st.get<int>('sms_bal_ts', 0)) {
    await st.set('sms_bal_ts', ts);
    await st.set('sms_bal_rial', sms.balanceRial);
  }

  final type = sms.isDeposit ? 'income' : 'expense';
  final amount = sms.amountRial.toDouble();

  // جلوگیری از تکراری
  final dup =
      await (database.select(database.transactions)..where(
            (t) =>
                t.date.equals(sms.dateTime) &
                t.amount.equals(amount) &
                t.type.equals(type),
          ))
          .get();
  if (dup.isNotEmpty) return false;

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
