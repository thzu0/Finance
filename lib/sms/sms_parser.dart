import 'jalali_util.dart';

class ParsedSms {
  final String type;
  final int amountRial;
  final int? balanceRial;
  final String? accountLast4;
  final String? title;
  final DateTime timestamp;

  const ParsedSms({required this.type, required this.amountRial,
    this.balanceRial, this.accountLast4, this.title, required this.timestamp});
}

String normalizeSms(String body) {
  const fa = '۰۱۲۳۴۵۶۷۸۹', ar = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final c in body.split('')) {
    final f = fa.indexOf(c), a = ar.indexOf(c);
    buffer.write(f >= 0 ? f : a >= 0 ? a : c);
  }
  return buffer.toString().replaceAll('ي', 'ی').replaceAll('ك', 'ک')
    .replaceAll('٬', ',')
    .replaceAll(RegExp(r'[\u200C\u200E\u200F\u202A-\u202E\u2066-\u2069]'), '')
    .replaceAll('\r\n', '\n').replaceAll('\r', '\n')
    .replaceAll(RegExp(r'j\.n\.b:[ \t]*', caseSensitive: false), '')
    .replaceAllMapped(RegExp(r'\*(بانک[^*\n]+)\*'), (m) => m[1]!)
    .split('\n').map((l) => l.replaceAll(RegExp(r'[^\S\n]+'), ' ').trim())
    .where((l) => l.isNotEmpty).join('\n');
}

int? _money(String? value) {
  if (value == null || !RegExp(r'^(?:\d+|\d{1,3}(?:,\d{3})+)$').hasMatch(value)) return null;
  return int.tryParse(value.replaceAll(',', ''));
}

final _income = RegExp(r'واریز|نشست');
final _expense = RegExp(r'برداشت|پرید');
final _weakExpense = RegExp(r'خرید|پرداخت|انتقال|کارمزد|قسط');
final _weakIncome = RegExp(r'دریافت|سود|یارانه|حقوق|پایا(?!نه)');
final _label = RegExp(r'(مبلغ|برداشت|واریز|انتقال(?: اینترنت)?|خرید پایانه فروش|پایا(?!نه))[ \t]*:?[ \t]*([+-]?)[ \t]*(\d[\d,]*)');

bool _isOtp(String text) =>
    (text.contains('رمز') && text.contains('اعتبار')) || RegExp(r'رمز[^\n\d]*\d').hasMatch(text);

/// آیا پیامک شبیه تراکنشه (مبلغ + کلمه‌ی کلیدی، بدون رمز یک‌بارمصرف)؟
/// برای نگه‌داشتن پیامک‌هایی که parseBankSms نتونسته بخونه.
bool looksLikeBankTransaction(String body) {
  final text = normalizeSms(body);
  if (_isOtp(text)) return false;
  final t = text.replaceAll(RegExp(r'(?:مانده|موجودی)[^\n]*'), '');
  final hasAmount = RegExp(r'(?<![\d/])(?:\d{1,3}(?:,\d{3})+|\d{4,})(?![\d/])').hasMatch(t);
  return hasAmount && (_income.hasMatch(t) || _expense.hasMatch(t) || _weakExpense.hasMatch(t) || _weakIncome.hasMatch(t));
}

