// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/icon_map.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/budget_repository.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

class SetBudgetScreen extends StatefulWidget {
  // ← اضافه شد: اگه این پر باشه، صفحه توی «حالت ویرایش» بازمیشه
  // و فیلدها با دیتای همین بودجه پر میشن. اگه null باشه، یعنی
  // «افزودن بودجه‌ی جدید» (رفتار قبلی، بدون تغییر).
  final Budget? existingBudget;

  const SetBudgetScreen({super.key, this.existingBudget});

  @override
  State<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  static const int _sliderMax = 20000000;
  static const int _sliderStep = 100000;

  int _mode = 0;
  final TextEditingController _amountCtrl = TextEditingController();

  List<Category> _categories = [];
  int? _categoryIndex;
  bool _loadingCategories = true;

  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));

  bool get _isMonthly => _mode == 0;
  bool get _isEditing => widget.existingBudget != null; // ← اضافه شد

  Category? get _selectedCategory =>
      _categoryIndex == null ? null : _categories[_categoryIndex!];

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() => setState(() {}));

    // ← اضافه شد: اگه داریم ویرایش می‌کنیم، فیلدهایی که به لیست
    // دسته‌ها نیاز ندارن (مبلغ، حالت، تاریخ‌ها) رو همینجا از قبل پر می‌کنیم.
    final existing = widget.existingBudget;
    if (existing != null) {
      _mode = existing.period == 'monthly' ? 0 : 1;
      _amountCtrl.text = formatAmount(existing.amount.round());
      _start = existing.startDate;
      _end =
          existing.endDate ?? existing.startDate.add(const Duration(days: 30));
    }

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await getCategoriesByType('expense');
    if (mounted) {
      setState(() {
        _categories = list;
        _loadingCategories = false;

        // ← اضافه شد: بعد از لود شدن دسته‌ها، اگه ویرایش می‌کنیم،
        // اندیس همون دسته‌ای که این بودجه بهش تعلق داره رو پیدا می‌کنیم.
        final existing = widget.existingBudget;
        if (existing != null) {
          final idx = _categories.indexWhere(
            (c) => c.id == existing.categoryId,
          );
          _categoryIndex = idx == -1 ? null : idx;
        }
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

    // ← اضافه شد: اگه در حالت ویرایشیم، updateBudget صدا زده میشه؛
    // وگرنه (رفتار قبلی) addBudget یه ردیف جدید می‌سازه.
    if (_isEditing) {
      await updateBudget(
        id: widget.existingBudget!.id,
        categoryId: category.id,
        amount: amount.toDouble(),
        period: _isMonthly ? 'monthly' : 'custom',
        startDate: _start,
        endDate: _isMonthly ? null : _end,
      );
    } else {
      await addBudget(
        categoryId: category.id,
        amount: amount.toDouble(),
        period: _isMonthly ? 'monthly' : 'custom',
        startDate: _start,
        endDate: _isMonthly ? null : _end,
      );
    }

    if (!mounted) return;
    showGlassSnack(context, _isEditing ? 'بودجه ویرایش شد' : 'بودجه ذخیره شد');
    Navigator.of(context).pop();
  }

  // ← متد جدید: حذف بودجه از همین صفحه‌ی ویرایش، با یه باتم‌شیت
  // تایید هم‌سبک با بقیه‌ی اپ (شبیه همونی که برای حذف تراکنش ساختیم).
  Future<void> _confirmDelete() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: Constans.background,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: kAccent.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Constans.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kDanger.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline, color: kDanger, size: 28),
                ),
                const SizedBox(height: 14),
                Text(
                  'حذف این بودجه؟',
                  style: TextStyle(
                    fontFamily: 'Lalezar',
                    fontSize: 20,
                    color: Constans.textPrimary,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, false),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Constans.textSecondary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'انصراف',
                            style: TextStyle(
                              fontFamily: 'Lalezar',
                              fontSize: 16,
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
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: kDanger,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'حذف',
                            style: TextStyle(
                              fontFamily: 'Lalezar',
                              fontSize: 16,
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
        );
      },
    );

    if (ok == true && mounted) {
      await deleteBudget(widget.existingBudget!.id);
      if (!mounted) return;
      showGlassSnack(context, 'بودجه حذف شد');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = _selectedCategory;
    final sliderValue = parseAmount(
      _amountCtrl.text,
    ).clamp(0, _sliderMax).toDouble();

    return GlassPage(
      // ← تغییر کرد: تیتر بسته به حالت افزودن/ویرایش فرق می‌کنه
      title: _isEditing ? 'ویرایش بودجه' : 'تعیین بودجه',
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

        // ← اضافه شد: دکمه‌ی حذف، فقط توی حالت ویرایش نشون داده میشه
        if (_isEditing) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _confirmDelete,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kDanger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kDanger.withValues(alpha: 0.4)),
              ),
              child: Text('حذف بودجه', style: glassText(18, color: kDanger)),
            ),
          ),
        ],
      ],
    );
  }
}
