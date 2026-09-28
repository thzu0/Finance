// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/database/bank_bin_detector.dart';
import 'package:finance/database/bank_theme.dart';
import 'package:finance/database/card_service.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═════════════════════════════════════════════
// تابع کمکی: تبدیل ارقام فارسی/عربی به انگلیسی
// ═════════════════════════════════════════════
String _normalizeDigits(String input) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final char = String.fromCharCode(rune);
    final pi = persian.indexOf(char);
    if (pi != -1) {
      buffer.write(pi);
      continue;
    }
    final ai = arabic.indexOf(char);
    if (ai != -1) {
      buffer.write(ai);
      continue;
    }
    buffer.write(char);
  }
  return buffer.toString();
}

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen>
    with SingleTickerProviderStateMixin {
  final _cardService = CardService.instance;
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  String _selectedBank = 'ملی';
  bool _hasSaved = false;
  bool _editing = false;
  bool _numberFocused = false;
  bool _holderFocused = false;
  bool _expiryFocused = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _loadSaved();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _entryCtrl.forward();

    _numberCtrl.addListener(_refresh);
    _numberCtrl.addListener(_onNumberChanged);
    _holderCtrl.addListener(_refresh);
    _expiryCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  /// تشخیص خودکار بانک از روی شماره کارت
  void _onNumberChanged() {
    if (_hasSaved && !_editing) return;

    final digits = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) return;

    final detectedBank = BankBinDetector.detectBank(digits);
    if (detectedBank != null && detectedBank != _selectedBank) {
      setState(() => _selectedBank = detectedBank);
    }
  }

  void _loadSaved() {
    if (_cardService.hasCard()) {
      final c = _cardService.getCard();
      _numberCtrl.text = c['number']!;
      _holderCtrl.text = c['holderName']!;
      _expiryCtrl.text = c['expiry']!;
      _selectedBank = c['bankName']!.isEmpty ? 'ملی' : c['bankName']!;
      _hasSaved = true;
      _editing = false;
    }
  }

  bool _isValidLuhn(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) return false;
    int sum = 0;
    bool alternate = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  Future<void> _save() async {
    final number = _numberCtrl.text.replaceAll(RegExp(r'\D'), '');
    final holder = _holderCtrl.text.trim();
    final expiry = _expiryCtrl.text.trim();

    if (number.length != 16) {
      showGlassSnack(context, 'شماره کارت باید ۱۶ رقم باشه');
      return;
    }
    if (!_isValidLuhn(number)) {
      showGlassSnack(context, 'شماره کارت معتبر نیست');
      return;
    }
    if (holder.isEmpty) {
      showGlassSnack(context, 'نام صاحب کارت رو وارد کن');
      return;
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      showGlassSnack(context, 'تاریخ انقضا باید به شکل ۱۲/۰۵ باشه');
      return;
    }

    final detectedBank = BankBinDetector.detectBank(number);
    if (detectedBank == null) {
      showGlassSnack(
        context,
        'این شماره کارت متعلق به بانک‌های شناخته‌شده نیست. بانک رو دستی انتخاب کن.',
      );
      return;
    }

    if (detectedBank != _selectedBank) {
      setState(() => _selectedBank = detectedBank);
    }

    await _cardService.saveCard(
      number: number,
      holderName: holder,
      expiry: expiry,
      bankName: detectedBank,
    );

    if (!mounted) return;
    setState(() {
      _hasSaved = true;
      _editing = false;
    });
    showGlassSnack(context, 'کارت ذخیره شد');
  }

  Future<void> _deleteCard() async {
    final ok = await showGlassConfirm(
      context,
      title: 'حذف کارت',
      message: 'اطلاعات کارت ذخیره‌شده پاک می‌شه. مطمئنی؟',
      confirmText: 'حذف کن',
      danger: true,
    );
    if (!ok || !mounted) return;
    await _cardService.deleteCard();
    _numberCtrl.clear();
    _holderCtrl.clear();
    _expiryCtrl.clear();
    if (!mounted) return;
    setState(() {
      _hasSaved = false;
      _editing = false;
      _selectedBank = 'ملی';
    });
    showGlassSnack(context, 'کارت حذف شد');
  }

  @override
  void dispose() {
    _numberCtrl.removeListener(_refresh);
    _numberCtrl.removeListener(_onNumberChanged);
    _holderCtrl.removeListener(_refresh);
    _expiryCtrl.removeListener(_refresh);
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleBanks = BankTheme.banks
        .where((b) => BankBinDetector.supportedBanks.contains(b.name))
        .toList();

    return GlassPage(
      title: 'کارت‌های بانکی',
      children: [
        // ─── پیش‌نمایش کارت ───
        FadeTransition(
          opacity: _fadeIn,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: _CardPreview(
              number: _numberCtrl.text,
              holder: _holderCtrl.text,
              expiry: _expiryCtrl.text,
              bank: BankTheme.byName(_selectedBank),
            ),
          ),
        ),

        // ─── فرم ───
        FadeTransition(
          opacity: _fadeIn,
          child: const SectionLabel('اطلاعات کارت'),
        ),
        GlassGroup(
          children: [
            _GlassField(
              controller: _numberCtrl,
              label: 'شماره کارت',
              hint: '6104 3377 1234 5678',
              icon: Icons.credit_card,
              keyboardType: TextInputType.visiblePassword,
              focused: _numberFocused,
              onFocus: (v) => setState(() => _numberFocused = v),
              textDirection: TextDirection.ltr,
              enabled: !_hasSaved || _editing,
              formatters: [
                _CardNumberFormatter(),
                LengthLimitingTextInputFormatter(19),
              ],
            ),
            _GlassField(
              controller: _holderCtrl,
              label: 'نام صاحب کارت',
              hint: 'مثلاً امیرطاها احمدی',
              icon: Icons.person_outline,
              focused: _holderFocused,
              onFocus: (v) => setState(() => _holderFocused = v),
              textDirection: TextDirection.rtl,
              enabled: !_hasSaved || _editing,
            ),
            _GlassField(
              controller: _expiryCtrl,
              label: 'تاریخ انقضا',
              hint: 'MM/YY',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.visiblePassword,
              focused: _expiryFocused,
              onFocus: (v) => setState(() => _expiryFocused = v),
              textDirection: TextDirection.ltr,
              enabled: !_hasSaved || _editing,
              formatters: [
                _ExpiryFormatter(),
                LengthLimitingTextInputFormatter(5),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),
        const SectionLabel('بانک صادرکننده'),
        _BankSelector(
          banks: visibleBanks,
          selected: _selectedBank,
          onSelect: (name) => setState(() => _selectedBank = name),
          enabled: !_hasSaved || _editing,
        ),

        const SizedBox(height: 28),

        // ─── دکمه‌ها ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _hasSaved && !_editing
              ? Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.edit_outlined,
                        label: 'ویرایش',
                        color: kSectionBlue,
                        onTap: () => setState(() => _editing = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'حذف',
                        color: kDanger,
                        onTap: _deleteCard,
                      ),
                    ),
                  ],
                )
              : _SaveButton(
                  saved: _hasSaved,
                  onTap: _save,
                  color: BankTheme.byName(_selectedBank).colorEnd,
                ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// پیش‌نمایش کارت
// ═════════════════════════════════════════════
class _CardPreview extends StatelessWidget {
  final String number;
  final String holder;
  final String expiry;
  final BankTheme bank;

  const _CardPreview({
    required this.number,
    required this.holder,
    required this.expiry,
    required this.bank,
  });

  String get _maskedNumber {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '•••• •••• •••• ••••';
    final padded = digits.padRight(16, '•');
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      final char = padded[i];
      buffer.write(i >= 12 ? char : '•');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: 210,
      decoration: BoxDecoration(
        gradient: bank.gradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: bank.colorEnd.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(bank.name),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(bank.icon, color: Colors.white, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'بانک ${bank.name}',
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 26,
                          height: 18,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _maskedNumber,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 22,
                    letterSpacing: 2.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'صاحب کارت',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            holder.isEmpty ? '---' : holder.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'انقضا',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          expiry.isEmpty ? 'MM/YY' : expiry,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// فیلد متنی
// ═════════════════════════════════════════════
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final bool focused;
  final ValueChanged<bool>? onFocus;
  final TextDirection textDirection;
  final bool enabled;

  const _GlassField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.formatters,
    this.focused = false,
    this.onFocus,
    this.textDirection = TextDirection.rtl,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Focus(
          onFocusChange: onFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: focused
                  ? kAccent.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused
                    ? kAccent.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: focused && enabled
                        ? kAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: focused && enabled
                        ? kAccent
                        : Constans.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    inputFormatters: formatters,
                    textDirection: textDirection,
                    readOnly: !enabled, // ← readOnly به‌جای enabled
                    textAlign: textDirection == TextDirection.ltr
                        ? TextAlign.left
                        : TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      color: Constans.textPrimary,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: hint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      labelStyle: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: focused && enabled
                            ? kAccent
                            : Constans.textSecondary,
                      ),
                      hintStyle: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        color: Constans.textSecondary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// انتخابگر بانک
// ═════════════════════════════════════════════
class _BankSelector extends StatelessWidget {
  final List<BankTheme> banks;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool enabled;

  const _BankSelector({
    required this.banks,
    required this.selected,
    required this.onSelect,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.55,
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: banks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            final b = banks[i];
            final isSelected = b.name == selected;
            return GestureDetector(
              onTap: enabled ? () => onSelect(b.name) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 92,
                decoration: BoxDecoration(
                  gradient: isSelected ? b.gradient : null,
                  color: isSelected
                      ? null
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: b.colorEnd.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      b.icon,
                      color: isSelected ? Colors.white : Constans.textSecondary,
                      size: 26,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : Constans.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// دکمه‌ی ذخیره
// ═════════════════════════════════════════════
class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;
  final Color color;

  const _SaveButton({
    required this.saved,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              saved ? Icons.check_circle_outline : Icons.save_outlined,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              saved ? 'به‌روزرسانی کارت' : 'ذخیره‌ی کارت',
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// دکمه‌ی ویرایش / حذف
// ═════════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 15,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// Input Formatters
// ═════════════════════════════════════════════

/// شماره کارت: فارسی→انگلیسی، فیلتر غیرعدد، گروه‌بندی ۴ رقمی
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _normalizeDigits(newValue.text);
    final digits = normalized.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// تاریخ انقضا: فارسی→انگلیسی، فیلتر غیرعدد، فرمت MM/YY
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _normalizeDigits(newValue.text);
    final digits = normalized.replaceAll(RegExp(r'\D'), '');

    String formatted = '';
    if (digits.isNotEmpty) {
      formatted = digits.substring(0, digits.length >= 2 ? 2 : 1);
    }
    if (digits.length > 2) {
      formatted +=
          '/${digits.substring(2, digits.length > 4 ? 4 : digits.length)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
