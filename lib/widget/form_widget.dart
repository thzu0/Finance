import 'package:finance/Constans/constans.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

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

/// انتخاب تاریخ با یه تقویم شمسی کاملاً سفارشی — نه استایل پیش‌فرض
/// پکیج، بلکه هم‌سبک با ظاهر شیشه‌ای بقیه‌ی اپ (GlassBox، رنگ‌های
/// kAccent/kDialogBg، فونت Lalezar، دکمه‌های گرادیانتی).
Future<DateTime?> pickGlassDate(
  BuildContext context,
  DateTime initial, {
  DateTime? first,
  DateTime? last,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _GlassJalaliDatePicker(
      initial: Jalali.fromDateTime(initial),
      first: Jalali.fromDateTime(first ?? DateTime(2020)),
      last: Jalali.fromDateTime(last ?? DateTime(2035)),
    ),
  );
}

/// خودِ ویجت تقویم شمسی. یه هدر با ماه/سال و پیکان‌های جابه‌جایی،
/// یه ردیف نام روزهای هفته، و یه گرید ۷‌ستونه از روزهای همون ماه.
class _GlassJalaliDatePicker extends StatefulWidget {
  final Jalali initial;
  final Jalali first;
  final Jalali last;

  const _GlassJalaliDatePicker({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_GlassJalaliDatePicker> createState() => _GlassJalaliDatePickerState();
}

class _GlassJalaliDatePickerState extends State<_GlassJalaliDatePicker> {
  late Jalali _visibleMonth; // ماهی که گرید فعلاً نشونش میده (day همیشه ۱)
  late Jalali _selected; // روزی که کاربر انتخاب کرده

  static const List<String> _monthNames = [
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

  // ترتیب باید دقیقاً با weekDay کتابخونه‌ی shamsi_date هماهنگ باشه:
  // ۱=شنبه ... ۷=جمعه.
  static const List<String> _weekdayShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _visibleMonth = Jalali(widget.initial.year, widget.initial.month, 1);
  }

  // شماره‌ی ترتیبی ماه (سال×۱۲+ماه) برای مقایسه‌ی راحت با first/last
  int _idx(Jalali j) => j.year * 12 + j.month;

  bool get _canGoNext =>
      _idx(_visibleMonth) <
      _idx(Jalali(widget.last.year, widget.last.month, 1));
  bool get _canGoPrev =>
      _idx(_visibleMonth) >
      _idx(Jalali(widget.first.year, widget.first.month, 1));

  void _shiftMonth(int delta) {
    var y = _visibleMonth.year;
    var m = _visibleMonth.month + delta;
    if (m < 1) {
      m = 12;
      y -= 1;
    } else if (m > 12) {
      m = 1;
      y += 1;
    }
    setState(() => _visibleMonth = Jalali(y, m, 1));
  }

  bool _isSameDay(Jalali a, Jalali b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // چک می‌کنه یه روز داخل بازه‌ی [first, last] هست یا نه
  bool _isSelectable(Jalali j) {
    int comparable(Jalali x) => x.year * 10000 + x.month * 100 + x.day;
    final v = comparable(j);
    return v >= comparable(widget.first) && v <= comparable(widget.last);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _visibleMonth.monthLength;
    final leadingBlanks =
        _visibleMonth.weekDay - 1; // خونه‌های خالی قبل از روز اول

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
        decoration: BoxDecoration(
          color: kDialogBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: kAccent.withValues(alpha: 0.35)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // دستگیره
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // هدر ماه/سال + پیکان‌ها
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _canGoNext ? () => _shiftMonth(1) : null,
                    icon: Icon(
                      Icons.chevron_left,
                      color: _canGoNext ? Colors.white : Colors.white24,
                    ),
                  ),
                  Text(
                    '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year.toString().farsiNumber}',
                    style: const TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 19,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoPrev ? () => _shiftMonth(-1) : null,
                    icon: Icon(
                      Icons.chevron_right,
                      color: _canGoPrev ? Colors.white : Colors.white24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // نام روزهای هفته
              Row(
                children: _weekdayShort
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontFamily: 'Lalezar',
                              fontSize: 13,
                              color: Constans.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 6),

              // گرید روزها
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: leadingBlanks + daysInMonth,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, i) {
                  if (i < leadingBlanks) return const SizedBox.shrink();

                  final day = i - leadingBlanks + 1;
                  final date = Jalali(
                    _visibleMonth.year,
                    _visibleMonth.month,
                    day,
                  );
                  final selected = _isSameDay(date, _selected);
                  final today = _isSameDay(date, Jalali.now());
                  final enabled = _isSelectable(date);

                  return GestureDetector(
                    onTap: enabled
                        ? () => setState(() => _selected = date)
                        : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? kAccent : Colors.transparent,
                        border: (today && !selected)
                            ? Border.all(color: kAccent, width: 1.2)
                            : null,
                      ),
                      child: Text(
                        day.toString().farsiNumber,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: !enabled
                              ? Colors.white24
                              : selected
                              ? Colors.white
                              : Constans.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // دکمه‌های لغو / تایید
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'لغو',
                          style: TextStyle(
                            fontFamily: 'Lalezar',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context, _selected.toDateTime()),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kAccent, kAccent2],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'تایید',
                          style: TextStyle(
                            fontFamily: 'Lalezar',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      final itemWidth = (MediaQuery.of(ctx).size.width - 40 - 36) / 4;
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
