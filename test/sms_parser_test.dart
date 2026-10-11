import 'package:finance/sms/sms_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const _skip = Object();
final _now = DateTime(2026, 10, 11, 12, 0);

String _sms(List<String> lines) => lines.join('\n');

void _expectParsed(
  List<String> lines, {
  required String type,
  required int amount,
  required int? balance,
  Object? last4 = _skip,
  Object? title = _skip,
}) {
  final r = parseBankSms(_sms(lines), now: _now);
  expect(r, isNotNull);
  expect(r!.type, type);
  expect(r.amountRial, amount);
  expect(r.balanceRial, balance);
  if (!identical(last4, _skip)) expect(r.accountLast4, last4);
  if (!identical(title, _skip)) expect(r.title, title);
}

void main() {
  group('مسکن', () {
    test('مسکن ۱', () {
      _expectParsed(
        ['انتقال:\u200E-50,000,000\u200E', 'حساب:710000000001', 'مانده:757,074', '0710-14'],
        type: 'expense', amount: 50000000, balance: 757074, last4: '0001',
      );
    });

    test('مسکن ۲', () {
      _expectParsed(
        ['پایا:\u200E+50,620,960\u200E', 'حساب:710000000001', 'مانده:50,757,074', '0710-14'],
        type: 'income', amount: 50620960, balance: 50757074, last4: '0001',
      );
    });

    test('مسکن ۳', () {
      _expectParsed(
        ['انتقال اینترنت:\u200E+10,000\u200E', 'حساب:710000000001', 'مانده:742,074', '0715-23'],
        type: 'income', amount: 10000, balance: 742074, last4: '0001',
      );
    });

    test('مسکن ۴، مانده ناقص', () {
      _expectParsed(
        ['-21,000', '07/15_23:08', 'مانده: 293,'],
        type: 'expense', amount: 21000, balance: null,
      );
    });

    test('مسکن ۵، مانده ناقص', () {
      _expectParsed(
        ['+5,000,000', '07/16_13:37', 'مانده: 5,293,'],
        type: 'income', amount: 5000000, balance: null,
      );
    });

    test('مسکن ۶، رمز یک\u200Cبارمصرف رد می\u200Cشود', () {
      final r = parseBankSms(
        _sms(['بانک مسکن', 'انتقال به 621986*0000', 'مبلغ : 50000000', 'رمز : 250000']),
        now: _now,
      );
      expect(r, isNull);
    });
  });

  group('بلو', () {
    test('بلو ۱', () {
      _expectParsed(
        ['بلو', 'واریز پول', 'کاربر عزیز، 20,000,000ریال به حساب شما نشست.', 'موجودی: 21,848,715 ریال', '۱۱:۰۹', '۱۴۰۵.'],
        type: 'income', amount: 20000000, balance: 21848715,
      );
    });

    test('بلو ۲', () {
      _expectParsed(
        ['بلو', 'برداشت پول', 'کاربر عزیز، 4,900,000 ریال از حساب شما پرید.', 'موجودی: 2,806,715 ریال', '۱۳:۲۳', '۱۴۰۵.'],
        type: 'expense', amount: 4900000, balance: 2806715,
      );
    });

    test('بلو ۳', () {
      _expectParsed(
        ['بلو', 'واریز پول', 'کاربر عزیز، 3,000,000ریال به حساب شما نشست.', 'موجودی: 5,806,715 ریال', '۱۸:۱۶', '۱۴۰۵.'],
        type: 'income', amount: 3000000, balance: 5806715,
      );
    });

    test('بلو ۴', () {
      _expectParsed(
        ['بلو', 'برداشت پول', 'کاربر عزیز، 850,000ریال از حساب شما پرید.', 'موجودی: 4,956,715 ریال', '۱۸:۳۴', '۱۴۰۵.'],
        type: 'expense', amount: 850000, balance: 4956715,
      );
    });
  });

  group('شهر', () {
    test('شهر ۱', () {
      _expectParsed(
        ['j.n.b: *بانک شهر*', 'پرداخت قسط', 'برداشت از:700000000002', 'مبلغ:63,740,000ريال', 'موجودي:605,840,156 ريال', '1405/07/5 13:03:18'],
        type: 'expense', amount: 63740000, balance: 605840156, last4: '0002', title: 'پرداخت قسط',
      );
    });

    test('شهر ۲', () {
      _expectParsed(
        ['j.n.b: *بانک شهر*', 'واريز گروهي', 'واريز به :4001000000003', 'مبلغ:60,000,000ريال', 'موجودي:60,588,334 ريال', '1405/07/7 14:37:19'],
        type: 'income', amount: 60000000, balance: 60588334, last4: '0003',
      );
    });

    test('شهر ۳، رمز رد می\u200Cشود', () {
      final r = parseBankSms(
        _sms([
          'j.n.b: *بانک شهر*',
          'انتقال به \u202A621986*0001\u202C',
          'مبلغ: 40,000,000 ريال',
          'رمز: 000396',
          'زمان اعتبار رمز: 20:15:11',
          'تاريخ: 1405/07/10 20:13:11',
        ]),
        now: _now,
      );
      expect(r, isNull);
    });

    test('شهر ۴', () {
      _expectParsed(
        ['j.n.b: *بانک شهر*', 'انتقال وجه کارتي', 'برداشت از:700000000002', 'مبلغ:40,021,500ريال', 'موجودي:471,798,656 ريال', '1405/07/10 20:13:19'],
        type: 'expense', amount: 40021500, balance: 471798656, last4: '0002',
      );
    });

    test('شهر ۵', () {
      _expectParsed(
        ['j.n.b: *بانک شهر*', 'خريد با کارت', 'برداشت از:4001000000003', 'مبلغ:1,700,000ريال', 'موجودي:51,059,134 ريال', '1405/07/13 16:58:00'],
        type: 'expense', amount: 1700000, balance: 51059134, last4: '0003',
      );
    });

    test('شهر ۶', () {
      _expectParsed(
        ['j.n.b: *بانک شهر*', 'خريد با کارت', 'برداشت از:4001000000003', 'مبلغ:5,876,000ريال', 'موجودي:39,885,134 ريال', '1405/07/15 16:10:02'],
        type: 'expense', amount: 5876000, balance: 39885134, last4: '0003',
      );
    });
  });

  group('سپه', () {
    test('سپه ۱، تاریخ بدون سال', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'برداشت:50,025,000', 'حساب :\u202A16300000000004\u202C', 'مانده:240,484,870', '6/24-18:02'],
        type: 'expense', amount: 50025000, balance: 240484870, last4: '0004',
      );
    });

    test('سپه ۲، با خط توضیح', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'برداشت:48,826,000', 'حساب :\u202A16300000000004\u202C', 'مانده:186,508,870', '6/25-5:43', 'دريافت اتوماتيک  قسط مورخ'],
        type: 'expense', amount: 48826000, balance: 186508870, last4: '0004', title: 'دریافت اتوماتیک قسط',
      );
    });

    test('سپه ۳، مبلغ بدون برچسب', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'خريد پايانه فروش: 4,500,000', 'حساب :\u202A16300000000004\u202C', 'مانده:175,888,870', '6/25-12:25'],
        type: 'expense', amount: 4500000, balance: 175888870, last4: '0004', title: 'خرید پایانه فروش',
      );
    });

    test('سپه ۴، رمز رد می\u200Cشود', () {
      final r = parseBankSms(
        _sms([
          'j.n.b: بانک سپه',
          '\u202A610433*0000\u202C انتقال',
          'مبلغ 100,000,000 ريال',
          'رمز: 120867',
          'ZwFQsa9kcO+',
          '@ebank.sphbank.ir #120867',
          'اعتبار 17:19:19',
        ]),
        now: _now,
      );
      expect(r, isNull);
    });

    test('سپه ۵، «پرداخت» ولی درآمد', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'پرداخت گروهي', 'حساب:\u202A1056300000005\u202C', 'مبلغ:12,000,000', 'مانده:16,247,345', 'زمان:1405/6/30', ' واريز گروهي يارانه'],
        type: 'income', amount: 12000000, balance: 16247345, title: 'واریز گروهی یارانه',
      );
    });

    test('سپه ۶، واریز سود', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'واريز سود به: 16300000000004', 'مبلغ: 205,543ريال', 'زمان: 1405/7/9-2:31', 'مانده: 286,066,333ريال'],
        type: 'income', amount: 205543, balance: 286066333, last4: '0004',
      );
    });

    test('سپه ۷، کارمزد', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'برداشت:600,000', 'حساب :\u202A2224800000006\u202C', 'مانده:2,580,811', '7/11-15:43', 'برداشت کارمزد سرويس پيامک'],
        type: 'expense', amount: 600000, balance: 2580811, last4: '0006', title: 'برداشت کارمزد سرویس پیامک',
      );
    });

    test('سپه ۸، خراب و ناقص', () {
      _expectParsed(
        ['j.n.b: بانک سپه', 'برداشت:140,000,000', 'حساب :\u202A16300000000004\u202C', 'مانده:145,614,333', '7/15-10:56', 'دستورپرداخت صادره پل کدپيگيري 140507150153132754166'],
        type: 'expense', amount: 140000000, balance: 145614333,
      );
    });
  });

  group('timestamp', () {
    test('سپه ۱، بدون سال ← سال جاری شمسی', () {
      final r = parseBankSms(
        _sms(['j.n.b: بانک سپه', 'برداشت:50,025,000', 'حساب :\u202A16300000000004\u202C', 'مانده:240,484,870', '6/24-18:02']),
        now: DateTime(2027, 10, 11, 12, 0),
      );
      expect(r, isNotNull);
      expect(r!.timestamp, DateTime(2027, 9, 15, 18, 2));
    });

    test('مسکن ۱، ساعت بدون دقیقه ← دقیقه ۰', () {
      final r = parseBankSms(
        _sms(['انتقال:\u200E-50,000,000\u200E', 'حساب:710000000001', 'مانده:757,074', '0710-14']),
        now: _now,
      );
      expect(r, isNotNull);
      expect(r!.timestamp, DateTime(2026, 10, 2, 14, 0));
    });

    test('receivedAt بر زمان داخل متن اولویت دارد', () {
      final receivedAt = DateTime(2026, 10, 1, 9, 30, 15);
      final r = parseBankSms(
        _sms(['j.n.b: *بانک شهر*', 'پرداخت قسط', 'برداشت از:700000000002', 'مبلغ:63,740,000ريال', 'موجودي:605,840,156 ريال', '1405/07/5 13:03:18']),
        receivedAt: receivedAt,
        now: _now,
      );
      expect(r, isNotNull);
      expect(r!.timestamp, receivedAt);
    });

    test('بدون هیچ زمانی ← now', () {
      final r = parseBankSms(_sms(['-21,000', 'مانده: 293,']), now: _now);
      expect(r, isNotNull);
      expect(r!.timestamp, _now);
    });
  });

  group('ورودی خراب', () {
    test('رشته\u200Cی خالی', () {
      expect(parseBankSms('', now: _now), isNull);
    });

    test('فقط فاصله و خط جدید', () {
      expect(parseBankSms('  \n\r\n\t ', now: _now), isNull);
    });

    test('متن بی\u200Cربط', () {
      expect(parseBankSms('سلام، امروز هوا خیلی خوب است', now: _now), isNull);
    });

    test('فقط عدد', () {
      expect(parseBankSms('123456', now: _now), isNull);
    });

    test('فقط کاراکترهای نامرئی', () {
      expect(parseBankSms('\u200E\u200F\u202A\u202C\u200C', now: _now), isNull);
    });
  });

  group('looksLikeBankTransaction', () {
    test('مبلغ + کلمه‌ی کلیدی', () {
      expect(looksLikeBankTransaction('پرداخت 1,200,000 ریال انجام شد'), isTrue);
    });
    test('رمز یک‌بارمصرف', () {
      expect(looksLikeBankTransaction('انتقال به 621986*0001 مبلغ: 40,000,000 ريال رمز: 000396'), isFalse);
    });
    test('عدد بدون کلمه‌ی کلیدی', () {
      expect(looksLikeBankTransaction('کد تخفیف شما 123456'), isFalse);
    });
    test('فقط مانده', () {
      expect(looksLikeBankTransaction('پرداخت\nمانده: 5,293,000'), isFalse);
    });
    test('فقط تاریخ', () {
      expect(looksLikeBankTransaction('پرداخت قسط در تاریخ 1405/07/05'), isFalse);
    });
    test('رشته‌ی خالی', () {
      expect(looksLikeBankTransaction(''), isFalse);
    });
  });
}
