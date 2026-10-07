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

/// قرض‌الحسنه مهر ایران:
/// ‪300463586351‬
/// 1,900,000-
/// 1405/7/14-16:18
/// مانده:30,724,805
///
/// نکته: علامت (+/-) بعد از مبلغ میاد، نه قبلش. و تاریخ سال کامل داره.
class QmIranSmsParser extends BankSmsParser {
  @override
  String get bankName => 'مهر ایران';

  @override
  List<String> get nameKeywords => [
    'مهر ایران',
    'QMEHRIRAN',
    'qmehriran',
    'mehriran',
  ];

  // علامت‌های کنترلی جهت‌دهی متن (LTR/RTL embedding, marks و...)
  static const _lrm = r'[\s\u200e\u200f\u202a\u202b\u202c]*';

  static final _re = RegExp(
    r'(?<acc>\d+)'
    '$_lrm'
    r'\s*\n\s*'
    r'(?<amt>[\d,]+)(?<sign>[+-])\s*\n\s*'
    r'(?<y>\d{4})/(?<mo>\d{1,2})/(?<d>\d{1,2})'
    r'-(?<h>\d{1,2}):(?<mi>\d{2})\s*\n\s*'
    r'مانده[:\s]*(?<bal>[\d,]+)',
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

/// ─────────────────────────────────────────────────────────────
/// بانک شهر
/// ─────────────────────────────────────────────────────────────
///
/// **فرمت اصلی** (پرداخت قسط، واریز گروهی، انتقال وجه کارتی، خرید با کارت):
/// ```
/// *بانک شهر*
/// پرداخت قسط
/// برداشت از:700794605751
/// مبلغ:63,740,000ريال
/// موجودی:605,840,156 ریال
/// 1405/07/5 13:03:18
/// ```
///
/// نکته‌ها:
/// - «خريد» و «کارتي» با ي عربی نوشته می‌شن
/// - فرمت تاریخ: `YYYY/MM/D  HH:MM:SS` (روز ممکنه 1 یا 2 رقمی)
/// - پیام‌های «انتقال به ... رمز ...» پارس نمی‌شن (تراکنش نیستن، فقط OTP)
class ShahrSmsParser extends BankSmsParser {
  @override
  String get bankName => 'شهر';

  @override
  List<String> get nameKeywords => [
    'شهر',
    'shahr',
    'Shahr',
    'SHAHR',
    'ShahrBank',
    'shahrbank',
  ];

  static const _mark = r'[\u200e\u200f\u202a\u202b\u202c]*';

  /// الگوی اصلی — همه فرمت‌ها به جز OTP
  static final _re = RegExp(
    r'\*?بانک\s*شهر\*?\s*\n\s*'
            r'(?<type>[^\n]+)\n\s*'
            r'(?:برداشت\s*از|واریز\s*به)\s*:\s*' +
        _mark +
        r'(?<acc>\d+)[^\n]*\n\s*'
            r'مبلغ\s*:\s*' +
        _mark +
        r'(?<amt>[\d,]+)\s*ریال[^\n]*\n\s*'
            r'موجودی\s*:\s*' +
        _mark +
        r'(?<bal>[\d,]+)\s*ریال[^\n]*\n\s*'
            r'(?<y>\d{4})/(?<mo>\d{1,2})/(?<d>\d{1,2})\s+'
            r'(?<h>\d{1,2}):(?<mi>\d{2}):(?<s>\d{2})',
  );

  @override
  ParsedSms? parse(String body) {
    // یکسان‌سازی ارقام + حروف عربی
    final text = normalizeSmsDigits(
      body,
    ).replaceAll('ي', 'ی').replaceAll('ك', 'ک');

    final m = _re.firstMatch(text);
    if (m == null) return null;

    try {
      final type = m.namedGroup('type')!.trim();

      // تشخیص درآمد / هزینه از روی نوع خط دوم:
      //  - واریز → درآمد
      //  - پرداخت قسط / انتقال وجه کارتی / خرید با کارت → هزینه
      final isDeposit = type.contains('واریز');

      final dt = _jalaliFull(
        int.parse(m.namedGroup('y')!),
        int.parse(m.namedGroup('mo')!),
        int.parse(m.namedGroup('d')!),
        int.parse(m.namedGroup('h')!),
        int.parse(m.namedGroup('mi')!),
      );

      return ParsedSms(
        accountNo: m.namedGroup('acc')!,
        isDeposit: isDeposit,
        amountRial: _toInt(m.namedGroup('amt')!),
        balanceRial: _toInt(m.namedGroup('bal')!),
        dateTime: dt,
      );
    } catch (_) {
      return null;
    }
  }
}

/// ─────────────────────────────────────────────────────────────
/// بانک سپه — سه فرمت متفاوت داره:
/// ─────────────────────────────────────────────────────────────
///
/// **فرمت A: برداشت / خرید پایانه فروش**
/// ```
/// برداشت:50,025,000
/// حساب :‪16300500096657‬
/// مانده:240,484,870
/// 6/24-18:02
/// ```
/// انواع: برداشت، خريد پايانه فروش، دريافت اتوماتيک قسط
///
/// **فرمت B: واریز سود** (سال کامل + ساعت)
/// ```
/// واريز سود به: 16300500096657
/// مبلغ: 205,543ريال
/// زمان: 1405/7/9-2:31
/// مانده: 286,066,333ريال
/// ```
///
/// **فرمت C: پرداخت گروهی / واریز گروهی** (بدون ساعت)
/// ```
/// پرداخت گروهي
/// حساب:‪1056301495509‬
/// مبلغ:12,000,000
/// مانده:16,247,345
/// زمان:1405/6/30
/// ```
///
/// **پیام‌های انتقال با رمز (OTP)** پارس نمی‌شن چون:
/// - مانده ندارن
/// - تاریخ تراکنش ندارن (فقط «اعتبار رمز»)
class SepahSmsParser extends BankSmsParser {
  @override
  String get bankName => 'سپه';

  @override
  List<String> get nameKeywords => [
    'سپه',
    'sepah',
    'SEPAH',
    'SEPAHBANK',
    'sphbank',
    'ebank.sphbank',
  ];

  // علامت‌های کنترلی جهت‌دهی متن (بدون \s)
  static const _mark = r'[\u200e\u200f\u202a\u202b\u202c]*';

  // ──────── الگوی A: <type>:<amount> + حساب + مانده + تاریخ بدون سال ────────
  static final _reA = RegExp(
    r'(?<type>[^\n:]+):\s*(?<amt>[\d,]+)[^\n]*\n\s*'
            r'حساب\s*:\s*' +
        _mark +
        r'(?<acc>\d+)[^\n]*\n\s*'
            r'مانده\s*:\s*' +
        _mark +
        r'(?<bal>[\d,]+)[^\n]*\n\s*'
            r'(?<mo>\d{1,2})/(?<d>\d{1,2})-(?<h>\d{1,2}):(?<mi>\d{2})',
  );

  // ──────── الگوی B: واریز سود به + مبلغ + زمان (سال کامل) + مانده ────────
  static final _reB = RegExp(
    r'واریز سود به\s*:\s*' +
        _mark +
        r'(?<acc>\d+)[^\n]*\n\s*'
            r'مبلغ\s*:\s*' +
        _mark +
        r'(?<amt>[\d,]+)[^\n]*\n\s*'
            r'زمان\s*:\s*' +
        _mark +
        r'(?<y>\d{4})/(?<mo>\d{1,2})/(?<d>\d{1,2})-(?<h>\d{1,2}):(?<mi>\d{2})[^\n]*\n\s*'
            r'مانده\s*:\s*' +
        _mark +
        r'(?<bal>[\d,]+)',
  );

  // ──────── الگوی C: پرداخت/واریز گروهی + حساب + مبلغ + مانده + زمان (بدون ساعت) ────────
  static final _reC = RegExp(
    r'(?<type>(?:پرداخت|واریز)\s+گروهی)[^\n]*\n\s*'
            r'حساب\s*:\s*' +
        _mark +
        r'(?<acc>\d+)[^\n]*\n\s*'
            r'مبلغ\s*:\s*' +
        _mark +
        r'(?<amt>[\d,]+)[^\n]*\n\s*'
            r'مانده\s*:\s*' +
        _mark +
        r'(?<bal>[\d,]+)[^\n]*\n\s*'
            r'زمان\s*:\s*' +
        _mark +
        r'(?<y>\d{4})/(?<mo>\d{1,2})/(?<d>\d{1,2})',
  );

  @override
  ParsedSms? parse(String body) {
    // یکسان‌سازی: ارقام + ی/ک عربی
    final text = normalizeSmsDigits(
      body,
    ).replaceAll('ي', 'ی').replaceAll('ك', 'ک');

    return _tryB(text) ?? _tryC(text) ?? _tryA(text, body);
  }

  // ──────────── الگوی B: واریز سود ────────────
  ParsedSms? _tryB(String text) {
    final m = _reB.firstMatch(text);
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
        accountNo: m.namedGroup('acc')!,
        isDeposit: true, // واریز سود = درآمد
        amountRial: _toInt(m.namedGroup('amt')!),
        balanceRial: _toInt(m.namedGroup('bal')!),
        dateTime: dt,
      );
    } catch (_) {
      return null;
    }
  }

