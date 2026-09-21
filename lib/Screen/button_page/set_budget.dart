// ignore: file_names
import 'package:finance/Constans/constans.dart';
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
  int? _category;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));

  bool get _isMonthly => _mode == 0;

  @override
  void initState() {
    super.initState();
    // با تایپ مبلغ، اسلایدر هم جابه‌جا بشه
    _amountCtrl.addListener(() => setState(() {}));
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
    final i = await showGlassOptionSheet(
      context,
      title: 'انتخاب دسته',
      options: kExpenseCategories,
      selected: _category,
    );
    if (i != null && mounted) setState(() => _category = i);
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

  void _save() {
    final amount = parseAmount(_amountCtrl.text);
    if (_category == null) {
      showGlassSnack(context, 'دسته رو انتخاب کن');
      return;
    }
    if (amount <= 0) {
      showGlassSnack(context, 'سقف بودجه رو وارد کن');
      return;
    }
    // TODO: ذخیره‌ی واقعی بودجه:
    // دسته: kExpenseCategories[_category!] ، سقف: amount ،
    // ماهانه؟: _isMonthly ، شروع: _start ، پایان: _isMonthly ? null : _end
    showGlassSnack(context, 'بودجه ذخیره شد');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cat = _category == null ? null : kExpenseCategories[_category!];
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
              icon: cat?.icon ?? Icons.category_outlined,
              title: 'دسته',
              subtitle: cat?.label ?? 'انتخاب کن',
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
