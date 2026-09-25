import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/icon_map.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/Screen/button_page/set_budget.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/budget_repository.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/extentions/extentions.dart';

import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart'; // ← اضافه شد: برای کلاس Jalali

// ==========================================
// مدل بودجه‌ی هر دسته (فقط برای نمایش توی UI؛ دیتای واقعی از BudgetWithSpent میاد)
// ==========================================
class _Budget {
  final Budget raw; // ← اضافه شد: خودِ ردیف بودجه از دیتابیس، برای ویرایش
  final String name;
  final IconData icon;
  final int spent;
  final int limit;

  const _Budget({
    required this.raw, // ← اضافه شد
    required this.name,
    required this.icon,
    required this.spent,
    required this.limit,
  });

  double get ratio => limit == 0 ? 0 : spent / limit;
}

class Budgetsscreen extends StatefulWidget {
  const Budgetsscreen({super.key});

  @override
  State<Budgetsscreen> createState() => _BudgetsscreenState();
}

class _BudgetsscreenState extends State<Budgetsscreen> {
  static const Color _good = Color(0xFF2ED8A3);
  static const Color _warn = Color(0xFFFFB020);
  static const Color _bad = Color(0xFFFF5470);
  static const Color _blue = Color(0xFF4C7DFF);
  static const double _warnThreshold = 0.8;

  // ← تغییر کرد: به‌جای DateTime میلادی، حالا مستقیم یه Jalali نگه
  // می‌داریم. چون budget_repository الان با سال/ماه *شمسی* کار
  // می‌کنه (نه میلادی)، دیگه نیازی به تبدیل رفت‌وبرگشتی نیست و
  // مشکل «۳ مهر زیر شهریور نشون داده میشه» از ریشه حل میشه.
  Jalali _selectedMonth = Jalali.now();