  // ──────────── الگوی C: پرداخت / واریز گروهی ────────────
  ParsedSms? _tryC(String text) {
    final m = _reC.firstMatch(text);
    if (m == null) return null;
    try {
      final type = m.namedGroup('type')!;

      // تشخیص درآمد/هزینه:
      //  - "واریز گروهی" → درآمد
      //  - "پرداخت گروهی" → معمولاً هزینه،
      //    ولی اگه متن حاوی «یارانه» باشه (یارانه‌ی政府) درآمده
      bool isDeposit = type.contains('واریز');
      if (!isDeposit && type.contains('پرداخت') && (text.contains('یارانه'))) {
        isDeposit = true;
      }

      // این الگو ساعت نداره → 00:00
      final dt = _jalaliFull(
        int.parse(m.namedGroup('y')!),
        int.parse(m.namedGroup('mo')!),
        int.parse(m.namedGroup('d')!),
        0,
        0,
      );
      return ParsedSms(
        accountNo: m.namedGroup('acc')!,
        isDeposit: isDeposit,
        amountRial: _toInt(m.namedGroup('amt')!),
        balanceRial: _toInt(m.namedGroup('bal')!),
        dateTime: dt,
      );
    } catch (_) {
      return null;
    }
  }

  // ──────────── الگوی A: برداشت / خرید / دریافت قسط ────────────
  ParsedSms? _tryA(String text, String originalBody) {
    final m = _reA.firstMatch(text);
    if (m == null) return null;
    try {
      final type = m.namedGroup('type')!.trim();

      // جهت تراکنش از روی نوع خط دوم:
      //  - برداشت / خرید پایانه فروش → هزینه
      //  - دریافت (به‌ندرت اینجا میاد) → درآمد
      //  - واریز → درآمد
      final isDeposit = type.contains('واریز') || type.contains('دریافت');

      final dt = _jalaliNoYear(
        int.parse(m.namedGroup('mo')!),
        int.parse(m.namedGroup('d')!),
        int.parse(m.namedGroup('h')!),
        int.parse(m.namedGroup('mi')!),
      );
      return ParsedSms(
        accountNo: m.namedGroup('acc')!,
        isDeposit: isDeposit,
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
    QmIranSmsParser(),
    MaskanSmsParser(),
    BluSmsParser(),
    SepahSmsParser(),
    ShahrSmsParser(),
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
