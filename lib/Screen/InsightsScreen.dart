import 'dart:math' as math;

import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:finance/widget/spending_donut_chart.dart';
import 'package:flutter/material.dart';
// TODO: مسیر فایل چارتت (SpendingDonutChart / SpendingLegend / SpendingCategory) رو اینجا بذار و از کامنت دربیار
// import 'package:finance/widget/chart.dart';

enum _Period { week, month, year }

class _PeriodData {
  final String tabLabel;
  final String compareLabel; // «هفته‌ی قبل»
  final List<String> labels; // زیر میله‌ها
  final List<String> fullLabels; // برای متن‌ها
  final List<int> values;
  final int previousTotal;
  final List<SpendingCategory> categories; // برای دونات

  const _PeriodData({
    required this.tabLabel,
    required this.compareLabel,
    required this.labels,
    required this.fullLabels,
    required this.values,
    required this.previousTotal,
    required this.categories,
  });

  int get total => values.fold(0, (a, b) => a + b);
  double get change => (total - previousTotal) / previousTotal;
  int get changePercent => (change.abs() * 100).round();
  int get peakIndex {
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }
}

// داده‌ی نمونه، بعداً با داده‌ی واقعی عوضش کن
const Map<_Period, _PeriodData> _data = {
  _Period.week: _PeriodData(
    tabLabel: 'هفته',
    compareLabel: 'هفته‌ی قبل',
    labels: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    fullLabels: [
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
    ],
    values: [420000, 310000, 580000, 250000, 690000, 900000, 360000],
    previousTotal: 3990000,
    categories: [
      SpendingCategory(label: 'خوراک', percent: 32),
      SpendingCategory(label: 'حمل و نقل', percent: 24),
      SpendingCategory(label: 'خرید', percent: 20),
      SpendingCategory(label: 'سرگرمی', percent: 14),
      SpendingCategory(label: 'سلامت', percent: 10),
    ],
  ),
  _Period.month: _PeriodData(
    tabLabel: 'ماه',
    compareLabel: 'ماه قبل',
    labels: ['هفته ۱', 'هفته ۲', 'هفته ۳', 'هفته ۴'],
    fullLabels: ['هفته‌ی اول', 'هفته‌ی دوم', 'هفته‌ی سوم', 'هفته‌ی چهارم'],
    values: [3200000, 2800000, 4100000, 3500000],
    previousTotal: 12400000,
    categories: [
      SpendingCategory(label: 'خرید', percent: 30),
      SpendingCategory(label: 'خوراک', percent: 28),
      SpendingCategory(label: 'حمل و نقل', percent: 18),
      SpendingCategory(label: 'سلامت', percent: 14),
      SpendingCategory(label: 'سرگرمی', percent: 10),
    ],
  ),
  _Period.year: _PeriodData(
    tabLabel: 'سال',
    compareLabel: 'سال قبل',
    labels: [
      'فر',
      'ارد',
      'خرد',
      'تیر',
      'مرد',
      'شهر',
      'مهر',
      'آبا',
      'آذر',
      'دی',
      'بهم',
      'اسف',
    ],
    fullLabels: [
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
    ],
    values: [
      11200000,
      9800000,
      12500000,
      10400000,
      13100000,
      12000000,
      14200000,
      11700000,
      10900000,
      12800000,
      13400000,
      15000000,
    ],
    previousTotal: 152000000,
    categories: [
      SpendingCategory(label: 'خرید', percent: 34),
      SpendingCategory(label: 'خوراک', percent: 26),
      SpendingCategory(label: 'سلامت', percent: 16),
      SpendingCategory(label: 'حمل و نقل', percent: 14),
      SpendingCategory(label: 'سرگرمی', percent: 10),
    ],
  ),
};

class Insightsscreen extends StatefulWidget {
  const Insightsscreen({super.key});

  @override
  State<Insightsscreen> createState() => _InsightsscreenState();
}

class _InsightsscreenState extends State<Insightsscreen> {
  // همون رنگ‌های صفحه‌ی تراکنش‌ها
  static const Color _blue = Color(0xFF4C7DFF);
  static const Color _purple = Color(0xFF7C5CFF);
  static const Color _income = Color(0xFF2ED8A3);
  static const Color _expense = Color(0xFFFF5470);
  static const Color _sectionTitle = Color(0xFF7FB2FF);
  static const Color _orange = Color(0xFFF97316);

  static const double _barAreaHeight = 130;

