//todos make the all budget card in main page correct and fix the number in this card
//todos write balance about last month again and make this chart real
//todos make this month card be real with database with milion or hezar currency
//todos make donut chart real with database
import 'package:finance/Constans/constans.dart';
import 'package:finance/Screen/button_page/add_transaction.dart';
import 'package:finance/Screen/button_page/set_budget.dart';
import 'package:finance/database/database_provider.dart'; // ← اضافه شد
import 'package:finance/database/transaction_repository.dart'; // ← اضافه شد
import 'package:finance/widget/build_action_button_widget.dart';
import 'package:finance/widget/fl_chart.dart';
import 'package:finance/widget/form_widget.dart'; // ← اضافه شد (برای formatAmount)
import 'package:finance/widget/month_card_widget.dart';
import 'package:finance/widget/spending_donut_chart.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

// ← تغییر کرد: از StatelessWidget به StatefulWidget، چون باید async
// از دیتابیس بخونیم و به تغییرات گوش بدیم.
class BuildHomePage extends StatefulWidget {
  const BuildHomePage({super.key, required this.size});

  final Size size;

  @override
  State<BuildHomePage> createState() => _BuildHomePageState();
}

class _BuildHomePageState extends State<BuildHomePage> {
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    // هر وقت تراکنشی (دستی یا بعداً از SMS) اضافه/حذف بشه، موجودی
    // خودکار دوباره محاسبه میشه.
    transactionsTicker.addListener(_loadBalance);
  }

  @override
  void dispose() {
    transactionsTicker.removeListener(_loadBalance);
    super.dispose();
  }

  Future<void> _loadBalance() async {
    final b = await getTotalBalance();
    if (mounted) {
      setState(() {
        _balance = b;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size =
        widget.size; // ← تغییر کرد: قبلاً پارامتر مستقیم بود، الان widget.size

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
              constraints: BoxConstraints(minHeight: size.height * 0.165),
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
              child: Stack(
                children: [
                  Positioned(
                    left: 5,
                    bottom: 8,
                    right: size.width * 0.45,
                    child: const FlChart(),
                  ),
                  Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 15, right: 5),
                            child: Icon(
                              Icons.remove_red_eye_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.only(top: 15, right: 15),
                            child: Text(
                              'موجودی کل',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                color: Constans.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          SizedBox(
                            height: 30.0,
                            child: Image.asset('assets/images/toman_white.png'),
                          ),
                          const SizedBox(width: 5),
                          Padding(
                            padding: const EdgeInsets.only(top: 10, right: 15),
                            // ← اضافه شد: عرض مبلغ محدود میشه تا هیچوقت وارد محدوده‌ی
                            // چارت (که سمت چپ، تا size.width * 0.45 پیش میاد) نشه.
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: size.width * 0.5,
                              ),
                              // ← اضافه شد: اگه عدد جا نشد، به‌جای سرریز کردن، خودش
                              // کوچیک‌تر میشه (فونت رو خودکار کوچیک می‌کنه).
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _loading
                                      ? '...'
                                      : formatAmount(_balance.round()),
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ← حذف شد: ردیف «نسبت به ماه قبل / ٪۴۵» چون
                      // عدد ثابت و بی‌ربط به دیتای واقعی بود. اگه
                      // بعداً خواستی این مقایسه رو هم واقعی کنیم
                      // (مثلاً نسبت به ماه قبل)، بگو یه تابع جدا
                      // براش می‌نویسیم.
                    ],
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
                      // ← تغییر کرد: initialTab: 0 اضافه شد (هزینه)
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
                      // ← تغییر کرد: initialTab: 1 اضافه شد (درآمد)
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
                          amount: '۳,۲۰۰',
                          percent: '%۱۲',
                          isPositive: true,
                          accentColor: Constans.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MonthOverviewCard(
                          icon: Icons.trending_down,
                          label: 'هزینه',
                          amount: '۷۵۰',
                          percent: '%۶',
                          isPositive: false,
                          accentColor: Constans.expense,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MonthOverviewCard(
                          icon: Icons.savings_outlined,
                          label: 'پس‌انداز',
                          amount: '۱,۴۵۰',
                          percent: '%۱۸',
                          isPositive: true,
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
                  SpendingOverview(
                    centerAmount: '۷۵۰',
                    categories: const [
                      SpendingCategory(label: 'غذا و رستوران', percent: 37),
                      SpendingCategory(label: 'حمل و نقل', percent: 20),
                      SpendingCategory(label: 'خرید', percent: 16),
                      SpendingCategory(label: 'سرگرمی', percent: 12),
                      SpendingCategory(label: 'سایر', percent: 15),
                    ],
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
