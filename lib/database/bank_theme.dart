import 'package:flutter/material.dart';

class BankTheme {
  final String name;
  final Color colorStart;
  final Color colorEnd;
  final IconData icon;

  const BankTheme({
    required this.name,
    required this.colorStart,
    required this.colorEnd,
    required this.icon,
  });

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [colorStart, colorEnd],
  );

  /// فقط بانک‌های اصلی و پرکاربرد
  static const List<BankTheme> banks = [
    BankTheme(
      name: 'ملی',
      colorStart: Color(0xFF0D47A1),
      colorEnd: Color(0xFF1976D2),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'ملت',
      colorStart: Color(0xFFB71C1C),
      colorEnd: Color(0xFFE53935),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'صادرات',
      colorStart: Color(0xFF1B5E20),
      colorEnd: Color(0xFF43A047),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'تجارت',
      colorStart: Color(0xFF4A148C),
      colorEnd: Color(0xFF7B1FA2),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'سپه',
      colorStart: Color(0xFF004D40),
      colorEnd: Color(0xFF00897B),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'کشاورزی',
      colorStart: Color(0xFF33691E),
      colorEnd: Color(0xFF689F38),
      icon: Icons.agriculture,
    ),
    BankTheme(
      name: 'مسکن',
      colorStart: Color(0xFFBF360C),
      colorEnd: Color(0xFFF4511E),
      icon: Icons.home_work,
    ),
    BankTheme(
      name: 'رفاه',
      colorStart: Color(0xFF311B92),
      colorEnd: Color(0xFF512DA8),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'سامان',
      colorStart: Color(0xFF01579B),
      colorEnd: Color(0xFF0288D1),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'پارسیان',
      colorStart: Color(0xFFE65100),
      colorEnd: Color(0xFFFB8C00),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'پاسارگاد',
      colorStart: Color(0xFF880E4F),
      colorEnd: Color(0xFFC2185B),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'اقتصاد نوین',
      colorStart: Color(0xFF006064),
      colorEnd: Color(0xFF0097A7),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'سینا',
      colorStart: Color(0xFF3E2723),
      colorEnd: Color(0xFF6D4C41),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'شهر',
      colorStart: Color(0xFF212121),
      colorEnd: Color(0xFF424242),
      icon: Icons.location_city,
    ),
    BankTheme(
      name: 'دی',
      colorStart: Color(0xFF1A237E),
      colorEnd: Color(0xFF3949AB),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'صنعت و معدن',
      colorStart: Color(0xFF37474F),
      colorEnd: Color(0xFF607D8B),
      icon: Icons.factory,
    ),
    BankTheme(
      name: 'کارآفرین',
      colorStart: Color(0xFF0D47A1),
      colorEnd: Color(0xFF42A5F5),
      icon: Icons.business_center,
    ),
    BankTheme(
      name: 'قوامین',
      colorStart: Color(0xFF1B5E20),
      colorEnd: Color(0xFF66BB6A),
      icon: Icons.account_balance,
    ),
    BankTheme(
      name: 'پست بانک',
      colorStart: Color(0xFFF57F17),
      colorEnd: Color(0xFFFBC02D),
      icon: Icons.local_post_office,
    ),
    BankTheme(
      name: 'توسعه صادرات',
      colorStart: Color(0xFF004D40),
      colorEnd: Color(0xFF26A69A),
      icon: Icons.public,
    ),
  ];

  static BankTheme byName(String name) {
    return banks.firstWhere((b) => b.name == name, orElse: () => banks.first);
  }
}
