// ignore: file_names
import 'package:finance/Screen/pages/pin_screen.dart';
import 'package:finance/database/app_setting.dart';

import 'package:finance/database/data_reset.dart';

import 'package:finance/security/biometrics_service.dart';
import 'package:finance/security/pin_service.dart';

import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

class Accountsecurityscreen extends StatefulWidget {
  final String name;
  final String email;

  const Accountsecurityscreen({
    super.key,
    this.name = 'بدون نام',
    this.email = 'email@example.com',
  });

  @override
  State<Accountsecurityscreen> createState() => _AccountsecurityscreenState();
}

class _AccountsecurityscreenState extends State<Accountsecurityscreen> {
  final _s = AppSettings.instance;

  late String _name = _s.get<String>('name', widget.name);
  late String _email = _s.get<String>('email', widget.email);
  late bool _appLock = PinService.isEnabled;
  late bool _biometric = BiometricService.isEnabled;

  @override
  void initState() {
    super.initState();
    if (_biometric) {
      BiometricService.isAvailable().then((ok) {
        if (!ok && mounted) {
          BiometricService.disable();
          setState(() => _biometric = false);
        }
      });
    }
  }

  Future<bool?> _push(PinMode mode, String title, {bool allowBio = false}) =>
      Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PinScreen(mode: mode, title: title, allowBiometric: allowBio),
        ),
      );

  Future<void> _editName() async {
    final v = await showGlassForm(
      context,
      title: 'ویرایش نام',
      fields: [GlassFormField(label: 'نام', initial: _name)],
      validate: (v) => v[0].trim().isEmpty ? 'نام نمی‌تونه خالی باشه' : null,
    );
    if (v == null || !mounted) return;
    final name = v[0].trim();
    await _s.set('name', name);
    if (mounted) setState(() => _name = name);
  }

  Future<void> _editEmail() async {
    final v = await showGlassForm(
      context,
      title: 'ویرایش ایمیل',
      fields: [
        GlassFormField(
          label: 'ایمیل',
          initial: _email,
          keyboard: TextInputType.emailAddress,
        ),
      ],
      validate: (v) => (!v[0].contains('@') || !v[0].contains('.'))
          ? 'ایمیل معتبر نیست'
          : null,
    );
    if (v == null || !mounted) return;
    final email = v[0].trim();
    await _s.set('email', email);
    if (mounted) setState(() => _email = email);
  }

  Future<void> _toggleLock(bool enable) async {
    if (enable) {
      final ok = await _push(PinMode.setup, 'تعیین رمز عددی');
      if (ok == true && mounted) {
        setState(() => _appLock = true);
        showGlassSnack(context, 'قفل برنامه فعال شد');
      }
    } else {
      final ok = await _push(PinMode.verify, 'رمز فعلی رو وارد کن');
      if (ok != true || !mounted) return;
      await PinService.disable();
      await BiometricService.disable();
      if (!mounted) return;
      setState(() {
        _appLock = false;
        _biometric = false;
      });
      showGlassSnack(context, 'قفل برنامه غیرفعال شد');
    }
  }

  Future<void> _changePin() async {
    final verified = await _push(PinMode.verify, 'رمز فعلی رو وارد کن');
    if (verified != true || !mounted) return;
    final ok = await _push(PinMode.setup, 'رمز جدید');
    if (ok == true && mounted) showGlassSnack(context, 'رمز عددی عوض شد');
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (!_appLock) {
      showGlassSnack(context, 'اول قفل عددی رو فعال کن');
      return;
    }
    if (enable) {
      await BiometricService.debugCapabilities(); // ← این خط اضافه شد
      final available = await BiometricService.isAvailable();
      if (!available) {
        if (!mounted) return;
        showGlassSnack(context, 'این دستگاه از اثر انگشت پشتیبانی نمی‌کنه');
        return;
      }
      final enrolled = await BiometricService.availableTypes();
      if (enrolled.isEmpty) {
        if (!mounted) return;
        showGlassSnack(
          context,
          'هیچ اثر انگشتی روی گوشی ثبت نشده؛ از تنظیمات گوشی ثبت کن',
        );
        return;
      }
      final ok = await BiometricService.authenticate(
        reason: 'برای فعال‌سازی اثر انگشت هویتت رو تأیید کن',
      );
      if (!ok || !mounted) return;
      await BiometricService.enable();
      if (!mounted) return;
      setState(() => _biometric = true);
      showGlassSnack(context, 'ورود با اثر انگشت فعال شد');
    } else {
      await BiometricService.disable();
      if (!mounted) return;
      setState(() => _biometric = false);
      showGlassSnack(context, 'ورود با اثر انگشت غیرفعال شد');
    }
  }

  Future<void> _deleteAll() async {
    if (_appLock) {
      final verified = await _push(PinMode.verify, 'برای ادامه رمز رو وارد کن');
      if (verified != true || !mounted) return;
    }
    final ok = await showGlassConfirm(
      context,
      title: 'حذف همه‌ی اطلاعات',
      message:
          'همه‌ی تراکنش‌ها، بودجه‌ها و تنظیماتت پاک می‌شه و برنمی‌گرده. ادامه می‌دی؟',
      confirmText: 'حذف همه',
      danger: true,
    );
    if (!ok || !mounted) return;

    await clearAllData();
    await _s.clearAll();
    if (!mounted) return;
    setState(() {
      _name = widget.name;
      _email = widget.email;
      _appLock = false;
      _biometric = false;
    });
    showGlassSnack(context, 'همه‌ی اطلاعات پاک شد');
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'حساب و امنیت',
      children: [
        const SectionLabel('اطلاعات حساب'),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.person_outline,
              title: 'نام',
              subtitle: _name,
              onTap: _editName,
            ),
            GlassTile(
              icon: Icons.mail_outline,
              title: 'ایمیل',
              subtitle: _email,
              onTap: _editEmail,
            ),
          ],
        ),
        const SectionLabel('امنیت'),
        GlassGroup(
          children: [
            GlassSwitchTile(
              icon: Icons.pin_outlined,
              title: 'قفل برنامه',
              subtitle: 'ورود با رمز عددی ۴ رقمی',
              value: _appLock,
              onChanged: _toggleLock,
            ),
            if (_appLock) ...[
              GlassSwitchTile(
                icon: Icons.fingerprint,
                title: 'ورود با اثر انگشت',
                subtitle: _biometric
                    ? 'فعال — می‌تونی با اثر انگشت هم وارد بشی'
                    : 'برای ورود سریع‌تر فعالش کن',
                value: _biometric,
                onChanged: _toggleBiometric,
              ),
              GlassTile(
                icon: Icons.lock_reset,
                title: 'تغییر رمز عددی',
                onTap: _changePin,
              ),
            ],
          ],
        ),
        const SectionLabel('داده‌ها'),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.delete_outline,
              title: 'حذف همه‌ی اطلاعات',
              subtitle: 'این کار قابل بازگشت نیست',
              color: kDanger,
              onTap: _deleteAll,
            ),
          ],
        ),
      ],
    );
  }
}
