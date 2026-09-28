import 'package:finance/Screen/pages/pin_screen.dart';
import 'package:finance/database/data_reset.dart';
import 'package:finance/security/pin_service.dart';
import 'package:flutter/material.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  /// مهلت برگشت: اگه کاربر بیشتر از این مدت بیرون بوده، دوباره قفل می‌شه.
  static const Duration _grace = Duration(seconds: 30);

  bool _locked = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = PinService.isEnabled;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // اگه قفل روی صفحه‌ست (یعنی کاربر داره رمز یا اثر انگشت می‌زنه)،
    // تغییرات lifecycle مربوط به خود دیالوگ اثر انگشت رو نادیده بگیر.
    // وگرنه بعد از تأیید موفق، دوباره قفل می‌شه و PinScreen برمی‌گرده.
    if (_locked) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pausedAt ??= DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final p = _pausedAt;
        _pausedAt = null;
        if (p == null) return;
        if (!PinService.isEnabled) return;
        final away = DateTime.now().difference(p);
        if (away > _grace) {
          setState(() => _locked = true);
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // صفحه‌ی زیرین دست‌نخورده — بعد از تأیید همون‌جا برمی‌گرده
        widget.child,
        if (_locked)
          Positioned.fill(
            child: PinScreen(
              key: const ValueKey('lock'),
              mode: PinMode.verify,
              title: 'قفل برنامه',
              allowBiometric: true,
              onSuccess: () => setState(() => _locked = false),
              onForgot: () async {
                await clearAllData();
                await PinService.disable();
                if (mounted) setState(() => _locked = false);
              },
            ),
          ),
      ],
    );
  }
}
