// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/Constans/scaffold_background_page.dart';
import 'package:finance/database/app_setting.dart';

import 'package:finance/security/biometrics_service.dart';
import 'package:finance/security/pin_service.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PinMode { setup, verify }

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final String title;
  final VoidCallback? onSuccess;
  final Future<void> Function()? onForgot;
  final bool allowBiometric;

  const PinScreen({
    super.key,
    required this.mode,
    required this.title,
    this.onSuccess,
    this.onForgot,
    this.allowBiometric = false,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const int _len = 4;
  String _entry = '';
  String? _first;
  String? _error;
  int _fails = 0;
  DateTime? _lockedUntil;
  bool _bioTried = false;

  String get _hint {
    if (widget.mode == PinMode.verify) return 'رمز رو وارد کن';
    return _first == null ? 'رمز جدید رو وارد کن' : 'رمز رو دوباره وارد کن';
  }

  bool get _canUseBio =>
      widget.allowBiometric &&
      widget.mode == PinMode.verify &&
      BiometricService.isEnabled;

  @override
  void initState() {
    super.initState();
    if (_canUseBio) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
    }
  }

  void _buzz([bool heavy = false]) {
    if (!AppSettings.instance.get<bool>('haptic', true)) return;
    heavy ? HapticFeedback.heavyImpact() : HapticFeedback.selectionClick();
  }

  void _done() {
    if (widget.onSuccess != null) {
      widget.onSuccess!();
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _tryBiometric() async {
    if (_bioTried) return;
    _bioTried = true;
    final ok = await BiometricService.authenticate();
    if (!mounted) return;
    if (ok) {
      _done();
    } else {
      setState(() {});
    }
  }

  void _press(String d) {
    if (_lockedUntil != null) {
      if (DateTime.now().isBefore(_lockedUntil!)) return;
      _lockedUntil = null;
      _fails = 0;
      _error = null;
    }
    if (_entry.length >= _len) return;
    _buzz();
    setState(() {
      _entry += d;
      _error = null;
    });
    if (_entry.length == _len) _submit();
  }

  void _backspace() {
    if (_entry.isEmpty) return;
    setState(() => _entry = _entry.substring(0, _entry.length - 1));
  }

  Future<void> _submit() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    if (widget.mode == PinMode.verify) {
      if (PinService.verify(_entry)) {
        _done();
        return;
      }
      _fails++;
      _buzz(true);
      setState(() {
        _entry = '';
        if (_fails >= 5) {
          _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
          _error = 'خیلی اشتباه زدی؛ ۳۰ ثانیه صبر کن';
        } else {
          _error = 'رمز اشتباهه';
        }
      });
      return;
    }

    if (_first == null) {
      setState(() {
        _first = _entry;
        _entry = '';
        _error = null;
      });
      return;
    }
    if (_first == _entry) {
      await PinService.setPin(_entry);
      if (mounted) _done();
    } else {
      _buzz(true);
      setState(() {
        _first = null;
        _entry = '';
        _error = 'دو رمز یکی نبودن؛ از اول وارد کن';
      });
    }
  }

  Future<void> _forgot() async {
    final ok = await showGlassConfirm(
      context,
      title: 'فراموشی رمز',
      message:
          'راهی برای بازیابی رمز نیست. برای ادامه باید همه‌ی داده‌های برنامه پاک بشه. ادامه می‌دی؟',
      confirmText: 'پاک کن و ادامه',
      danger: true,
    );
    if (!ok || !mounted) return;
    await widget.onForgot!();
  }

  Widget _key(String k) {
    if (k.isEmpty) return const SizedBox(width: 76, height: 76);
    final isBack = k == '<';
    return GestureDetector(
      onTap: isBack ? _backspace : () => _press(k),
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: isBack ? 0 : 0.07),
          border: isBack
              ? null
              : Border.all(color: kAccent.withValues(alpha: 0.25)),
        ),
        child: isBack
            ? Icon(Icons.backspace_outlined, color: Constans.textSecondary)
            : Text(
                toPersianDigits(k),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Constans.textPrimary,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];

    return PopScope(
      canPop: widget.onSuccess == null,
      child: Scaffold(
        backgroundColor: Constans.background,
        body: AppGlowBackground(
          child: SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    child: Stack(
                      children: [
                        if (widget.onSuccess == null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_forward,
                                color: Constans.textPrimary,
                              ),
                            ),
                          ),
                        if (_canUseBio)
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: IconButton(
                              onPressed: _tryBiometric,
                              icon: const Icon(
                                Icons.fingerprint,
                                size: 30,
                                color: kAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _canUseBio ? Icons.fingerprint : Icons.lock_outline,
                    size: 40,
                    color: kSectionBlue,
                  ),
                  const SizedBox(height: 14),
                  Text(widget.title, style: glassText(22)),
                  const SizedBox(height: 6),
                  Text(
                    _hint,
                    style: glassText(15, color: Constans.textSecondary),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_len, (i) {
                      final filled = i < _entry.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 9),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? kAccent : Colors.transparent,
                          border: Border.all(
                            color: filled
                                ? kAccent
                                : Constans.textSecondary.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(
                    height: 34,
                    child: Center(
                      child: Text(
                        _error ?? '',
                        style: glassText(14, color: kDanger),
                      ),
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Column(
                      children: [
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final k in r)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: _key(k),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.mode == PinMode.verify && widget.onForgot != null)
                    TextButton(
                      onPressed: _forgot,
                      child: Text(
                        'رمز رو فراموش کردم',
                        style: glassText(14, color: Constans.textSecondary),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
