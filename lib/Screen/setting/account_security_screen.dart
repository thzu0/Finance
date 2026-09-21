// ignore: file_names
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class Accountsecurityscreen extends StatefulWidget {
  final String name;
  final String email;

  const Accountsecurityscreen({
    super.key,
    this.name = 'امیر',
    this.email = 'amir@email.com',
  });

  @override
  State<Accountsecurityscreen> createState() => _AccountsecurityscreenState();
}

class _AccountsecurityscreenState extends State<Accountsecurityscreen> {
  late String _name = widget.name;
  late String _email = widget.email;
  bool _appLock = false;
  bool _biometric = false;

  Future<void> _editName() async {
    final v = await showGlassForm(
      context,
      title: 'ویرایش نام',
      fields: [GlassFormField(label: 'نام', initial: _name)],
      validate: (v) => v[0].isEmpty ? 'نام نمی‌تونه خالی باشه' : null,
    );
    if (v == null || !mounted) return;
    setState(() => _name = v[0]);
    // TODO: ذخیره‌ی نام
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
    setState(() => _email = v[0]);
    // TODO: ذخیره‌ی ایمیل
  }

  Future<void> _changePassword() async {
    final v = await showGlassForm(
      context,
      title: 'تغییر رمز عبور',
      confirmText: 'تغییر بده',
      fields: const [
        GlassFormField(label: 'رمز فعلی', obscure: true),
        GlassFormField(label: 'رمز جدید', obscure: true),
        GlassFormField(label: 'تکرار رمز جدید', obscure: true),
      ],
      validate: (v) {
        if (v.any((e) => e.isEmpty)) return 'همه‌ی فیلدها رو پر کن';
        if (v[1].length < 6) return 'رمز جدید حداقل ۶ کاراکتر باشه';
        if (v[1] != v[2]) return 'تکرار رمز با رمز جدید یکی نیست';
        return null;
      },
    );
    if (v == null || !mounted) return;
    // TODO: تغییر واقعی رمز
    showGlassSnack(context, 'رمز عبور تغییر کرد');
  }

  Future<void> _logout() async {
    final ok = await showGlassConfirm(
      context,
      title: 'خروج از حساب',
      message: 'مطمئنی می‌خوای از حسابت خارج بشی؟',
      confirmText: 'خروج',
      danger: true,
    );
    if (!ok || !mounted) return;
    // TODO: پاک کردن نشست و رفتن به صفحه‌ی ورود
    showGlassSnack(context, 'از حساب خارج شدی');
  }

  Future<void> _deleteAccount() async {
    final ok = await showGlassConfirm(
      context,
      title: 'حذف حساب',
      message:
          'با حذف حساب، همه‌ی اطلاعاتت پاک می‌شه و برنمی‌گرده. ادامه می‌دی؟',
      confirmText: 'حذف حساب',
      danger: true,
    );
    if (!ok || !mounted) return;
    // TODO: حذف واقعی حساب
    showGlassSnack(context, 'درخواست حذف حساب ثبت شد');
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
            GlassTile(
              icon: Icons.lock_outline,
              title: 'تغییر رمز عبور',
              onTap: _changePassword,
            ),
            GlassSwitchTile(
              icon: Icons.pin_outlined,
              title: 'قفل برنامه',
              subtitle: 'ورود با رمز عددی',
              value: _appLock,
              onChanged: (v) {
                setState(() => _appLock = v);
                // TODO: صفحه‌ی تعیین رمز عددی
              },
            ),
            GlassSwitchTile(
              icon: Icons.fingerprint,
              title: 'ورود با اثر انگشت',
              value: _biometric,
              onChanged: (v) {
                setState(() => _biometric = v);
                // TODO: احراز هویت بیومتریک (مثلا با پکیج local_auth)
              },
            ),
          ],
        ),
        const SectionLabel('حساب'),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.logout,
              title: 'خروج از حساب',
              color: kDanger,
              onTap: _logout,
            ),
            GlassTile(
              icon: Icons.delete_outline,
              title: 'حذف حساب',
              subtitle: 'این کار قابل بازگشت نیست',
              color: kDanger,
              onTap: _deleteAccount,
            ),
          ],
        ),
      ],
    );
  }
}
