//todos make the all budget card in main page correct and fix the number in this card
//todos write balance about last month again and make this chart real
//todos make this month card be real with database with milion or hezar currency
//todos make donut chart real with database
import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/extention.dart';
import 'package:finance/Screen/button_page/add_transaction.dart';
import 'package:finance/Screen/button_page/set_budget.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/build_action_button_widget.dart';
import 'package:finance/widget/fl_chart.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:finance/widget/month_card_widget.dart';
import 'package:finance/widget/spending_donut_chart.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class BuildHomePage extends StatefulWidget {
  const BuildHomePage({super.key, required this.size});

  final Size size;

  @override
  State<BuildHomePage> createState() => _BuildHomePageState();
}

class _BuildHomePageState extends State<BuildHomePage> {
  List<SpendingCategory> _spendingCategories = [];
  List<TrendPoint> _trend = [];
  double _balance = 0;
  double _balanceChangePercent = 0;
  bool _balanceUp = true;

  double _income = 0, _expense = 0, _savings = 0;
  int _incomePercent = 0, _expensePercent = 0, _savingsPercent = 0;
  bool _incomeUp = true, _expenseUp = false, _savingsUp = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    transactionsTicker.addListener(_loadAll);
  }

  @override
  void dispose() {
    transactionsTicker.removeListener(_loadAll);
    super.dispose();
  }

  Future<void> _loadAll() async {
    final now = DateTime.now();
    final balance = await getTotalBalance();
    final summary = await getMonthSummary(now);
    final trend = await getBalanceTrend(7); // ۷ روز اخیر
    final spending = await getExpenseByCategory(now);
    final monthStartBalance = await getBalanceBeforeDate(
      DateTime(now.year, now.month, 1),
    );

    if (mounted) {
      setState(() {
        _balance = balance;

        if (monthStartBalance == 0) {
          _balanceChangePercent = 0;
          _balanceUp = true;
        } else {
          final ratio = (balance - monthStartBalance) / monthStartBalance.abs();
          _balanceChangePercent = (ratio.abs() * 100);
          _balanceUp = ratio >= 0;
        }

        _income = summary.income;
        _expense = summary.expense;
        _savings = summary.savings;

        _incomePercent = summary.prevIncome == 0
            ? 0
            : (((summary.income - summary.prevIncome) / summary.prevIncome) *
                      100)
                  .round();
        _incomeUp = summary.income >= summary.prevIncome;

        _expensePercent = summary.prevExpense == 0
            ? 0
            : (((summary.expense - summary.prevExpense) / summary.prevExpense) *
                      100)
                  .round();
        _expenseUp = summary.expense <= summary.prevExpense;

        _savingsPercent = summary.income == 0
            ? 0
            : ((summary.savings / summary.income) * 100).round();
        _savingsUp = summary.savings >= 0;

        _loading = false;

        _trend = trend;
        _spendingCategories = spending;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 20.0,
            ),
            child: Container(
              width: size.width,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3FA8),
                    Color(0xFF1B357F),
                    Color(0xFF17307F),
                    Color(0xFF14286F),
                    Color(0xFF12206B),
                    Color(0xFF0A1548),
                    Color(0xFF080D24),
                  ],
                  stops: [0.1, 0.15, 0.35, 0.6, 0.7, 0.85, 1.0],
                ),
                borderRadius: BorderRadius.circular(24.0),
              ),
              // ← دیگه Stack نیست: یه Column ساده که خودش بر اساس
              // محتوای واقعی‌ش ارتفاع می‌گیره. هیچ عدد فرضی (مثل
              // درصدهای قبلی 0.165 یا 0.22) لازم نیست.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'موجودی کل',
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Constans.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ← مبلغ حالا عرض کامل کارت رو داره (چارت دیگه
                  // کنارش نیست)، پس FittedBox همیشه فضای زیادی برای
                  // جا شدن داره، حتی برای اعداد خیلی بزرگ.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loading ? '...' : formatAmount(_balance.round()),
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 26,
                          child: Image.asset('assets/images/toman_white.png'),
                        ),
                      ],
                    ),
                  ),
                  if (!_loading && _balanceChangePercent > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'نسبت به اول ماه',
                          style: TextStyle(
                            color: _balanceUp
                                ? Constans.success
                                : Constans.expense,
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '%${_balanceChangePercent.round()}'.farsiNumber,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: _balanceUp
                                ? Constans.success
                                : Constans.expense,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          _balanceUp
                              ? Icons.arrow_circle_up
                              : Icons.arrow_circle_down,
                          color: _balanceUp
                              ? Constans.success
                              : Constans.expense,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  // ← چارت دیگه Positioned/overlap نیست؛ یه ردیف جدا
                  // زیر بخش موجودی، با ارتفاع ثابت و عرض کامل.
                  SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: FlChart(points: _trend),
                  ),
                ],
              ),
            ),
          ),

          ///=============================
          ///Action button
          ///=============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BuildActionButton(
                  label: 'تعیین بودجه',
                  color: Constans.purple,
                  icon: Icons.calendar_today_outlined,
                  press: () => Navigator.push(
                    context,
                    PageTransition(
                      child: const SetBudgetScreen(),
                      type: PageTransitionType.fade,
                    ),
                  ),
                ),
                BuildActionButton(
                  label: 'افزودن هزینه',
                  color: Constans.expense,
                  icon: Icons.remove,
                  press: () => Navigator.push(
                    context,
                    PageTransition(
                      child: const AddTransactionScreen(initialTab: 0),
                      type: PageTransitionType.fade,
                    ),
                  ),
                ),
                BuildActionButton(
                  label: 'افزودن درآمد',
                  color: Constans.success,
                  icon: Icons.add,
                  press: () => Navigator.push(
                    context,
                    PageTransition(
                      child: const AddTransactionScreen(initialTab: 1),
                      type: PageTransitionType.fade,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ///=======================================
          /// This month container
          ///=======================================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 10.0,
            ),
            child: Container(
              constraints: BoxConstraints(minHeight: size.height * 0.2),
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Constans.border.withValues(alpha: 0.45),
                  width: 0.85,
                ),
                color: Constans.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      'این ماه',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Constans.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MonthOverviewCard(
                          icon: Icons.trending_up,
                          label: 'درآمد',
                          amount: formatAmount(_income.round()),
                          percent: '%${_incomePercent.abs()}'.farsiNumber,
                          isPositive: _incomeUp,
                          accentColor: Constans.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MonthOverviewCard(
                          icon: Icons.trending_down,
                          label: 'هزینه',
                          amount: formatAmount(_expense.round()),
                          percent: '%${_expensePercent.abs()}'.farsiNumber,
                          isPositive: _expenseUp,
                          accentColor: Constans.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MonthOverviewCard(
                          icon: Icons.savings_outlined,
                          label: 'پس‌انداز',
                          amount: formatAmount(_savings.round()),
                          percent: '%${_savingsPercent.abs()}'.farsiNumber,
                          isPositive: _savingsUp,
                          accentColor: Constans.electricBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          ///============================
          ///Container of chart Home page
          ///============================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Constans.border.withValues(alpha: 0.45),
                  width: 0.85,
                ),
                color: Constans.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      'بررسی هزینه‌ها',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Constans.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _spendingCategories.isEmpty
                      ? SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              'هنوز هزینه‌ای ثبت نشده',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Constans.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      : Builder(
                          builder: (_) {
                            final parts = formatShortAmountParts(_expense);
                            return SpendingOverview(
                              centerValue: _loading ? '...' : parts.value,
                              centerUnit: _loading ? '' : parts.unit,
                              categories: _spendingCategories,
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
