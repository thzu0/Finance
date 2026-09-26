import 'dart:ui';

import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/icon_map.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

enum TxType { income, expense }

class _Tx {
  final int id;
  final String title;
  final String category;
  final int amount;
  final String time;
  final IconData icon;
  final Color color;
  final TxType type;
  final bool isToday;

  const _Tx({
    required this.id,
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

class Transactionsscreen extends StatefulWidget {
  const Transactionsscreen({super.key});

  @override
  State<Transactionsscreen> createState() => _TransactionsscreenState();
}

class _TransactionsscreenState extends State<Transactionsscreen> {
  static const Color _blue = Color(0xFF4C7DFF);
  static const Color _income = Color(0xFF2ED8A3);
  static const Color _expense = Color(0xFFFF5470);

  // 0 = همه ، 1 = درآمد ، 2 = هزینه
  int _selectedTab = 0;

  List<_Tx> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    // هر وقت تراکنشی جای دیگه‌ای از اپ اضافه/حذف بشه، این صفحه
    // خودکار دوباره از دیتابیس می‌خونه.
    transactionsTicker.addListener(_loadTransactions);
  }

  @override
  void dispose() {
    transactionsTicker.removeListener(_loadTransactions);
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final rows = await getAllTransactions();
    final now = DateTime.now();

    final list = rows.map((r) {
      final t = r.transaction;
      final c = r.category;
      final isToday =
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day;

      return _Tx(
        id: t.id,
        title: t.note.isNotEmpty ? t.note : c.name,
        category: c.name,
        amount: t.amount.toInt(),
        time:
            '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
        icon: iconFromName(c.icon),
        color: hexToColor(c.color),
        type: t.type == 'income' ? TxType.income : TxType.expense,
        isToday: isToday,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
      });
    }
  }

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

  Future<void> _confirmDelete(_Tx t) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: Constans.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Constans.border.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _expense.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: _expense,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'حذف تراکنش',
                      style: TextStyle(
                        fontFamily: 'Lalezar',
                        fontSize: 20,
                        color: Constans.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مطمئنی می‌خوای این تراکنش حذف بشه؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: Constans.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, false),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Constans.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                'انصراف',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Constans.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(ctx, true),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _expense,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'حذف',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (ok == true) {
      await deleteTransaction(t.id);
      if (mounted) {
        setState(() {
          _items.removeWhere((x) => x.id == t.id);
        });
      }
    }
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
                  'تراکنش ها',
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
                  child: Column(
                    children: <Widget>[
                      _buildSearchRow(),
                      const SizedBox(height: 25),
                      _buildTabBar(),
                      const SizedBox(height: 5),
                      if (_items.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildSection('امروز', _filtered(true)),
                        const SizedBox(height: 10),
                        _buildSection('قبلی', _filtered(false)),
                      ],
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ───────────── وضعیت خالی، وسط صفحه ─────────────
  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Constans.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'هنوز هیچ تراکنشی ثبت نکردی',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lalezar',
                fontSize: 16,
                color: Constans.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────── سرچ + فیلتر ─────────────
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GlassBox(
            height: 52,
            width: 52,
            child: IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.tune,
                color: Constans.textPrimary.withValues(alpha: 0.9),
              ),
            ),
          ),
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

  // ───────────── هر بخش (امروز / قبلی) ─────────────
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

  // ───────────── یک ردیف تراکنش (با نگه‌داشتن = حذف) ─────────────
  Widget _buildTxRow(_Tx t) {
    final isIncome = t.type == TxType.income;
    final amountColor = isIncome ? _income : _expense;

    return GestureDetector(
      onLongPress: () => _confirmDelete(t),
      child: Padding(
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
      ),
    );
  }
}
