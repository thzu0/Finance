import 'package:finance/Constans/constans.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// ارقام فارسی / انگلیسی
// ==========================================
const List<String> _faDigits = [
  '۰',
  '۱',
  '۲',
  '۳',
  '۴',
  '۵',
  '۶',
  '۷',
  '۸',
  '۹',
];

String toPersianDigits(String s) =>
    s.replaceAllMapped(RegExp(r'[0-9]'), (m) => _faDigits[int.parse(m[0]!)]);

String toLatinDigits(String s) => s.replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (m) {
  final c = m[0]!.codeUnitAt(0);
  return (c >= 0x06F0 ? c - 0x06F0 : c - 0x0660).toString();
});

/// «۱۲,۵۰۰,۰۰۰» → 12500000
int parseAmount(String s) =>
    int.tryParse(toLatinDigits(s).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// 12500000 → «۱۲,۵۰۰,۰۰۰»
String formatAmount(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return toPersianDigits(b.toString());
}

/// موقع تایپ، عدد رو فارسی و سه‌رقم‌سه‌رقم جدا می‌کنه
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = toLatinDigits(
      newValue.text,
    ).replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    final n = int.tryParse(digits) ?? 0;
    final text = formatAmount(n);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ==========================================
// تاریخ شمسی (تبدیل از میلادی، بدون پکیج)
// ==========================================
const List<String> _jalaliMonths = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

List<int> gregorianToJalali(int gy, int gm, int gd) {
  const gdm = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  final gy2 = gm > 2 ? gy + 1 : gy;
  int days =
      355666 +
      (365 * gy) +
      ((gy2 + 3) ~/ 4) -
      ((gy2 + 99) ~/ 100) +
      ((gy2 + 399) ~/ 400) +
      gd +
      gdm[gm - 1];
  int jy = -1595 + (33 * (days ~/ 12053));
  days %= 12053;
  jy += 4 * (days ~/ 1461);
  days %= 1461;
  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }
  final int jm;
  final int jd;
  if (days < 186) {
    jm = 1 + days ~/ 31;
    jd = 1 + days % 31;
  } else {
    jm = 7 + (days - 186) ~/ 30;
    jd = 1 + (days - 186) % 30;
  }
  return [jy, jm, jd];
}

/// مثلا «۳۰ شهریور ۱۴۰۵»
String formatJalali(DateTime d) {
  final j = gregorianToJalali(d.year, d.month, d.day);
  return '${toPersianDigits(j[2].toString())} ${_jalaliMonths[j[1] - 1]} ${toPersianDigits(j[0].toString())}';
}

/// انتخاب تاریخ (تقویم خود فلاتر میلادیه، ولی تاریخ انتخاب‌شده شمسی نشون داده می‌شه)
Future<DateTime?> pickGlassDate(
  BuildContext context,
  DateTime initial, {
  DateTime? first,
  DateTime? last,
}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first ?? DateTime(2020),
    lastDate: last ?? DateTime(2035),
    builder: (ctx, child) => Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: kAccent,
          surface: kDialogBg,
        ),
      ),
      child: child!,
    ),
  );
}

// ==========================================
// گزینه‌ها (دسته‌ها و حساب‌ها) + باتم‌شیت انتخاب
// ==========================================
class GlassOption {
  final IconData icon;
  final String label;
  const GlassOption(this.icon, this.label);
}

const List<GlassOption> kExpenseCategories = [
  GlassOption(Icons.restaurant, 'خورد و خوراک'),
  GlassOption(Icons.directions_car, 'حمل و نقل'),
  GlassOption(Icons.shopping_bag, 'خرید'),
  GlassOption(Icons.movie, 'سرگرمی'),
  GlassOption(Icons.health_and_safety, 'سلامت'),
  GlassOption(Icons.receipt_long, 'قبض‌ها'),
  GlassOption(Icons.school, 'آموزش'),
  GlassOption(Icons.more_horiz, 'سایر'),
];

const List<GlassOption> kIncomeCategories = [
  GlassOption(Icons.account_balance_wallet, 'حقوق'),
  GlassOption(Icons.laptop_mac, 'فریلنس'),
  GlassOption(Icons.card_giftcard, 'هدیه'),
  GlassOption(Icons.trending_up, 'سرمایه‌گذاری'),
  GlassOption(Icons.more_horiz, 'سایر'),
];

const List<GlassOption> kAccounts = [
  GlassOption(Icons.account_balance_wallet_outlined, 'کیف پول اصلی'),
  GlassOption(Icons.account_balance_outlined, 'حساب بانکی'),
  GlassOption(Icons.savings_outlined, 'پس‌انداز'),
];

/// ایندکس گزینه‌ی انتخاب‌شده رو برمی‌گردونه (یا null اگه بسته بشه)
Future<int?> showGlassOptionSheet(
  BuildContext context, {
  required String title,
  required List<GlassOption> options,
  int? selected,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      // عرض هر آیتم: سه‌تا تو هر ردیف
      final itemWidth = (MediaQuery.of(ctx).size.width - 40 - 24) / 3;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            color: kDialogBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: kAccent.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title, style: glassText(20)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (int i = 0; i < options.length; i++)
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx, i),
                        child: Container(
                          width: itemWidth,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected == i
                                ? kAccent.withValues(alpha: 0.22)
                                : Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected == i
                                  ? kAccent
                                  : kAccent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                options[i].icon,
                                color: selected == i
                                    ? Colors.white
                                    : kSectionBlue,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                options[i].label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: glassText(14),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ==========================================
// فیلد مبلغ بزرگ
// ==========================================
class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Color color;

  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Text(label, style: glassText(14, color: Constans.textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsFormatter()],
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: '۰',
                    hintStyle: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'تومان',
                style: glassText(18, color: Constans.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// دکمه‌ی ذخیره‌ی گرادیانتی
// ==========================================
class GlassSaveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> colors;

  const GlassSaveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.colors = const [kAccent, kAccent2],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: colors),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            child: Text(text, style: glassText(20, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// فقط ماه و سال رو به شمسی نشون میده (بدون روز)، مثلاً «شهریور ۱۴۰۵».
/// برای نمایش «ماه انتخاب‌شده» توی صفحه‌ی بودجه استفاده میشه؛
/// چون خودِ تاریخ داخلی همچنان میلادیه (day=1)، فقط نمایشش شمسیه.
String formatJalaliMonth(DateTime d) {
  final j = gregorianToJalali(d.year, d.month, 1);
  return '${_jalaliMonths[j[1] - 1]} ${toPersianDigits(j[0].toString())}';
}
