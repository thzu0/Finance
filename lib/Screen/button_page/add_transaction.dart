import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/icon_map.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/seed_categories.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class AddTransactionScreen extends StatefulWidget {
  /// 0 = هزینه ، 1 = درآمد
  final int initialTab;

  const AddTransactionScreen({super.key, this.initialTab = 0});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late int _tab = widget.initialTab;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  int? _categoryIndex;
  List<Category> _dbCategories = [];
  int _account = 0;
  DateTime _date = DateTime.now();

  bool get _isExpense => _tab == 0;
  List<GlassOption> get _categories => _dbCategories
      .map((c) => GlassOption(iconFromName(c.icon), c.name))
      .toList();
  Color get _color => _isExpense ? kDanger : kSuccess;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await getCategoriesByType(_isExpense ? 'expense' : 'income');
    if (mounted) {
      setState(() {
        _dbCategories = list;
        _categoryIndex = null;
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final i = await showGlassOptionSheet(
      context,
      title: _isExpense ? 'انتخاب دسته' : 'انتخاب منبع درآمد',
      options: _categories,
      selected: _categoryIndex,
    );
    if (i != null && mounted) setState(() => _categoryIndex = i);
  }

  Future<void> _pickAccount() async {
    FocusScope.of(context).unfocus();
    final i = await showGlassOptionSheet(
      context,
      title: 'انتخاب حساب',
      options: kAccounts,
      selected: _account,
    );
    if (i != null && mounted) setState(() => _account = i);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final d = await pickGlassDate(context, _date);
    if (d != null && mounted) setState(() => _date = d);
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountCtrl.text);
    if (amount <= 0) {
      showGlassSnack(context, 'مبلغ رو وارد کن');
      return;
    }
    if (_categoryIndex == null) {
      showGlassSnack(
        context,
        _isExpense ? 'دسته رو انتخاب کن' : 'منبع درآمد رو انتخاب کن',
      );
      return;
    }

    final realCategoryId = _dbCategories[_categoryIndex!].id;

    await addTransaction(
      amount: amount.toDouble(),
      categoryId: realCategoryId,
      date: _date,
      type: _isExpense ? 'expense' : 'income',
      note: _noteCtrl.text,
    );

    if (!mounted) return;
    showGlassSnack(context, _isExpense ? 'هزینه ثبت شد' : 'درآمد ثبت شد');
    Navigator.of(context).pop(true); // true یعنی «یه چیزی تغییر کرد»
  }

  @override
  Widget build(BuildContext context) {
    final cat = _categoryIndex == null ? null : _categories[_categoryIndex!];

    return GlassPage(
      title: 'افزودن تراکنش',
      children: [
        const SizedBox(height: 4),
        GlassSegmented(
          labels: const ['هزینه', 'درآمد'],
          selected: _tab,
          onChanged: (i) {
            setState(() => _tab = i);
            _loadCategories();
          },
        ),
        const SizedBox(height: 16),
        AmountField(
          controller: _amountCtrl,
          label: _isExpense ? 'مبلغ هزینه' : 'مبلغ درآمد',
          color: _color,
        ),
        const SizedBox(height: 16),
        GlassGroup(
          children: [
            GlassTile(
              icon: cat?.icon ?? Icons.category_outlined,
              title: _isExpense ? 'دسته' : 'منبع درآمد',
              subtitle: cat?.label ?? 'انتخاب کن',
              onTap: _pickCategory,
            ),
            GlassTile(
              icon: Icons.calendar_month_outlined,
              title: 'تاریخ',
              subtitle: formatJalali(_date),
              onTap: _pickDate,
            ),
            GlassTile(
              icon: kAccounts[_account].icon,
              title: 'حساب',
              subtitle: kAccounts[_account].label,
              onTap: _pickAccount,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassBox(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _noteCtrl,
            maxLines: 3,
            minLines: 2,
            style: glassText(16),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'توضیحات (اختیاری)',
              hintStyle: glassText(16, color: Constans.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GlassSaveButton(
          text: 'ذخیره',
          onPressed: _save,
          colors: _isExpense
              ? const [kAccent, kAccent2]
              : const [Color(0xFF1FBF8F), kSuccess],
        ),
      ],
    );
  }
}
