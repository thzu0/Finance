// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class Notificationsscreen extends StatefulWidget {
  const Notificationsscreen({super.key});

  @override
  State<Notificationsscreen> createState() => _NotificationsscreenState();
}

class _NotificationsscreenState extends State<Notificationsscreen> {
  bool _enabled = true;
  bool _daily = true;
  TimeOfDay _time = const TimeOfDay(hour: 21, minute: 0);
  bool _budgetAlert = true;
  bool _tips = false;
  bool _weekly = true;
  bool _monthly = true;

  String get _timeText =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'
          .farsiNumber;

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.dark(primary: kAccent)),
        child: child!,
      ),
    );
    if (t == null || !mounted) return;
    setState(() => _time = t);
    // TODO: زمان‌بندی دوباره‌ی یادآوری
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'اعلان‌ها',
      children: [
        const SizedBox(height: 4),
        GlassGroup(
          children: [
            GlassSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'دریافت اعلان‌ها',
              subtitle: 'خاموش کردنش همه‌ی اعلان‌ها رو قطع می‌کنه',
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ],
        ),
        // وقتی اعلان‌ها خاموشه، بقیه کم‌رنگ و غیرقابل لمس می‌شن
        Opacity(
          opacity: _enabled ? 1 : 0.4,
          child: IgnorePointer(
            ignoring: !_enabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('یادآوری'),
                GlassGroup(
                  children: [
                    GlassSwitchTile(
                      icon: Icons.edit_calendar_outlined,
                      title: 'یادآوری ثبت تراکنش‌ها',
                      subtitle: 'هر روز یادت می‌ندازه خرج‌هات رو ثبت کنی',
                      value: _daily,
                      onChanged: (v) => setState(() => _daily = v),
                    ),
                    if (_daily)
                      GlassTile(
                        icon: Icons.access_time,
                        title: 'ساعت یادآوری',
                        onTap: _pickTime,
                        trailing: Text(
                          _timeText,
                          style: glassText(16, color: Constans.textSecondary),
                        ),
                      ),
                  ],
                ),
                const SectionLabel('هشدارها'),
                GlassGroup(
                  children: [
                    GlassSwitchTile(
                      icon: Icons.warning_amber_rounded,
                      title: 'هشدار بودجه',
                      subtitle: 'وقتی به ۸۰٪ سقف یه دسته رسیدی',
                      value: _budgetAlert,
                      onChanged: (v) => setState(() => _budgetAlert = v),
                    ),
                    GlassSwitchTile(
                      icon: Icons.lightbulb_outline,
                      title: 'پیشنهادهای هوشمند',
                      subtitle: 'نکته‌هایی برای کم کردن خرج',
                      value: _tips,
                      onChanged: (v) => setState(() => _tips = v),
                    ),
                  ],
                ),
                const SectionLabel('گزارش‌ها'),
                GlassGroup(
                  children: [
                    GlassSwitchTile(
                      icon: Icons.bar_chart,
                      title: 'گزارش هفتگی',
                      subtitle: 'خلاصه‌ی خرج هفته، آخر هر هفته',
                      value: _weekly,
                      onChanged: (v) => setState(() => _weekly = v),
                    ),
                    GlassSwitchTile(
                      icon: Icons.calendar_month_outlined,
                      title: 'خلاصه‌ی ماهانه',
                      subtitle: 'مرور خرج و درآمد ماه، اول هر ماه',
                      value: _monthly,
                      onChanged: (v) => setState(() => _monthly = v),
                    ),
                  ],
                ),
                // TODO: زمان‌بندی واقعی اعلان‌ها (مثلا با flutter_local_notifications)
              ],
            ),
          ),
        ),
      ],
    );
  }
}
