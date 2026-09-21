// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class Appsettingsscreen extends StatefulWidget {
  const Appsettingsscreen({super.key});

  @override
  State<Appsettingsscreen> createState() => _AppsettingsscreenState();
}

class _AppsettingsscreenState extends State<Appsettingsscreen> {
  int _currency = 0; // 0 = تومان ، 1 = ریال
  int _calendar = 0; // 0 = شمسی ، 1 = میلادی
  int _digits = 0; // 0 = فارسی ، 1 = انگلیسی
  bool _hideAmounts = false;
  bool _haptic = true;

  // TODO: همه‌ی این تنظیم‌ها رو جایی ذخیره کن (مثلا shared_preferences)

  Future<void> _clearData() async {
    final ok = await showGlassConfirm(
      context,
      title: 'پاک کردن همه‌ی داده‌ها',
      message:
          'همه‌ی تراکنش‌ها، بودجه‌ها و هدف‌هات حذف می‌شن و برنمی‌گردن. مطمئنی؟',
      confirmText: 'پاک کن',
      danger: true,
    );
    if (!ok || !mounted) return;
    // TODO: پاک کردن واقعی داده‌ها
    showGlassSnack(context, 'همه‌ی داده‌ها پاک شد');
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
              onChanged: (i) => setState(() => _currency = i),
            ),
            _SegmentSetting(
              icon: Icons.calendar_today_outlined,
              title: 'تقویم',
              labels: const ['شمسی', 'میلادی'],
              selected: _calendar,
              onChanged: (i) => setState(() => _calendar = i),
            ),
            _SegmentSetting(
              icon: Icons.pin_outlined,
              title: 'نوع ارقام',
              labels: const ['فارسی', 'English'],
              selected: _digits,
              onChanged: (i) => setState(() => _digits = i),
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
              onChanged: (v) => setState(() => _hideAmounts = v),
            ),
            GlassSwitchTile(
              icon: Icons.vibration,
              title: 'لرزش هنگام لمس',
              value: _haptic,
              onChanged: (v) => setState(() => _haptic = v),
            ),
          ],
        ),
        const SectionLabel('داده‌ها'),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.cloud_upload_outlined,
              title: 'پشتیبان‌گیری',
              subtitle: 'ذخیره‌ی نسخه‌ی پشتیبان از اطلاعات',
              onTap: () {
                // TODO: پشتیبان‌گیری
                showGlassSnack(context, 'این قابلیت به‌زودی اضافه می‌شه');
              },
            ),
            GlassTile(
              icon: Icons.delete_sweep_outlined,
              title: 'پاک کردن همه‌ی داده‌ها',
              subtitle: 'این کار قابل بازگشت نیست',
              color: kDanger,
              onTap: _clearData,
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
