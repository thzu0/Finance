// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/database/bank_bin_detector.dart';
import 'package:finance/database/bank_theme.dart';
import 'package:finance/database/card_service.dart';
import 'package:finance/services/sms_permission.dart';
import 'package:finance/services/sms_sync_service.dart';
import 'package:finance/sms/bank_sms_parser.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _font = 'Vazirmatn';
const _ok = Color(0xFF34D399);

// ═════════════════════════════════════════════
// تبدیل ارقام فارسی/عربی به انگلیسی
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

final _nonDigit = RegExp(r'\D');
final _singleDigit = RegExp(r'\d');

enum _CardField { number, holder, expiry }

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
  final _numberFocus = FocusNode();
  final _holderFocus = FocusNode();
  final _expiryFocus = FocusNode();

  String _selectedBank = 'ملی';
  // کاربر خودش بانک رو انتخاب کرده (یا بانک ذخیره‌شده داریم)؟
  bool _bankPicked = false;
  bool _hasSaved = false;
  bool _editing = false;
  bool _smsEnabled = false;
  bool _revealNumber = false;
  int _prevDigitsLen = 0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  late final Listenable _inputs;

  // ─── getterهای کمکی ───
  String get _digits => _numberCtrl.text.replaceAll(_nonDigit, '');
  String? get _detectedBank =>
      _digits.length >= 6 ? BankBinDetector.detectBank(_digits) : null;
  bool get _canEdit => !_hasSaved || _editing;
  bool get _bankKnown => _detectedBank != null || _bankPicked;
  bool get _numberOk => _digits.length == 16 && _isValidLuhn(_digits);
  bool get _expiryOk => _isValidExpiry(_expiryCtrl.text.trim());
  bool get _canSubmit =>
      _numberOk &&
      _holderCtrl.text.trim().isNotEmpty &&
      _expiryOk &&
      _bankKnown;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _checkSmsPermission();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic);
    _slideIn = _fadeIn.drive(
      Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero),
    );
    _entryCtrl.forward();

    // فقط یه لیسنر برای همه‌ی ورودی‌ها
    _inputs = Listenable.merge([
      _numberCtrl,
      _holderCtrl,
      _expiryCtrl,
      _numberFocus,
      _holderFocus,
      _expiryFocus,
    ]);
    _inputs.addListener(_onInputsChanged);
  }

  void _onInputsChanged() {
    if (!mounted) return;
    final digits = _digits;

    if (_canEdit) {
      final detected = _detectedBank;
      if (detected != null) _selectedBank = detected;

      // وقتی شماره‌ی معتبر کامل شد، بپر روی نام صاحب کارت
      if (digits.length == 16 &&
          _prevDigitsLen < 16 &&
          _numberFocus.hasFocus &&
          _isValidLuhn(digits)) {
        _holderFocus.requestFocus();
      }
    }
    _prevDigitsLen = digits.length;
    setState(() {});
  }

  Future<void> _checkSmsPermission() async {
    final stillGranted = await SmsPermissionService.isStillGranted();
    if (!mounted) return;
    setState(() => _smsEnabled = stillGranted);
  }

  void _loadSaved() {
    if (!_cardService.hasCard()) return;
    final c = _cardService.getCard();
    final bank = c['bankName']!;
    // اول فلگ‌ها، بعد کنترلرها (که لیسنر رو صدا می‌زنن)
    _hasSaved = true;
    _editing = false;
    _bankPicked = bank.isNotEmpty;
    _selectedBank = bank.isEmpty ? 'ملی' : bank;
    _numberCtrl.text = c['number']!;
    _holderCtrl.text = c['holderName']!;
    _expiryCtrl.text = c['expiry']!;
    _prevDigitsLen = _digits.length;
  }

  // انصراف از ویرایش: مقادیر ذخیره‌شده برمی‌گردن
  void _cancelEdit() {
    FocusScope.of(context).unfocus();
    _loadSaved();
    setState(() => _revealNumber = false);
  }

  bool _isValidLuhn(String number) {
    final digits = number.replaceAll(_nonDigit, '');
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

  // روی بعضی کارت‌ها سال/ماه هست و روی بعضی ماه/سال،
  // پس فقط چک می‌کنیم یکی از دو بخش یه ماه معتبر (۰۱ تا ۱۲) باشه.
  bool _isValidExpiry(String expiry) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch(expiry);
    if (m == null) return false;
    bool isMonth(int x) => x >= 1 && x <= 12;
    return isMonth(int.parse(m[1]!)) || isMonth(int.parse(m[2]!));
  }

  Future<void> _save() async {
    final number = _digits;
    final holder = _holderCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
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
    if (!_isValidExpiry(expiry)) {
      showGlassSnack(context, 'تاریخ انقضا معتبر نیست (مثلاً ۰۵/۱۲)');
      return;
    }

    // اگه BIN شناخته‌شده بود همون، وگرنه بانکی که کاربر دستی انتخاب کرده
    final bank = _detectedBank ?? (_bankPicked ? _selectedBank : null);
    if (bank == null) {
      showGlassSnack(
        context,
        'بانک این کارت تشخیص داده نشد، از لیست انتخابش کن',
      );
      return;
    }

    await _cardService.saveCard(
      number: number,
      holderName: holder,
      expiry: expiry,
      bankName: bank,
    );

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedBank = bank;
      _bankPicked = true;
      _hasSaved = true;
      _editing = false;
      _revealNumber = false;
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
    // بدون کارت، خوندن پیامک هم باید خاموش بشه (قبلاً فقط UI خاموش می‌شد)
    if (_smsEnabled) await SmsPermissionService.disable();
    if (!mounted) return;

    _hasSaved = false;
    _editing = false;
    _bankPicked = false;
    _selectedBank = 'ملی';
    _numberCtrl.clear();
    _holderCtrl.clear();
    _expiryCtrl.clear();
    setState(() {
      _smsEnabled = false;
      _revealNumber = false;
    });
    showGlassSnack(context, 'کارت حذف شد');
  }

  Future<void> _copyNumber() async {
    await Clipboard.setData(ClipboardData(text: _digits));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    showGlassSnack(context, 'شماره کارت کپی شد');
  }

  // ─── سوییچ پیامک ───

  Future<void> _toggleSmsParsing(bool enable) async {
    if (!enable) {
      await SmsPermissionService.disable();
      if (!mounted) return;
      setState(() => _smsEnabled = false);
      return;
    }

    if (!_cardService.hasCard()) {
      showGlassSnack(context, 'اول کارتت رو ذخیره کن');
      return;
    }
    final bankName = _cardService.getCard()['bankName'] ?? '';
    if (!SmsParserRegistry.isSupported(bankName)) {
      showGlassSnack(context, 'خواندن پیامک این بانک هنوز پشتیبانی نمی‌شه');
      return;
    }

    final result = await SmsPermissionService.request();
    if (!mounted) return;

    switch (result) {
      case SmsPermissionResult.granted:
        setState(() => _smsEnabled = true);
        final n = await SmsSyncService.sync();
        if (!mounted) return;
        showGlassSnack(
          context,
          n > 0 ? '$n تراکنش جدید ثبت شد' : 'خواندن خودکار پیامک فعال شد',
        );

        break;
      case SmsPermissionResult.denied:
        setState(() => _smsEnabled = false);
        showGlassSnack(context, 'برای خواندن پیامک‌ها، دسترسی لازمه');
        break;
      case SmsPermissionResult.permanentlyDenied:
        setState(() => _smsEnabled = false);
        final goToSettings = await showGlassConfirm(
          context,
          title: 'دسترسی به پیامک',
          message:
              'برای خواندن خودکار پیامک‌ها، باید توی تنظیمات گوشی دسترسی بدی. الان بریم؟',
          confirmText: 'برو به تنظیمات',
        );
        if (goToSettings) {
          await SmsPermissionService.openSettings();
        }
        break;
    }
  }

  @override
  void dispose() {
    _inputs.removeListener(_onInputsChanged);
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _numberFocus.dispose();
    _holderFocus.dispose();
    _expiryFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════
  // UI
  // ═════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final canEdit = _canEdit;
    final bank = BankTheme.byName(_selectedBank);
    final masked = _hasSaved && !_editing && !_revealNumber;

    _CardField? active;
    if (_numberFocus.hasFocus) {
      active = _CardField.number;
    } else if (_holderFocus.hasFocus) {
      active = _CardField.holder;
    } else if (_expiryFocus.hasFocus) {
      active = _CardField.expiry;
    }

    return GlassPage(
      title: 'کارت‌های بانکی',
      children: [
        // ─── کارت (عنصر اصلی صفحه) ───
        FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideIn,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _CardPreview(
                digits: _digits,
                holder: _holderCtrl.text,
                expiry: _expiryCtrl.text,
                bank: bank,
                bankKnown: _bankKnown,
                masked: masked,
                active: canEdit ? active : null,
              ),
            ),
          ),
        ),

        // ─── فرم یا نمای ذخیره‌شده ───
        AnimatedSize(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            child: KeyedSubtree(
              key: ValueKey(canEdit),
              child: canEdit ? _buildEditor() : _buildSaved(),
            ),
          ),
        ),

        // ─── خواندن خودکار پیامک ───
        const SizedBox(height: 28),
        const SectionLabel('خواندن خودکار پیامک'),
        GlassGroup(
          children: [
            GlassSwitchTile(
              icon: Icons.sms_outlined,
              title: 'خواندن پیامک‌های بانکی',
              subtitle: _smsEnabled
                  ? 'فعال — تراکنش‌ها خودکار ثبت می‌شن'
                  : 'غیرفعال — برای فعال‌سازی روشن کن',
              value: _smsEnabled,
              onChanged: _toggleSmsParsing,
            ),
            if (_smsEnabled)
              const GlassTile(
                icon: Icons.info_outline,
                title: 'راهنما',
                subtitle:
                    'اپ فقط پیامک‌های بانکی رو می‌خونه و مبلغ و تاریخ رو استخراج می‌کنه.',
              ),
          ],
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // حالت کارت ذخیره‌شده: نمایش/کپی + ویرایش/حذف
  Widget _buildSaved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MiniAction(
              icon: _revealNumber
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              label: _revealNumber ? 'مخفی کن' : 'نمایش شماره',
              onTap: () => setState(() => _revealNumber = !_revealNumber),
            ),
            const SizedBox(width: 10),
            _MiniAction(
              icon: Icons.copy_rounded,
              label: 'کپی شماره',
              onTap: _copyNumber,
            ),
          ],
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.edit_outlined,
                  label: 'ویرایش',
                  color: kSectionBlue,
                  onTap: () => setState(() {
                    _editing = true;
                    _revealNumber = false;
                  }),
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
          ),
        ),
      ],
    );
  }

  // حالت فرم: اطلاعات + بانک + دکمه‌ها
  Widget _buildEditor() {
    final digits = _digits;
    final detected = _detectedBank;
    final bank = BankTheme.byName(_selectedBank);
    final visibleBanks = BankTheme.banks
        .where((b) => BankBinDetector.supportedBanks.contains(b.name))
        .toList();

    String? statusMessage;
    bool statusOk = false;
    if (detected != null) {
      statusMessage = 'بانک $detected از روی شماره کارت تشخیص داده شد';
      statusOk = true;
    } else if (digits.length >= 6) {
      statusMessage = 'بانک تشخیص داده نشد، خودت از لیست انتخابش کن';
    }

    final numberError = digits.length == 16 && !_isValidLuhn(digits)
        ? 'شماره کارت معتبر نیست'
        : null;
    final expiryText = _expiryCtrl.text;
    final expiryError = expiryText.length == 5 && !_expiryOk
        ? 'تاریخ انقضا معتبر نیست'
        : null;

    Widget? numberSuffix;
    if (digits.length == 16) {
      numberSuffix = Icon(
        numberError == null ? Icons.check_circle : Icons.error_outline,
        size: 20,
        color: numberError == null ? _ok : kDanger,
      );
    } else if (digits.isNotEmpty) {
      numberSuffix = Text(
        '${digits.length}/16',
        textDirection: TextDirection.ltr,
        style: TextStyle(
          fontFamily: _font,
          fontSize: 11,
          color: Constans.textSecondary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('اطلاعات کارت'),
        GlassGroup(
          children: [
            _GlassField(
              controller: _numberCtrl,
              focusNode: _numberFocus,
              label: 'شماره کارت',
              hint: '6104 3377 1234 5678',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              action: TextInputAction.next,
              onSubmitted: (_) => _holderFocus.requestFocus(),
              suffix: numberSuffix,
              errorText: numberError,
              formatters: [
                _CardNumberFormatter(),
                LengthLimitingTextInputFormatter(19),
              ],
            ),
            _GlassField(
              controller: _holderCtrl,
              focusNode: _holderFocus,
              label: 'نام صاحب کارت',
              hint: 'مثلاً علی احمدی',
              icon: Icons.person_outline,
              textDirection: TextDirection.rtl,
              action: TextInputAction.next,
              capitalization: TextCapitalization.words,
              onSubmitted: (_) => _expiryFocus.requestFocus(),
              formatters: [LengthLimitingTextInputFormatter(26)],
            ),
            _GlassField(
              controller: _expiryCtrl,
              focusNode: _expiryFocus,
              label: 'تاریخ انقضا',
              hint: '05/12',
              icon: Icons.calendar_today_outlined,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.ltr,
              action: TextInputAction.done,
              errorText: expiryError,
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
          selected: _bankKnown ? _selectedBank : null,
          locked: detected != null,
          onSelect: (name) => setState(() {
            _selectedBank = name;
            _bankPicked = true;
          }),
        ),
        _BankStatus(message: statusMessage, ok: statusOk),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _SaveButton(
                  saved: _hasSaved,
                  ready: _canSubmit,
                  onTap: _save,
                  color: bank.colorEnd,
                ),
              ),
              // انصراف فقط تو حالت ویرایش کارت ذخیره‌شده معنی داره
              if (_hasSaved && _editing) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.close,
                    label: 'انصراف',
                    color: Constans.textSecondary,
                    onTap: _cancelEdit,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// پیش‌نمایش کارت
// ═════════════════════════════════════════════
List<double> _saturationMatrix(double s) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final ir = (1 - s) * r, ig = (1 - s) * g, ib = (1 - s) * b;
  return [
    ir + s, ig, ib, 0, 0, //
    ir, ig + s, ib, 0, 0,
    ir, ig, ib + s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

class _CardPreview extends StatelessWidget {
  final String digits;
  final String holder;
  final String expiry;
  final BankTheme bank;
  final bool bankKnown; // بانک ناشناخته → کارت خاکستری
  final bool masked; // فقط ۴ رقم آخر
  final _CardField? active;

  const _CardPreview({
    required this.digits,
    required this.holder,
    required this.expiry,
    required this.bank,
    required this.bankKnown,
    required this.masked,
    required this.active,
  });

  List<InlineSpan> _numberSpans() {
    final spans = <InlineSpan>[];
    for (int i = 0; i < 16; i++) {
      if (i > 0 && i % 4 == 0) spans.add(const TextSpan(text: '  '));
      final filled = i < digits.length;
      if (masked) {
        spans.add(TextSpan(text: (i >= 12 && filled) ? digits[i] : '•'));
      } else if (filled) {
        spans.add(TextSpan(text: digits[i]));
      } else {
        spans.add(
          TextSpan(
            text: '•',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
        );
      }
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final shadowColor = bankKnown ? bank.colorEnd : Colors.black;

    // کارت همیشه RTL چیده می‌شه، مستقل از جهت صفحه
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AspectRatio(
        aspectRatio: 1.586,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          // ClipRRect: دایره‌های تزئینی دیگه از گوشه‌ها بیرون نمی‌زنن
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: bankKnown ? 1.0 : 0.0),
              duration: const Duration(milliseconds: 450),
              builder: (context, sat, child) => ColorFiltered(
                colorFilter: ColorFilter.matrix(_saturationMatrix(sat)),
                child: child,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(gradient: bank.gradient),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: -50,
                      right: -40,
                      child: _Circle(size: 190, alpha: 0.08),
                    ),
                    Positioned(
                      bottom: -70,
                      left: -50,
                      child: _Circle(size: 210, alpha: 0.06),
                    ),
                    // برق ملایم شیشه‌ای
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.white.withValues(alpha: 0.2),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.55],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: _content(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Row(
                key: ValueKey(bankKnown ? bank.name : '?'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    bankKnown ? bank.icon : Icons.account_balance_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bankKnown ? 'بانک ${bank.name}' : 'بانک نامشخص',
                    style: const TextStyle(
                      fontFamily: _font,
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.nfc,
                  color: Colors.white.withValues(alpha: 0.75),
                  size: 22,
                ),
                const SizedBox(width: 10),
                _Chip(),
              ],
            ),
          ],
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            TextSpan(children: _numberSpans()),
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 22,
              letterSpacing: 2,
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
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _CardLabelValue(
                label: 'صاحب کارت',
                value: holder.isEmpty ? 'نام صاحب کارت' : holder.toUpperCase(),
                dim: holder.isEmpty,
                active: active == _CardField.holder,
                crossAxisAlignment: CrossAxisAlignment.start,
              ),
            ),
            _CardLabelValue(
              label: 'انقضا',
              value: expiry.isEmpty ? '--/--' : expiry,
              dim: expiry.isEmpty,
              active: active == _CardField.expiry,
              ltr: true,
              crossAxisAlignment: CrossAxisAlignment.end,
            ),
          ],
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double alpha;
  const _Circle({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _CardLabelValue extends StatelessWidget {
  final String label;
  final String value;
  final bool dim;
  final bool active;
  final bool ltr;
  final CrossAxisAlignment crossAxisAlignment;

  const _CardLabelValue({
    required this.label,
    required this.value,
    required this.dim,
    required this.active,
    required this.crossAxisAlignment,
    this.ltr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: _font,
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 3),
        // خط زیر مقدارِ فیلدی که الان توش تایپ می‌کنی
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: active ? 0.9 : 0.0),
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: ltr ? TextDirection.ltr : null,
            style: TextStyle(
              fontFamily: _font,
              fontSize: 14,
              color: Colors.white.withValues(alpha: dim ? 0.5 : 1),
              fontWeight: FontWeight.w500,
              letterSpacing: ltr ? 1 : 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════
// فیلد متنی
// ═════════════════════════════════════════════
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final TextDirection textDirection;
  final TextInputAction? action;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final String? errorText;

  const _GlassField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.formatters,
    this.textDirection = TextDirection.rtl,
    this.action,
    this.capitalization = TextCapitalization.none,
    this.onSubmitted,
    this.suffix,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final hasError = errorText != null;
        final Color accent = hasError ? kDanger : kAccent;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: focused || hasError
                      ? accent.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasError
                        ? kDanger.withValues(alpha: 0.7)
                        : focused
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
                        color: focused || hasError
                            ? accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: focused || hasError
                            ? accent
                            : Constans.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        keyboardType: keyboardType,
                        inputFormatters: formatters,
                        textDirection: textDirection,
                        textInputAction: action,
                        textCapitalization: capitalization,
                        onSubmitted: onSubmitted,
                        autocorrect: false,
                        enableSuggestions: false,
                        cursorColor: kAccent,
                        textAlign: textDirection == TextDirection.ltr
                            ? TextAlign.left
                            : TextAlign.right,
                        style: TextStyle(
                          fontFamily: _font,
                          fontSize: 15,
                          color: Constans.textPrimary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          labelText: label,
                          hintText: hint,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            color: focused || hasError
                                ? accent
                                : Constans.textSecondary,
                          ),
                          floatingLabelStyle: TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            color: accent,
                          ),
                          hintStyle: TextStyle(
                            fontFamily: _font,
                            fontSize: 13,
                            color: Constans.textSecondary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (suffix != null) ...[const SizedBox(width: 8), suffix!],
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: hasError
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                        child: Text(
                          errorText!,
                          style: TextStyle(
                            fontFamily: _font,
                            fontSize: 12,
                            color: kDanger,
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════
// انتخابگر بانک
// ═════════════════════════════════════════════
class _BankSelector extends StatelessWidget {
  final List<BankTheme> banks;
  final String? selected; // null = هنوز بانکی مشخص نیست
  final bool locked; // خودکار تشخیص داده شده، دستی لازم نیست
  final ValueChanged<String> onSelect;

  const _BankSelector({
    required this.banks,
    required this.selected,
    required this.locked,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: banks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final b = banks[i];
          final isSelected = b.name == selected;
          // وقتی قفله فقط بانک انتخاب‌شده پررنگ می‌مونه (قبلاً کل لیست کم‌رنگ می‌شد)
          final opacity = (locked && !isSelected) ? 0.4 : 1.0;

          return AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: opacity,
            child: _Pressable(
              onTap: locked
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onSelect(b.name);
                    },
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
                        fontFamily: _font,
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
            ),
          );
        },
      ),
    );
  }
}

class _BankStatus extends StatelessWidget {
  final String? message;
  final bool ok;
  const _BankStatus({required this.message, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? _ok : kDanger;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Icon(
                    ok ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message!,
                      style: TextStyle(
                        fontFamily: _font,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ═════════════════════════════════════════════
// دکمه‌ها
// ═════════════════════════════════════════════

/// کلیک با حس فشردن (کوچیک شدن) به‌جای GestureDetector خشک
class _Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _Pressable({required this.onTap, required this.child});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final bool
  ready; // فرم کامله؟ (دکمه کم‌رنگ می‌مونه ولی کلیک‌پذیره تا دلیل رو بگه)
  final VoidCallback onTap;
  final Color color;

  const _SaveButton({
    required this.saved,
    required this.ready,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: ready ? 1.0 : 0.55,
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
            boxShadow: ready
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
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
                  fontFamily: _font,
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return _Pressable(
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
                fontFamily: _font,
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

/// دکمه‌ی کوچیک زیر کارت (نمایش / کپی)
class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Constans.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: _font,
                fontSize: 12.5,
                color: Constans.textSecondary,
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
/// (مکان مکان‌نما رو حفظ می‌کنه، پس وسط عدد هم می‌شه ویرایش کرد)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _normalizeDigits(newValue.text);

    // چندتا رقم قبل از مکان‌نما بود؟
    final cursor = newValue.selection.baseOffset;
    int digitsBeforeCursor = 0;
    if (cursor < 0) {
      digitsBeforeCursor = normalized.replaceAll(_nonDigit, '').length;
    } else {
      for (int i = 0; i < cursor && i < normalized.length; i++) {
        if (_singleDigit.hasMatch(normalized[i])) digitsBeforeCursor++;
      }
    }

    var digits = normalized.replaceAll(_nonDigit, '');
    if (digits.length > 16) digits = digits.substring(0, 16);
    if (digitsBeforeCursor > digits.length) digitsBeforeCursor = digits.length;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    // مکان‌نمای جدید: بعد از همون تعداد رقم
    int offset = 0;
    int seen = 0;
    while (offset < formatted.length && seen < digitsBeforeCursor) {
      if (formatted[offset] != ' ') seen++;
      offset++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// تاریخ انقضا: فارسی→انگلیسی، فیلتر غیرعدد، فرمت XX/XX
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = _normalizeDigits(newValue.text);
    final digits = normalized.replaceAll(_nonDigit, '');

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
