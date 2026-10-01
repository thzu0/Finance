// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/card_service.dart';
import 'package:finance/services/sms_permission.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class Appsettingsscreen extends StatefulWidget {
  const Appsettingsscreen({super.key});

  @override
  State<Appsettingsscreen> createState() => _AppsettingsscreenState();
}

class _AppsettingsscreenState extends State<Appsettingsscreen> {
  final _s = AppSettings.instance;

  late int _currency = _s.get<int>('currency', 0); // 0 = تومان ، 1 = ریال
  late int _calendar = _s.get<int>('calendar', 0); // 0 = شمسی ، 1 = میلادی
  late int _digits = _s.get<int>('digits', 0); // 0 = فارسی ، 1 = انگلیسی
  late bool _hideAmounts = _s.get<bool>('hide_amounts', false);
  late bool _haptic = _s.get<bool>('haptic', true);
  bool _smsEnabled = false;
  @override
  void initState() {
    super.initState();
    _checkSms();
  }

  Future<void> _checkSms() async {
    final stillGranted = await SmsPermissionService.isStillGranted();
    if (!mounted) return;
    setState(() => _smsEnabled = stillGranted);
  }

  Future<void> _toggleSms(bool enable) async {
    if (!enable) {
      await SmsPermissionService.disable();
      if (!mounted) return;
      setState(() => _smsEnabled = false);
      return;
    }

    if (!CardService.instance.hasCard()) {
      showGlassSnack(context, 'اول توی صفحه‌ی کارت‌ها، کارتت رو ذخیره کن');
      return;
    }

    final result = await SmsPermissionService.request();
    if (!mounted) return;

    switch (result) {
      case SmsPermissionResult.granted:
        setState(() => _smsEnabled = true);
        showGlassSnack(context, 'خواندن خودکار پیامک فعال شد');
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
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'تنظیمات برنامه',
      children: [
        const SectionLabel('نمایش'),
        GlassGroup(
          children: [
            _SegmentSetting(
              icon: Icons.payments_outlined,
              title: 'واحد پول',
              labels: const ['تومان', 'ریال'],
              selected: _currency,
              onChanged: (i) async {
                setState(() => _currency = i);
                await _s.set('currency', i);
              },
            ),
            _SegmentSetting(
              icon: Icons.calendar_today_outlined,
              title: 'زبان',
              labels: const ['فارسی','English'],
              selected: _calendar,
              onChanged: (i) async {
                setState(() => _calendar = i);
                await _s.set('calendar', i);
              },
            ),
            _SegmentSetting(
              icon: Icons.pin_outlined,
              title: 'نوع ارقام',
              labels: const ['فارسی', 'English'],
              selected: _digits,
              onChanged: (i) async {
                setState(() => _digits = i);
                await _s.set('digits', i);
              },
            ),
          ],
        ),
        const SectionLabel('حریم خصوصی و تجربه'),
        GlassGroup(
          children: [
            GlassSwitchTile(
              icon: Icons.visibility_off_outlined,
              title: 'مخفی کردن مبالغ',
              subtitle: 'مبلغ‌ها به‌جای عدد، ••• نشون داده می‌شن',
              value: _hideAmounts,
              onChanged: (v) async {
                setState(() => _hideAmounts = v);
                await _s.set('hide_amounts', v);
              },
            ),
            GlassSwitchTile(
              icon: Icons.vibration,
              title: 'لرزش هنگام لمس',
              value: _haptic,
              onChanged: (v) async {
                setState(() => _haptic = v);
                await _s.set('haptic', v);
              },
            ),
          ],
        ),
        const SectionLabel('پیامک‌ها'),
        GlassGroup(
          children: [
            GlassSwitchTile(
              icon: Icons.sms_outlined,
              title: 'خواندن خودکار پیامک',
              subtitle: _smsEnabled
                  ? 'فعال — تراکنش‌های بانکی خودکار ثبت می‌شن'
                  : 'غیرفعال — برای فعال‌سازی روشن کن',
              value: _smsEnabled,
              onChanged: _toggleSms,
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
        const SectionLabel('داده‌ها'),

        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'خروجی گزارش (PDF)',
              subtitle: 'گردش مالی‌ت رو به‌صورت فایل PDF بگیر',
              onTap: () {
                // TODO: ساخت PDF
                showGlassSnack(context, 'این قابلیت به‌زودی اضافه می‌شه');
              },
            ),
          ],
        ),
      ],
    );
  }
}

// یه تنظیم با انتخاب‌گر چندحالته زیر عنوانش
class _SegmentSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _SegmentSetting({
    required this.icon,
    required this.title,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: kSectionBlue, size: 22),
              const SizedBox(width: 12),
              Text(title, style: glassText(17, color: Constans.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          GlassSegmented(
            labels: labels,
            selected: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
