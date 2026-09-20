import 'package:finance/Constans/constans.dart';
import 'package:finance/Screen/BudgetScreen.dart';
import 'package:finance/Screen/InsightsScreen.dart';
import 'package:finance/Screen/ProfileScreen.dart';
import 'package:finance/Screen/TransactionsScreen.dart';
import 'package:finance/Screen/home_screen.dart';
import 'package:finance/widget/custom_bottm_nav_widget.dart';
import 'package:flutter/material.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int bottomIndex = 0;

  List<Widget> screen() {
    return [
      HomeScreen(),
      Transactionsscreen(),
      BudgetScreen(),
      Insightsscreen(),
      Profilescreen(),
    ];
  }

  List<String> appBarTitle = const [
    'خانه',
    'تراکنش ها',
    'بودجه',
    'تحلیل',
    'پروفایل',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constans.background,
      extendBody: true,
      body: IndexedStack(index: bottomIndex, children: screen()),
      bottomNavigationBar: CustomBottomNav(
        onTap: (index) => setState(() {
          bottomIndex = index;
        }),
      ),
    );
  }
}
