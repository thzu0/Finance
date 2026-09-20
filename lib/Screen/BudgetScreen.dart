//todos make the icons button for filter this month or any month that user selected and you should add float or action button in app bar for add the budgets

import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

enum TxType { income, expense }

class _Tx {
  final String title;
  final String category;
  final int amount;
  final String time;
  final IconData icon;
  final Color color;
  final TxType type;
  final bool isToday;

  const _Tx({
    required this.title,
    required this.category,
    required this.amount,
    required this.time,
    required this.icon,
    required this.color,
    required this.type,
    required this.isToday,
  });
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  static const Color _blue = Color(0xFF4C7DFF);
  static const Color _income = Color(0xFF2ED8A3);
  static const Color _expense = Color(0xFFFF5470);

  // 0 = همه ، 1 = درآمد ، 2 = هزینه
  int _selectedTab = 0;

  // داده‌ی نمونه، بعداً با داده‌ی واقعی عوضش کن
  final List<_Tx> _items = const [
    _Tx(
      title: 'کافه',
      category: 'خورد و خوراک',
      amount: 65000,
      time: '10:24',
      icon: Icons.local_cafe,
      color: Color(0xFF14B8A6),
      type: TxType.expense,
      isToday: true,
    ),
    _Tx(
      title: 'حقوق',
      category: 'درآمد',
      amount: 12000000,
      time: '09:00',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF22C55E),
      type: TxType.income,
      isToday: true,
    ),
    _Tx(
      title: 'اسنپ',
      category: 'حمل و نقل',
      amount: 124000,
      time: '08:12',
      icon: Icons.directions_car,
      color: Color(0xFF3B82F6),
      type: TxType.expense,
      isToday: true,
    ),
    _Tx(
      title: 'دیجی‌کالا',
      category: 'خرید',
      amount: 899000,
      time: '19:45',
      icon: Icons.shopping_bag,
      color: Color(0xFFF97316),
      type: TxType.expense,
      isToday: false,
    ),
    _Tx(
      title: 'نتفلیکس',
      category: 'سرگرمی',
      amount: 159000,
      time: '18:20',
      icon: Icons.movie,
      color: Color(0xFFE11D48),
      type: TxType.expense,
      isToday: false,
    ),
    _Tx(
      title: 'داروخانه',
      category: 'سلامت',
      amount: 200000,
      time: '16:10',
      icon: Icons.health_and_safety,
      color: Color(0xFF10B981),
      type: TxType.expense,
      isToday: false,
    ),
  ];

  List<_Tx> _filtered(bool today) {
    return _items.where((t) {
      if (t.isToday != today) return false;
      if (_selectedTab == 1) return t.type == TxType.income;
      if (_selectedTab == 2) return t.type == TxType.expense;
      return true;
    }).toList();
  }

  String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
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
            child: Column(
              children: <Widget>[
                // اگه سرچ‌باکس رفت زیر تیتر، این خط رو از کامنت دربیار:
                // const SizedBox(height: 80),
                _buildSearchRow(),
                const SizedBox(height: 25),
                _buildTabBar(),
                const SizedBox(height: 5),
                _buildSection('امروز', _filtered(true)),
                const SizedBox(height: 10),
                _buildSection('دیروز', _filtered(false)),
                // فاصله برای اینکه زیر بتم‌نویگیشن نره
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── سرچ + فیلتر ─────────────
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: GlassBox(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextField(
                        textAlign: TextAlign.start,
                        showCursor: false,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(right: 5.0),
                          hintText: 'جستجو...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            color: Constans.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Lalezar',
                          fontWeight: FontWeight.w500,
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.search,
                    color: Constans.textPrimary.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── تب‌بار شیشه‌ای ─────────────
  Widget _buildTabBar() {
    const labels = ['همه', 'درآمد', 'هزینه'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassBox(
        height: 52,
        padding: const EdgeInsets.all(4),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: List.generate(labels.length, (i) {
              final selected = _selectedTab == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: selected
                          ? const LinearGradient(
                              colors: [Color(0xFF4C7DFF), Color(0xFF7C5CFF)],
                            )
                          : null,
                    ),
                    child: Text(
                      labels[i],
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

  // ───────────── هر بخش (امروز / دیروز) ─────────────
  Widget _buildSection(String title, List<_Tx> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Lalezar',
                fontSize: 25,
                color: Color(0xFF7FB2FF),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: GlassBox(
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _buildTxRow(items[i]),
                  if (i != items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: _blue.withValues(alpha: 0.18),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────── یک ردیف تراکنش ─────────────
  Widget _buildTxRow(_Tx t) {
    final isIncome = t.type == TxType.income;
    final amountColor = isIncome ? _income : _expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // آیکون
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: t.color.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(t.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),

            // عنوان و دسته
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 19,
                      color: Constans.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.category,
                    style: TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 14,
                      color: Constans.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // مبلغ و ساعت
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmt(t.amount).farsiNumber,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontFamily: 'Lalezar',
                        fontSize: 17,
                        color: amountColor,
                      ),
                    ),
                    SizedBox(width: 5),
                    Image.asset(
                      isIncome
                          ? 'assets/images/toman_green.png'
                          : 'assets/images/toman_red.png',

                      width: 25,
                      height: 20,
                      filterQuality: FilterQuality.high,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.time.farsiNumber,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: 'Lalezar',
                    fontSize: 13,
                    color: Constans.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