  List<_Budget> _budgets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    // ← وقتی خودِ یه بودجه اضافه/حذف بشه (budgetsTicker) یا وقتی یه
    // تراکنش جدید ثبت/حذف بشه (transactionsTicker)، چون "خرج‌شده"
    // از روی تراکنش‌ها محاسبه میشه، باید هر دو رو گوش بدیم.
    budgetsTicker.addListener(_load);
    transactionsTicker.addListener(_load);
  }

  @override
  void dispose() {
    budgetsTicker.removeListener(_load);
    transactionsTicker.removeListener(_load);
    super.dispose();
  }

  // ← متد جدید: بودجه‌های ماه انتخاب‌شده رو از دیتابیس واقعی می‌خونه
  // و به مدل نمایشی _Budget تبدیل می‌کنه.
  Future<void> _load() async {
    // ← تغییر کرد: چون _selectedMonth الان خودش Jalali‌ه، مستقیم
    // year/month شمسیش رو به getBudgetsForMond پاس می‌دیم (بدون تبدیل).
    final rows = await getBudgetsForMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    final list = rows.map((r) {
      return _Budget(
        raw: r.budget, // ← اضافه شد
        name: r.category.name,
        icon: iconFromName(r.category.icon),
        spent: r.spent.round(),
        limit: r.budget.amount.round(),
      );
    }).toList();

    if (mounted) {
      setState(() {
        _budgets = list;
        _loading = false;
      });
    }
  }

  Color _stateColor(double ratio) {
    if (ratio > 1) return _bad;
    if (ratio >= _warnThreshold) return _warn;
    return _good;
  }

  String _fmt(int n) {
    final s = n.abs().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  String _num(int n) => _fmt(n).farsiNumber;

  // ← تغییر کرد: قبلاً روی DateTime میلادی کار می‌کرد (کامنت قدیمی
  // زیر همین متد بود که پاک نکردیم چون گفتی دست نزنم، ولی منطق
  // واقعی الان روی Jalali اجرا میشه). shamsi_date خودش سرریز سال
  // رو مدیریت نمی‌کنه به‌صورت خودکار مثل DateTime، برای همین خودمون
  // دستی چک می‌کنیم: اگه از ماه ۱۲ (اسفند) به بعد رفتیم یا از ماه
  // ۱ (فروردین) به قبل رفتیم، سال رو دستی عوض می‌کنیم.
  // جابه‌جایی واقعی بین ماه‌های میلادی (کتابخونه‌ی DateTime خودش
  // سرریز سال رو هندل می‌کنه، مثلاً ماه ۱۳ خودش میشه فروردین سال بعد)
  void _shiftMonth(int delta) {
    setState(() {
      final newMonth = _selectedMonth.month + delta;
      if (newMonth < 1) {
        _selectedMonth = Jalali(_selectedMonth.year - 1, 12, 1);
      } else if (newMonth > 12) {
        _selectedMonth = Jalali(_selectedMonth.year + 1, 1, 1);
      } else {
        _selectedMonth = Jalali(_selectedMonth.year, newMonth, 1);
      }
    });
    _load(); // ← ماه که عوض شد، بودجه‌های همون ماه رو دوباره می‌خونیم
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constans.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: GlassBox(
              height: 44,
              width: 44,
              radius: 14,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PageTransition(
                      child: const SetBudgetScreen(),
                      type: PageTransitionType.fade,
                    ),
                  );
                },
                icon: Icon(Icons.add, color: Constans.textPrimary),
              ),
            ),
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(
                  'بودجه',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Constans.textPrimary,
                    fontFamily: 'Lalezar',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AppGlowBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      children: <Widget>[
                        _buildMonthSelector(),
                        const SizedBox(height: 14),
                        _buildSummaryCard(),
                        _buildAlertBanner(),
                        _buildSectionHeader(),
                        if (_budgets.isEmpty) _buildEmptyState(),
                        for (final b in _budgets) _buildCategoryCard(b),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _shiftMonth(1),
            icon: Icon(
              Icons.chevron_left,
              color: Constans.textSecondary,
              size: 28,
            ),
          ),
          Text(
            // ← تغییر کرد: قبلاً اینجا formatJalaliMonth(_selectedMonth)
            // بود که ورودی میلادی می‌گرفت. چون _selectedMonth الان
            // خودش Jalali‌ه، مستقیم از تابع کمکی جدید _jalaliMonthLabel
            // (پایین همین کلاس) استفاده می‌کنیم.
            _jalaliMonthLabel(_selectedMonth),
            style: TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 20,
              color: Constans.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: Icon(
              Icons.chevron_right,
              color: Constans.textSecondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ← اضافه شد: اسم ماه‌های شمسی، برای نمایش توی _buildMonthSelector.
  // چون formatJalaliMonth (توی form_widget.dart) ورودی میلادی می‌خواست
  // و الان دیگه میلادی نداریم، این نسخه‌ی مخصوص Jalali رو اضافه کردیم.
  static const List<String> _jalaliMonthNames = [
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

  // ← اضافه شد: مثلاً «مهر ۱۴۰۵»
  String _jalaliMonthLabel(Jalali j) {
    return '${_jalaliMonthNames[j.month - 1]} ${j.year.toString().farsiNumber}';
  }

  // ← وضعیت خالی: وقتی هنوز هیچ بودجه‌ای برای این ماه ثبت نشده
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Text(
        'برای این ماه هنوز بودجه‌ای ثبت نکردی',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Lalezar',
          fontSize: 15,
          color: Constans.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalLimit = _budgets.fold<int>(0, (s, b) => s + b.limit);
    final totalSpent = _budgets.fold<int>(0, (s, b) => s + b.spent);
    final remaining = totalLimit - totalSpent;
    final ratio = totalLimit == 0 ? 0.0 : totalSpent / totalLimit;
    final percent = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassBox(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'خرج‌شده از کل بودجه',
                  style: TextStyle(
                    fontFamily: 'Lalezar',
                    fontSize: 15,
                    color: Constans.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percent%'.farsiNumber,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Constans.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProgressBar(value: ratio, color: _blue, height: 10),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stat('بودجه', _num(totalLimit), Constans.textPrimary),
                _stat('خرج‌شده', _num(totalSpent), Constans.textPrimary),
                _stat(
                  'باقی‌مونده',
                  _num(remaining),
                  remaining >= 0 ? _good : _bad,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Lalezar',
            fontSize: 13,
            color: Constans.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertBanner() {
    final over = _budgets.where((b) => b.ratio > 1).toList();
    if (over.isEmpty) return const SizedBox.shrink();

    final text = over.length == 1
        ? 'بودجه‌ی «${over.first.name}» ${_num(over.first.spent - over.first.limit)} تومان رد شده'
        : '${over.length.toString().farsiNumber} دسته از سقف بودجه رد شده';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _bad.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _bad.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: _bad, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 14,
                  color: _bad,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Text(
            'دسته‌ها',
            style: const TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 18,
              color: Color(0xFF7FB2FF),
            ),
          ),
          const Spacer(),
          Text(
            'مبالغ به تومان',
            style: TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 13,
              color: Constans.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_Budget b) {
    final color = _stateColor(b.ratio);
    final percent = (b.ratio * 100).round();
    final isOver = b.ratio > 1;
    final diff = (b.spent - b.limit).abs();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: () {
          // ← تغییر کرد: قبلاً فقط یه TODO بود، الان واقعاً به صفحه‌ی
          // SetBudgetScreen با دیتای همین بودجه (b.raw) میره. چون
          // updateBudget/deleteBudget خودشون budgetsTicker رو صدا
          // می‌زنن، این صفحه خودکار بعد از برگشت رفرش میشه.
          Navigator.push(
            context,
            PageTransition(
              child: SetBudgetScreen(existingBudget: b.raw),
              type: PageTransitionType.fade,
            ),
          );
        },
        child: GlassBox(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(b.icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: TextStyle(
                            fontFamily: 'Lalezar',
                            fontSize: 18,
                            color: Constans.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_num(b.spent)} از ${_num(b.limit)}',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            color: Constans.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$percent%'.farsiNumber,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProgressBar(value: b.ratio, color: color, height: 8),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  isOver
                      ? '${_num(diff)} بیشتر از سقف'
                      : '${_num(diff)} باقی‌مونده',
                  style: TextStyle(
                    fontFamily: 'Lalezar',
                    fontSize: 13,
                    color: isOver ? _bad : Constans.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const _ProgressBar({
    required this.value,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final target = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        width: double.infinity,
        color: Colors.white.withValues(alpha: 0.12),
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: target),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            return FractionallySizedBox(
              widthFactor: v,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
