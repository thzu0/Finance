import 'package:finance/Constans/constans.dart';
import 'package:finance/widget/build_action_button_widget.dart';
import 'package:finance/widget/fl_chart.dart';
import 'package:finance/widget/month_card_widget.dart';
import 'package:finance/widget/spending_donut_chart.dart';
import 'package:flutter/material.dart';

class BuildHomePage extends StatelessWidget {
  const BuildHomePage({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
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
              height: size.height * 0.165,
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
                            child: Text(
                              '۲,۴۵۰.۰۰',
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, right: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              'نسبت به ماه قبل',
                              style: TextStyle(
                                color: Constans.success,
                                fontFamily: 'Vazirmatn',
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '%۴۵',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Constans.success,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(width: 3),
                            Icon(
                              Icons.arrow_circle_up,
                              color: Constans.success,
                            ),
                          ],
                        ),
                      ),
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
                  press: () {},
                ),

                BuildActionButton(
                  label: 'افزودن هزینه',
                  color: Constans.expense,
                  icon: Icons.remove,
                  press: () {},
                ),
                BuildActionButton(
                  label: 'افزودن درآمد',
                  color: Constans.success,
                  icon: Icons.add,
                  press: () {},
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
              height: size.height * 0.2,
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
              height: size.height * 0.27,
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
                crossAxisAlignment: CrossAxisAlignment
                    .end, // همون چیزی که تو کارت "این ماه" داشتی
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
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: SpendingOverview(
                            centerAmount: '۷۵۰',
                            categories: const [
                              SpendingCategory(
                                label: 'غذا و رستوران',
                                percent: 37,
                              ),
                              SpendingCategory(label: 'حمل و نقل', percent: 20),
                              SpendingCategory(label: 'خرید', percent: 16),
                              SpendingCategory(label: 'سرگرمی', percent: 12),
                              SpendingCategory(label: 'سایر', percent: 15),
                            ],
                          ),
                        ),
                      ],
                    ),
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
