import 'dart:ui';

import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/icon_map.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/currency_mark.dart';
import 'package:finance/widget/form_widget.dart'; // showAmount
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

enum TxType { income, expense }

enum _Period { all, today, week, month }

enum _Sort { newest, oldest, highest, lowest }

String _periodLabel(_Period p) {
  switch (p) {
    case _Period.all:
      return 'همه';
    case _Period.today:
      return 'امروز';
    case _Period.week:
      return '۷ روز اخیر';
    case _Period.month:
      return '۳۰ روز اخیر';
  }
}

String _sortLabel(_Sort s) {
  switch (s) {
    case _Sort.newest:
      return 'جدیدترین';
    case _Sort.oldest:
      return 'قدیمی‌ترین';
    case _Sort.highest:
      return 'بیشترین مبلغ';
    case _Sort.lowest:
      return 'کمترین مبلغ';
  }
}

/// برای جستجو: ارقام فارسی/عربی → انگلیسی، ي/ك عربی → ی/ک فارسی،
/// نیم‌فاصله حذف، حروف کوچیک
String _norm(String input) {
  const fa = '۰۱۲۳۴۵۶۷۸۹';
  const ar = '٠١٢٣٤٥٦٧٨٩';
  final b = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    final i = fa.indexOf(ch);
    if (i != -1) {
      b.write(i);
      continue;
    }
    final j = ar.indexOf(ch);
    if (j != -1) {
      b.write(j);
      continue;
    }
    if (ch == 'ي') {
      b.write('ی');
    } else if (ch == 'ك') {
      b.write('ک');
    } else if (ch != '\u200c') {
      b.write(ch);
    }
  }
  return b.toString().toLowerCase().trim();
}

class _Tx {
  final int id;
  final String title;
  final String category;
  final int amount; // ریال (همون چیزی که تو دیتابیسه)
  final DateTime date;
  final String time;
  final IconData icon;
  final Color color;
  final TxType type;
  final bool isToday;
  final bool isSms;
  final String bankName;

  const _Tx({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.time,
    required this.icon,
    required this.color,
    required this.type,
    required this.isToday,
    required this.isSms,
    required this.bankName,
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

  final _s = AppSettings.instance;

  // وقتی تنظیمات (واحد پول، مخفی‌کردن مبالغ) عوض بشه، صفحه دوباره ساخته میشه
  void _onSettings() {
    if (mounted) setState(() {});
  }

  // 0 = همه ، 1 = درآمد ، 2 = هزینه
  int _selectedTab = 0;

  // ─── جستجو و فیلتر ───
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  _Period _period = _Period.all;
  _Sort _sort = _Sort.newest;
  final Set<String> _cats = {};

  List<_Tx> _items = [];
  bool _loading = true;

  String get _query => _searchCtrl.text;

  int get _activeFilterCount =>
      (_period != _Period.all ? 1 : 0) +
      (_sort != _Sort.newest ? 1 : 0) +
      (_cats.isNotEmpty ? 1 : 0);

  bool get _hasQueryOrFilter =>
      _query.trim().isNotEmpty || _activeFilterCount > 0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    // هر وقت تراکنشی جای دیگه‌ای از اپ اضافه/حذف بشه، این صفحه
    // خودکار دوباره از دیتابیس می‌خونه.
    transactionsTicker.addListener(_loadTransactions);
    _s.changes.addListener(_onSettings);
  }

  @override
  void dispose() {
    transactionsTicker.removeListener(_loadTransactions);
    _s.changes.removeListener(_onSettings);
    _searchCtrl.dispose();
    _searchFocus.dispose();
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

      final note = t.note;
      final isSms = note.startsWith('پیامک');
      final isIncome = t.type == 'income';

      // عنوان
      final String title;
      if (isSms) {
        title = isIncome ? 'واریز' : 'برداشت';
      } else if (note.isNotEmpty) {
        title = note;
      } else {
        title = c.name;
      }

      // آیکون و رنگ
      final IconData icon;
      final Color iconColor;
      if (isSms) {
        icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;
        iconColor = isIncome ? _income : _expense;
      } else {
        icon = iconFromName(c.icon);
        iconColor = hexToColor(c.color);
      }

      return _Tx(
        id: t.id,
        title: title,
        category: c.name,
        amount: t.amount.toInt(),
        date: t.date,
        time:
            '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}',
        icon: icon,
        color: iconColor,
        type: isIncome ? TxType.income : TxType.expense,
        isToday: isToday,
        isSms: isSms,
        bankName: isSms ? note.replaceFirst('پیامک', '').trim() : '',
      );
    }).toList();

