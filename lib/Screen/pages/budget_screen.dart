import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/Screen/button_page/set_budget.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

// ==========================================
// مدل بودجه‌ی هر دسته
// ==========================================
class _Budget {
  final String name;
  final IconData icon;
  final int spent;
  final int limit;

  const _Budget({
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
  // رنگ‌های وضعیت
  static const Color _good = Color(0xFF2ED8A3); // زیر ۸۰٪
  static const Color _warn = Color(0xFFFFB020); // بین ۸۰٪ تا ۱۰۰٪
  static const Color _bad = Color(0xFFFF5470); // بالای ۱۰۰٪
  static const Color _blue = Color(0xFF4C7DFF);

  // آستانه‌ی هشدار (۰.۸ یعنی ۸۰٪)
  static const double _warnThreshold = 0.8;

  static const List<String> _months = [
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

  int _month = 5; // شهریور
  int _year = 1405;

  // داده‌ی نمونه، بعداً با داده‌ی واقعی (و به تفکیک ماه) عوضش کن
  final List<_Budget> _budgets = const [
    _Budget(
      name: 'خورد و خوراک',
      icon: Icons.restaurant,
      spent: 4200000,
      limit: 5000000,
    ),
    _Budget(
      name: 'خرید',
      icon: Icons.shopping_bag,
      spent: 3900000,
      limit: 3500000,
    ),
    _Budget(
      name: 'حمل و نقل',
      icon: Icons.directions_car,
      spent: 1800000,
      limit: 3000000,
    ),
    _Budget(name: 'سرگرمی', icon: Icons.movie, spent: 900000, limit: 2000000),
    _Budget(
      name: 'سلامت',
      icon: Icons.health_and_safety,
      spent: 600000,
      limit: 1500000,
    ),
  ];

  // ───────────── ابزارها ─────────────
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

  void _shiftMonth(int delta) {
    setState(() {
      _month += delta;
      if (_month < 0) {
        _month = 11;
        _year--;
      } else if (_month > 11) {
        _month = 0;
        _year++;
      }
    });
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
        // دکمه‌ی افزودن بودجه (شیشه‌ای)
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
          child: SingleChildScrollView(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  // اگه محتوا رفت زیر تیتر، این خط رو از کامنت دربیار:
                  // const SizedBox(height: 80),
                  _buildMonthSelector(),
                  const SizedBox(height: 14),
                  _buildSummaryCard(),
                  _buildAlertBanner(),
                  _buildSectionHeader(),
                  for (final b in _budgets) _buildCategoryCard(b),
                  // فاصله برای اینکه زیر بتم‌نویگیشن نره
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── انتخاب‌گر ماه ─────────────
  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ماه قبل (تو RTL سمت راسته)
          IconButton(
            onPressed: () => _shiftMonth(-1),
            icon: Icon(
              Icons.chevron_right,
              color: Constans.textSecondary,
              size: 28,
            ),
          ),
          Text(
            '${_months[_month]} $_year'.farsiNumber,
            style: TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 20,
              color: Constans.textPrimary,
            ),
          ),
          // ماه بعد
          IconButton(
            onPressed: () => _shiftMonth(1),
            icon: Icon(
              Icons.chevron_left,
              color: Constans.textSecondary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── کارت خلاصه ─────────────
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

  // ───────────── نوار هشدار ─────────────
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

  // ───────────── عنوان بخش دسته‌ها ─────────────
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

  // ───────────── کارت هر دسته ─────────────
  Widget _buildCategoryCard(_Budget b) {
    final color = _stateColor(b.ratio);
    final percent = (b.ratio * 100).round();
    final isOver = b.ratio > 1;
    final diff = (b.spent - b.limit).abs();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: () {
          // TODO: ویرایش بودجه‌ی این دسته
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

// ==========================================
// نوار پیشرفت (با انیمیشن پر شدن)
// ==========================================
class _ProgressBar extends StatelessWidget {
  final double value; // ۰ تا ۱ (بیشتر از ۱ بریده می‌شه)
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
