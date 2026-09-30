import 'dart:math' as math;

import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/insights_repository.dart' as repo;
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/currency_mark.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:finance/widget/spending_donut_chart.dart';
import 'package:flutter/material.dart';

enum _Period { week, month, year }

class _PeriodData {
  final String tabLabel;
  final String compareLabel;
  final List<String> labels;
  final List<String> fullLabels;
  final List<int> values;
  final int previousTotal;
  final List<SpendingCategory> categories;

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

  double get change =>
      previousTotal == 0 ? 0 : (total - previousTotal) / previousTotal;

  int get changePercent => (change.abs() * 100).round();

  int get peakIndex {
    if (values.isEmpty) return 0;
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }
}

// برچسب‌های ثابت: (برچسب کوتاه، برچسب کامل، عنوان تب، عنوان مقایسه)
const Map<_Period, (List<String>, List<String>, String, String)> _labels = {
  _Period.week: (
    ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
    ['شنبه', 'یکشنبه', 'دوشنبه', 'سه‌شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه'],
    'هفته',
    'هفته‌ی قبل',
  ),
  _Period.month: (
    ['هفته ۱', 'هفته ۲', 'هفته ۳', 'هفته ۴'],
    ['هفته‌ی اول', 'هفته‌ی دوم', 'هفته‌ی سوم', 'هفته‌ی چهارم'],
    'ماه',
    'ماه قبل',
  ),
  _Period.year: (
    [
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
    [
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
    'سال',
    'سال قبل',
  ),
};

class Insightsscreen extends StatefulWidget {
  const Insightsscreen({super.key});

  @override
  State<Insightsscreen> createState() => _InsightsscreenState();
}

class _InsightsscreenState extends State<Insightsscreen> {
  static const Color _blue = Color(0xFF4C7DFF);
  static const Color _purple = Color(0xFF7C5CFF);
  static const Color _income = Color(0xFF2ED8A3);
  static const Color _expense = Color(0xFFFF5470);
  static const Color _sectionTitle = Color(0xFF7FB2FF);
  static const Color _orange = Color(0xFFF97316);

  static const double _barAreaHeight = 130;

  final _s = AppSettings.instance;

  _Period _period = _Period.week;

  bool _loading = true;
  _PeriodData? _current;

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _load();
    transactionsTicker.addListener(_load);
    _s.changes.addListener(_onSettings);
  }

  @override
  void dispose() {
    transactionsTicker.removeListener(_load);
    _s.changes.removeListener(_onSettings);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final repo.InsightsResult result;
    switch (_period) {
      case _Period.week:
        result = await repo.getWeekInsights(DateTime.now());
      case _Period.month:
        result = await repo.getMonthInsights(DateTime.now());
      case _Period.year:
        result = await repo.getYearInsights(DateTime.now());
    }

    final (labels, fullLabels, tabLabel, compareLabel) = _labels[_period]!;

    if (mounted) {
      setState(() {
        _current = _PeriodData(
          tabLabel: tabLabel,
          compareLabel: compareLabel,
          labels: labels,
          fullLabels: fullLabels,
          values: result.values.map((v) => v.round()).toList(),
          previousTotal: result.previousTotal.round(),
          categories: result.categories
              .map((c) => SpendingCategory(label: c.label, percent: c.percent))
              .toList(),
        );
        _loading = false;
      });
    }
  }

  /// ۹۰۰ هزار / ۱٫۵ میلیون (با رعایت ریال و مخفی‌سازی)
  String _compact(int v) {
    if (amountsHidden) return '•••';
    final x = toDisplayAmount(v);
    if (x >= 1000000) {
      final m = x / 1000000;
      final s = m == m.roundToDouble()
          ? m.round().toString()
          : m.toStringAsFixed(1).replaceAll('.', '٫');
      return '${s.farsiNumber} میلیون';
    }
    return '${(x ~/ 1000).toString().farsiNumber} هزار';
  }

  /// همون _compact ولی با واحد؛ موقع مخفی‌سازی فقط •••
  String _compactWithUnit(int v) =>
      amountsHidden ? '•••' : '${_compact(v)} $currencyName';

  @override
  Widget build(BuildContext context) {
    final d = _current;

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
          child: _loading || d == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      children: <Widget>[
                        _buildTabBar(),
                        const SizedBox(height: 25),
                        _card(_buildSummary(d)),
                        _sectionHeader('خرج ${d.tabLabel}'),
                        _card(_buildBarChart(d)),
                        _sectionHeader('دسته‌های پرخرج'),
                        d.categories.isEmpty
                            ? _card(
                                Text(
                                  'هنوز خرجی توی این بازه ثبت نشده',
                                  style: glassText(
                                    15,
                                    color: Constans.textSecondary,
                                  ),
                                ),
                              )
                            : _card(_buildCategories(d)),
                        _sectionHeader('پیشنهاد هوشمند'),
                        _card(_buildSuggestion(d)),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: double.infinity,
        child: GlassBox(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

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
                  onTap: () {
                    setState(() => _period = p);
                    _load();
                  },
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
                      _labels[p]!.$3,
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
                    showAmount(d.total),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 22,
                      color: Constans.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  CurrencyMark(color: 'white', height: 28),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(_PeriodData d) {
    if (d.values.isEmpty || d.values.every((v) => v == 0)) {
      return Text(
        'داده‌ای برای نمایش نیست',
        style: TextStyle(
          fontFamily: 'Lalezar',
          fontSize: 15,
          color: Constans.textSecondary,
        ),
      );
    }

    final maxV = d.values.reduce(math.max);
    final peak = d.peakIndex;
    final many = d.values.length > 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'بیشترین: ${d.fullLabels[peak]} · ${_compactWithUnit(d.values[peak])}',
          style: TextStyle(
            fontFamily: 'Lalezar',
            fontSize: 15,
            color: Constans.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
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

  Widget _buildCategories(_PeriodData d) {
    final (amountText, unitLabel) = centerAmountParts(d.total);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: SpendingLegend(categories: d.categories)),
          const SizedBox(width: 24),
          SpendingDonutChart(
            categories: d.categories,
            centerValue: amountText,
            centerUnit: unitLabel,
            size: 160,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestion(_PeriodData d) {
    if (d.values.isEmpty || d.values.every((v) => v == 0)) {
      return Text(
        'هنوز چیزی برای تحلیل نداریم — چند تا خرج ثبت کن تا اینجا پیشنهاد بدم.',
        style: TextStyle(
          fontFamily: 'Lalezar',
          fontSize: 16,
          height: 1.7,
          color: Constans.textPrimary,
        ),
      );
    }

    final peak = d.peakIndex;
    final text =
        'بیشترین خرجت ${d.fullLabels[peak]} بوده '
        '(${_compactWithUnit(d.values[peak])}). '
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