ParsedSms? parseBankSms(String body, {DateTime? receivedAt, DateTime? now}) {
  final text = normalizeSms(body);
  if (_isOtp(text)) return null;
  final transactionText = text.replaceAll(RegExp(r'(?:مانده|موجودی)[^\n]*'), '');
  final signed = RegExp(r'(?:^|[ \t:])([+-])[ \t]*(\d[\d,]*)(?![\d/-])|(?:^|[ \t])(\d[\d,]*)([+-])(?:[ \t]|$)', multiLine: true).firstMatch(transactionText);
  final label = _label.firstMatch(transactionText);
  final currency = RegExp(r'(\d[\d,]*)[ \t]*(?:ریال|تومان)[ \t]*(?:به حساب|از حساب)').firstMatch(transactionText);
  final amount = _money(signed?[2] ?? signed?[3] ?? label?[3] ?? currency?[1]);
  if (amount == null || amount <= 0) return null;
  final sign = signed?[1] ?? signed?[4] ?? (label?[2] == '' ? null : label?[2]);
  final String type;
  if (sign != null) {
    type = sign == '+' ? 'income' : 'expense';
  } else if (_income.hasMatch(transactionText)) {
    type = 'income';
  } else if (_expense.hasMatch(transactionText) || _weakExpense.hasMatch(transactionText)) {
    type = 'expense';
  } else if (_weakIncome.hasMatch(transactionText)) {
    type = 'income';
  } else {
    return null;
  }
  final factor = text.contains('تومان') ? 10 : 1;
  final balance = _money(RegExp(r'(?:مانده|موجودی)[ \t]*:?[ \t]*(\d[\d,]*)').firstMatch(text)?[1]);
  final account = RegExp(r'(?:حساب|برداشت از|واریز(?: سود)? به|کارت)[ \t]*:?[ \t]*\d{2,}(\d{4})(?![\d*])').firstMatch(text)?[1];
  final titles = text.split('\n').where((l) => !RegExp(r'\d|مانده|موجودی|حساب|^بانک|^بلو$').hasMatch(l) &&
    (_income.hasMatch(l) || _expense.hasMatch(l) || _weakExpense.hasMatch(l) || _weakIncome.hasMatch(l))).toList();
  final title = titles.isNotEmpty ? titles.last.replaceAll(RegExp(r'\s*مورخ$'), '') :
    label != null && label[1] != 'مبلغ' ? label[1] : type == 'income' ? 'واریز' : 'برداشت';
  return ParsedSms(type: type, amountRial: amount * factor,
    balanceRial: balance == null ? null : balance * factor,
    accountLast4: account,
    title: title, timestamp: receivedAt ?? _timestamp(text, now ?? DateTime.now()));
}

DateTime _timestamp(String text, DateTime now) {
  final full = RegExp(r'(?<!\d)(1[34]\d{2})[/\.](\d{1,2})[/\.](\d{1,2})(?:[ _-]+(\d{1,2})(?::(\d{2}))?(?::(\d{2}))?)?').firstMatch(text);
  final short = RegExp(r'(?<![\d/])(\d{1,2})/(\d{1,2})[_-](\d{1,2})(?::(\d{2}))?').firstMatch(text);
  final compact = RegExp(r'^(\d{2})(\d{2})-(\d{1,2})(?::(\d{2}))?$', multiLine: true).firstMatch(text);
  if (full != null || short != null || compact != null) {
    final m = full ?? short ?? compact!;
    final offset = full == null ? 0 : 1;
    final year = full == null ? gregorianToJalali(now)[0] : int.parse(m[1]!);
    final month = int.parse(m[1 + offset]!), day = int.parse(m[2 + offset]!);
    final h = int.tryParse(m[3 + offset] ?? '') ?? 0;
    final min = int.tryParse(m[4 + offset] ?? '') ?? 0;
    final sec = full == null ? 0 : int.tryParse(m[6] ?? '') ?? 0;
    if (month >= 1 && month <= 12 && day >= 1 && day <= (month <= 6 ? 31 : 30) && h < 24 && min < 60 && sec < 60) {
      final date = jalaliToGregorian(year, month, day);
      final j = gregorianToJalali(date);
      if (j[0] == year && j[1] == month && j[2] == day) return DateTime(date.year, date.month, date.day, h, min, sec);
    }
    return now;
  }
  final clock = RegExp(r'(?<!\d)(\d{1,2}):(\d{2})(?::(\d{2}))?(?!\d)').firstMatch(text);
  if (clock != null) {
    final h = int.parse(clock[1]!), m = int.parse(clock[2]!), s = int.tryParse(clock[3] ?? '') ?? 0;
    if (h < 24 && m < 60 && s < 60) return DateTime(now.year, now.month, now.day, h, m, s);
  }
  return now;
}
