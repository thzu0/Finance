// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/icon_map.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/budget_repository.dart';
import 'package:finance/database/seed_categories.dart'; // getCategoriesByType اینجاست
import 'package:finance/widget/form_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

class SetBudgetScreen extends StatefulWidget {
  const SetBudgetScreen({super.key});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  static const int _sliderMax = 20000000;
  static const int _sliderStep = 100000;

  int _mode = 0; // 0 = ماهانه ، 1 = سفارشی
  final TextEditingController _amountCtrl = TextEditingController();

  // ← به‌جای اندیس ساده روی لیست استاتیک، حالا دسته‌های واقعی
  // از دیتابیس می‌خونیم و اندیسِ انتخاب‌شده رو نگه می‌داریم.
  List<Category> _categories = [];
  int? _categoryIndex;
  bool _loadingCategories = true;

  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));

  bool get _isMonthly => _mode == 0;

  // ← دسته‌ی واقعاً انتخاب‌شده (یا null اگه هنوز چیزی انتخاب نشده)
  Category? get _selectedCategory =>
      _categoryIndex == null ? null : _categories[_categoryIndex!];

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));
    _loadCategories(); // ← دسته‌های هزینه رو از دیتابیس واقعی می‌خونیم
  }

  // ← متد جدید: چون بودجه فقط برای دسته‌های "هزینه" معنی داره،
  // فقط دسته‌هایی با type == 'expense' رو می‌خونیم.
  Future<void> _loadCategories() async {
    final list = await getCategoriesByType('expense');
    if (mounted) {
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _setAmount(int n) {
    final t = n == 0 ? '' : formatAmount(n);
    _amountCtrl.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();

    if (_loadingCategories || _categories.isEmpty) {
      showGlassSnack(context, 'دسته‌ها هنوز لود نشده‌ن، یه لحظه صبر کن');
      return;
    }

    // ← به‌جای kExpenseCategories ثابت، لیست GlassOption رو از روی
    // دسته‌های واقعی دیتابیس می‌سازیم (آیکون هر دسته با iconFromName
    // از رشته‌ی ذخیره‌شده توی دیتابیس بازسازی میشه).
    final options = _categories
        .map((c) => GlassOption(iconFromName(c.icon), c.name))
        .toList();

    final i = await showGlassOptionSheet(
      context,
      title: 'انتخاب دسته',
      options: options,
      selected: _categoryIndex,
    );
    if (i != null && mounted) setState(() => _categoryIndex = i);
  }

  Future<void> _pickStart() async {
    FocusScope.of(context).unfocus();
    final d = await pickGlassDate(context, _start);
    if (d == null || !mounted) return;
    setState(() {
      _start = d;
      if (_end.isBefore(_start)) _end = _start.add(const Duration(days: 30));
    });
  }

  Future<void> _pickEnd() async {
    FocusScope.of(context).unfocus();
    final d = await pickGlassDate(context, _end, first: _start);
    if (d != null && mounted) setState(() => _end = d);
  }

  // ← دیگه فقط اسنک‌بار نمی‌زنه؛ واقعاً توی دیتابیس ذخیره می‌کنه.
  Future<void> _save() async {
    final amount = parseAmount(_amountCtrl.text);
    final category = _selectedCategory;

    if (category == null) {
      showGlassSnack(context, 'دسته رو انتخاب کن');
      return;
    }
    if (amount <= 0) {
      showGlassSnack(context, 'سقف بودجه رو وارد کن');
      return;
    }
    if (!_isMonthly && !_end.isAfter(_start)) {
      showGlassSnack(context, 'تاریخ پایان باید بعد از تاریخ شروع باشه');
      return;
    }

    // ← ذخیره‌ی واقعی. خودِ addBudget بعد از ذخیره، budgetsTicker رو
    // صدا می‌زنه تا هر صفحه‌ای که لیست بودجه‌ها رو نشون میده، خودکار رفرش شه.
    await addBudget(
      categoryId: category.id,
      amount: amount.toDouble(),
      period: _isMonthly ? 'monthly' : 'custom',
      startDate: _start,
      endDate: _isMonthly ? null : _end,
    );

    if (!mounted) return;
    showGlassSnack(context, 'بودجه ذخیره شد');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cat = _selectedCategory;
    final sliderValue = parseAmount(
      _amountCtrl.text,
    ).clamp(0, _sliderMax).toDouble();

    return GlassPage(
      title: 'تعیین بودجه',
      children: [
        const SizedBox(height: 4),
        GlassSegmented(
          labels: const ['ماهانه', 'سفارشی'],
          selected: _mode,
          onChanged: (i) => setState(() => _mode = i),
        ),
        const SizedBox(height: 16),
        GlassGroup(
          children: [
            GlassTile(
              icon: cat == null
                  ? Icons.category_outlined
                  : iconFromName(cat.icon),
              title: 'دسته',
              subtitle: cat?.name ?? 'انتخاب کن',
              onTap: _pickCategory,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AmountField(
          controller: _amountCtrl,
          label: _isMonthly ? 'سقف ماهانه' : 'سقف بودجه',
          color: kSectionBlue,
        ),
        const SizedBox(height: 12),
        GlassBox(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: kAccent,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                  thumbColor: Colors.white,
                  overlayColor: kAccent.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: sliderValue,
                  min: 0,
                  max: _sliderMax.toDouble(),
                  divisions: _sliderMax ~/ _sliderStep,
                  onChanged: (v) => _setAmount(v.round()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '۰',
                      style: glassText(13, color: Constans.textSecondary),
                    ),
                    Text(
                      formatAmount(_sliderMax),
                      style: glassText(13, color: Constans.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.calendar_month_outlined,
              title: 'تاریخ شروع',
              subtitle: formatJalali(_start),
              onTap: _pickStart,
            ),
            if (!_isMonthly)
              GlassTile(
                icon: Icons.event_available_outlined,
                title: 'تاریخ پایان',
                subtitle: formatJalali(_end),
                onTap: _pickEnd,
              ),
          ],
        ),
        const SizedBox(height: 24),
        GlassSaveButton(text: 'ذخیره', onPressed: _save),
      ],
    );
  }
}