    if (mounted) {
      setState(() {
        _items = list;
        _loading = false;
        // دسته‌هایی که دیگه وجود ندارن از فیلتر حذف بشن
        final names = list.map((t) => t.category).toSet();
        _cats.removeWhere((c) => !names.contains(c));
      });
    }
  }

  // ═════════════════════════════════════════════
  // منطق جستجو / فیلتر / مرتب‌سازی
  // ═════════════════════════════════════════════
  bool _tabOk(_Tx t) {
    if (_selectedTab == 1) return t.type == TxType.income;
    if (_selectedTab == 2) return t.type == TxType.expense;
    return true;
  }

  /// هر کلمه‌ی جستجو باید توی عنوان/دسته باشه؛ کلمه‌ی عددی می‌تونه
  /// با مبلغ (همون عددی که کاربر روی صفحه می‌بینه) هم جور بشه.
  bool _matchesQuery(_Tx t) {
    final q = _norm(_query);
    if (q.isEmpty) return true;

    final haystack = _norm('${t.title} ${t.category}');
    final amountDigits = _norm(
      showAmount(t.amount),
    ).replaceAll(RegExp(r'\D'), '');

    for (final token in q.split(RegExp(r'\s+'))) {
      if (token.isEmpty) continue;
      final inText = haystack.contains(token);
      final isNumber = RegExp(r'^\d+$').hasMatch(token);
      final inAmount =
          isNumber && amountDigits.isNotEmpty && amountDigits.contains(token);
      if (!inText && !inAmount) return false;
    }
    return true;
  }

  bool _passesFilters(_Tx t, _Period period, Set<String> cats) {
    if (cats.isNotEmpty && !cats.contains(t.category)) return false;
    if (period != _Period.all) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = switch (period) {
        _Period.today => today,
        _Period.week => today.subtract(const Duration(days: 6)),
        _Period.month => today.subtract(const Duration(days: 29)),
        _Period.all => today,
      };
      if (t.date.isBefore(start)) return false;
    }
    return true;
  }

  List<_Tx> _filtered(bool today) {
    final list = _items.where((t) {
      if (t.isToday != today) return false;
      return _tabOk(t) && _matchesQuery(t) && _passesFilters(t, _period, _cats);
    }).toList();

    switch (_sort) {
      case _Sort.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case _Sort.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case _Sort.highest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case _Sort.lowest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  void _clearSearchAndFilters() {
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _period = _Period.all;
      _sort = _Sort.newest;
      _cats.clear();
    });
  }

  // ═════════════════════════════════════════════
  // شیت فیلتر
  // ═════════════════════════════════════════════
  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();

    var period = _period;
    var sort = _sort;
    final cats = {..._cats};

    // دسته‌ها از خود تراکنش‌ها در میان (با آیکون و رنگ)
    final meta = <String, _Tx>{};
    for (final t in _items) {
      meta.putIfAbsent(t.category, () => t);
    }
    final names = meta.keys.toList()..sort();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final count = _items
              .where(
                (t) =>
                    _tabOk(t) &&
                    _matchesQuery(t) &&
                    _passesFilters(t, period, cats),
              )
              .length;
          final dirty =
              period != _Period.all || sort != _Sort.newest || cats.isNotEmpty;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.82,
                  ),
                  decoration: BoxDecoration(
                    color: Constans.surface.withValues(alpha: 0.82),
                    border: Border(
                      top: BorderSide(
                        color: Constans.border.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'فیلتر و مرتب‌سازی',
                                  style: TextStyle(
                                    fontFamily: 'Lalezar',
                                    fontSize: 22,
                                    color: Constans.textPrimary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: dirty
                                    ? () => setSheet(() {
                                        period = _Period.all;
                                        sort = _Sort.newest;
                                        cats.clear();
                                      })
                                    : null,
                                child: Text(
                                  'پاک کردن',
                                  style: TextStyle(
                                    fontFamily: 'Lalezar',
                                    fontSize: 16,
                                    color: dirty
                                        ? _expense
                                        : Constans.textSecondary.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sheetTitle('بازه‌ی زمانی'),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final p in _Period.values)
                                        _FilterChip(
                                          label: _periodLabel(p),
                                          selected: period == p,
                                          onTap: () =>
                                              setSheet(() => period = p),
                                        ),
                                    ],
                                  ),
                                  _sheetTitle('مرتب‌سازی'),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final s in _Sort.values)
                                        _FilterChip(
                                          label: _sortLabel(s),
                                          selected: sort == s,
                                          onTap: () => setSheet(() => sort = s),
                                        ),
                                    ],
                                  ),
                                  if (names.isNotEmpty) ...[
                                    _sheetTitle('دسته‌بندی'),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final n in names)
                                          _FilterChip(
                                            label: n,
                                            icon: meta[n]!.icon,
                                            iconColor: meta[n]!.color,
                                            selected: cats.contains(n),
                                            onTap: () => setSheet(() {
                                              if (!cats.remove(n)) cats.add(n);
                                            }),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _period = period;
                                _sort = sort;
                                _cats
                                  ..clear()
                                  ..addAll(cats);
                              });
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4C7DFF),
                                    Color(0xFF7C5CFF),
                                  ],
                                ),
                              ),
                              child: Text(
                                count == 0
                                    ? 'نتیجه‌ای پیدا نشد'
                                    : 'نمایش $count تراکنش'.farsiNumber,
                                style: const TextStyle(
                                  fontFamily: 'Lalezar',
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sheetTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Lalezar',
          fontSize: 17,
          color: Color(0xFF7FB2FF),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════
  // حذف
  // ═════════════════════════════════════════════
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
    final todayList = _loading ? <_Tx>[] : _filtered(true);
    final prevList = _loading ? <_Tx>[] : _filtered(false);

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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: <Widget>[
                      _buildSearchRow(),
                      const SizedBox(height: 25),
                      _buildTabBar(),
                      _buildActiveFilters(),
                      const SizedBox(height: 5),
                      if (_items.isEmpty)
                        _buildEmptyState()
                      else if (todayList.isEmpty && prevList.isEmpty)
                        _buildNoResults()
                      else ...[
                        _buildSection('امروز', todayList),
                        const SizedBox(height: 10),
                        _buildSection('قبلی', prevList),
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

  // ───────────── وقتی جستجو/فیلتر چیزی پیدا نکرد ─────────────
  Widget _buildNoResults() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Constans.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              'تراکنشی با این مشخصات پیدا نشد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Lalezar',
                fontSize: 16,
                color: Constans.textSecondary,
              ),
            ),
            if (_hasQueryOrFilter) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: _clearSearchAndFilters,
                child: const Text(
                  'پاک کردن جستجو و فیلترها',
                  style: TextStyle(
                    fontFamily: 'Lalezar',
                    fontSize: 16,
                    color: _blue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────── سرچ + فیلتر ─────────────
  Widget _buildSearchRow() {
    final active = _activeFilterCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // دکمه‌ی فیلتر، با نقطه‌ی نشانگر وقتی فیلتری فعاله
          Stack(
            clipBehavior: Clip.none,
            children: [
              GlassBox(
                height: 52,
                width: 52,
                child: IconButton(
                  onPressed: _openFilterSheet,
                  tooltip: 'فیلتر',
                  icon: Icon(
                    Icons.tune,
                    color: active > 0
                        ? _blue
                        : Constans.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
              ),
              if (active > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: IgnorePointer(
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$active'.farsiNumber,
                        style: const TextStyle(
                          fontFamily: 'Lalezar',
                          fontSize: 12,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GlassBox(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  // دکمه‌ی پاک کردن متن
                  if (_query.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Constans.textSecondary,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        textAlign: TextAlign.start,
                        cursorColor: _blue,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _searchFocus.unfocus(),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(right: 5.0),
                          hintText: 'جستجو در عنوان، دسته یا مبلغ...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(
                            fontFamily: 'Lalezar',
                            fontSize: 15,
                            color: Constans.textSecondary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Lalezar',
                          fontWeight: FontWeight.w500,
                          fontSize: 18.0,
                          color: Constans.textPrimary,
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

  // ───────────── چیپ‌های فیلتر فعال (با ✕ برای برداشتن تکی) ─────────────
  Widget _buildActiveFilters() {
    final chips = <Widget>[];
    if (_period != _Period.all) {
      chips.add(
        _activeChip(
          _periodLabel(_period),
          () => setState(() => _period = _Period.all),
        ),
      );
    }
    if (_sort != _Sort.newest) {
      chips.add(
        _activeChip(
          _sortLabel(_sort),
          () => setState(() => _sort = _Sort.newest),
        ),
      );
    }
    for (final c in _cats) {
      chips.add(_activeChip(c, () => setState(() => _cats.remove(c))));
    }
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: double.infinity,
          child: Wrap(spacing: 8, runSpacing: 8, children: chips),
        ),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _blue.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close_rounded, size: 16, color: Constans.textSecondary),
            const SizedBox(width: 6),
            Text(
              label.farsiNumber,
              style: TextStyle(
                fontFamily: 'Lalezar',
                fontSize: 14,
                color: Constans.textPrimary,
              ),
            ),
          ],
        ),
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

              // عنوان + زیرعنوان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Lalezar',
                        fontSize: 19,
                        color: Constans.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // چیپ دسته — فقط برای تراکنش‌های دستی
                        if (!t.isSms) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              t.category,
                              style: TextStyle(
                                fontFamily: 'Lalezar',
                                fontSize: 12,
                                color: Constans.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        // برچسب منبع پیامکی
                        if (t.isSms && t.bankName.isNotEmpty) ...[
                          Icon(
                            Icons.sms_outlined,
                            size: 14,
                            color: Constans.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            t.bankName,
                            style: TextStyle(
                              fontFamily: 'Lalezar',
                              fontSize: 13,
                              color: Constans.textSecondary,
                            ),
                          ),
                        ],
                      ],
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
                        '${isIncome ? '+' : '−'}${showAmount(t.amount)}',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontFamily: 'Lalezar',
                          fontSize: 17,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      CurrencyMark(
                        color: isIncome ? 'green' : 'red',
                        width: 25,
                        height: 26,
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

// ═════════════════════════════════════════════
// چیپ انتخاب توی شیت فیلتر
// ═════════════════════════════════════════════
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? iconColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF4C7DFF), Color(0xFF7C5CFF)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected
                    ? Colors.white
                    : (iconColor ?? Constans.textSecondary),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lalezar',
                fontSize: 15,
                color: selected ? Colors.white : Constans.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