  _Period _period = _Period.week;

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// ۹۰۰ هزار / ۱٫۵ میلیون
  String _compact(int v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      final s = m == m.roundToDouble()
          ? m.round().toString()
          : m.toStringAsFixed(1).replaceAll('.', '٫');
      return '${s.farsiNumber} میلیون';
    }
    return '${(v ~/ 1000).toString().farsiNumber} هزار';
  }

  @override
  Widget build(BuildContext context) {
    final d = _data[_period]!;

    return Scaffold(
      backgroundColor: Constans.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Text(
                  'تحلیل خرج ها',
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
                  // اگه تب‌ها رفت زیر تیتر، این خط رو از کامنت دربیار:
                  // const SizedBox(height: 80),
                  _buildTabBar(),
                  const SizedBox(height: 25),
                  _card(_buildSummary(d)),
                  _sectionHeader('خرج ${d.tabLabel}'),
                  _card(_buildBarChart(d)),
                  _sectionHeader('دسته‌های پرخرج'),
                  _card(_buildCategories(d)),
                  _sectionHeader('پیشنهاد هوشمند'),
                  _card(_buildSuggestion(d)),
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

  // ───────────── کارت شیشه‌ای تمام‌عرض ─────────────
  Widget _card(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: double.infinity,
        child: GlassBox(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  // ───────────── تیتر هر بخش (مثل «امروز» تو تراکنش‌ها) ─────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          textDirection: TextDirection.rtl,
          style: const TextStyle(
            fontFamily: 'Lalezar',
            fontSize: 25,
            color: _sectionTitle,
          ),
        ),
      ),
    );
  }

  // ───────────── تب‌بار شیشه‌ای هفته/ماه/سال ─────────────
  Widget _buildTabBar() {
    final periods = _Period.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassBox(
        height: 52,
        padding: const EdgeInsets.all(4),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: List.generate(periods.length, (i) {
              final p = periods[i];
              final selected = _period == p;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _period = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: selected
                          ? const LinearGradient(colors: [_blue, _purple])
                          : null,
                    ),
                    child: Text(
                      _data[p]!.tabLabel,
                      style: TextStyle(
                        fontFamily: 'Lalezar',
                        fontSize: 17,
                        color: selected ? Colors.white : Constans.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ───────────── کارت خلاصه ─────────────
  Widget _buildSummary(_PeriodData d) {
    final down = d.change <= 0;
    final color = down ? _income : _expense;
    final headline = down
        ? '${d.changePercent.toString().farsiNumber}٪ کمتر خرج کردی'
        : '${d.changePercent.toString().farsiNumber}٪ بیشتر خرج کردی';

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            down ? Icons.trending_down_rounded : Icons.trending_up_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 21,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'نسبت به ${d.compareLabel}',
                style: TextStyle(
                  fontFamily: 'Lalezar',
                  fontSize: 14,
                  color: Constans.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(d.total).farsiNumber,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 22,
                      color: Constans.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/toman_white.png',
                        width: 25,
                        height: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────── نمودار میله‌ای ─────────────
  Widget _buildBarChart(_PeriodData d) {
    final maxV = d.values.reduce(math.max);
    final peak = d.peakIndex;
    final many = d.values.length > 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بیشترین: ${d.fullLabels[peak]} · ${_compact(d.values[peak])} تومان',
          style: TextStyle(
            fontFamily: 'Lalezar',
            fontSize: 15,
            color: Constans.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // key باعث می‌شه با عوض شدن تب، انیمیشن دوباره از صفر شروع بشه
        TweenAnimationBuilder<double>(
          key: ValueKey(_period),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < d.values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: many ? 3 : 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: _barAreaHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: math.max(
                                  4,
                                  _barAreaHeight * d.values[i] / maxV * t,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: i == peak
                                      ? null
                                      : _blue.withValues(alpha: 0.28),
                                  gradient: i == peak
                                      ? const LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [_blue, _purple],
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              fontFamily: 'Lalezar',
                              fontSize: many ? 11 : 14,
                              color: i == peak
                                  ? Constans.textPrimary
                                  : Constans.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ───────────── دسته‌های پرخرج (دونات خودت) ─────────────
  /// جمع خرج به میلیون برای وسط دونات: ۳٫۵ / ۱۳٫۶ / ۱۴۷
  String _millions(int total) {
    final m = total / 1000000;
    final s = (m - m.roundToDouble()).abs() < 0.05 || m >= 100
        ? m.round().toString()
        : m.toStringAsFixed(1);
    return s.replaceAll('.', '٫').farsiNumber;
  }

  Widget _buildCategories(_PeriodData d) {
    // صفحه راست‌به‌چپه، ولی چیدمان چارتت رو همون‌طور که خودت طراحی کردی
    // نگه می‌داریم: لیست سمت چپ، دونات سمت راست.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: SpendingLegend(categories: d.categories)),
          const SizedBox(width: 24),
          SpendingDonutChart(
            categories: d.categories,
            centerAmount: _millions(d.total),
            centerLabel: 'میلیون',
            size: 160,
          ),
        ],
      ),
    );
  }

  // ───────────── پیشنهاد هوشمند ─────────────
  Widget _buildSuggestion(_PeriodData d) {
    final peak = d.peakIndex;
    final text =
        'بیشترین خرجت ${d.fullLabels[peak]} بوده '
        '(${_compact(d.values[peak])} تومان). '
        'دفعه‌ی بعد قبل از خرج‌های بزرگ، ۲۴ ساعت صبر کن؛ '
        'خیلی وقت‌ها دیگه لازم نمی‌شه.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lightbulb_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Lalezar',
              fontSize: 16,
              height: 1.7,
              color: Constans.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
