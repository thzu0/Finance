// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/Screen/setting/notification_history_screen.dart'
    show NotificationsHistoryScreen;

import 'package:finance/database/app_setting.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_scheduler.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class Notificationsscreen extends StatefulWidget {
  const Notificationsscreen({super.key});

  @override
  State<Notificationsscreen> createState() => _NotificationsscreenState();
}

class _NotificationsscreenState extends State<Notificationsscreen> {
  final _s = AppSettings.instance;

  late bool _enabled = _s.get<bool>('notif_enabled', true);
  late bool _daily = _s.get<bool>('notif_daily', true);
  late int _hour = _s.get<int>('notif_daily_hour', 21);
  late int _minute = _s.get<int>('notif_daily_minute', 0);
  late bool _budgetAlert = _s.get<bool>('notif_budget_alert', true);
  late bool _tips = _s.get<bool>('notif_tips', false);
  late bool _weekly = _s.get<bool>('notif_weekly', true);
  late bool _monthly = _s.get<bool>('notif_monthly', true);

  TimeOfDay get _time => TimeOfDay(hour: _hour, minute: _minute);

  String get _timeText =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}'
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
    setState(() {
      _hour = t.hour;
      _minute = t.minute;
    });
    await _s.set('notif_daily_hour', _hour);
    await _s.set('notif_daily_minute', _minute);

    // 🆕 زمان‌بندی مجدد یادآور روزانه
    await NotificationScheduler.instance.syncDailyReminder();
  }

  void _openHistory() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: const NotificationsHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'اعلان‌ها',
      children: [
        const SizedBox(height: 2),
        const SectionLabel('مدیریت'),
        GlassGroup(
          children: [
            GlassSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'دریافت اعلان‌ها',
              subtitle: 'خاموش کردنش همه‌ی اعلان‌ها رو قطع می‌کنه',
              value: _enabled,
              onChanged: (v) async {
                setState(() => _enabled = v);
                await _s.set('notif_enabled', v);
                // 🆕 اگه روشن شد همه‌ی زمان‌بندی‌ها رو ثبت کن، اگه خاموش شد همه رو لغو کن
                if (v) {
                  await NotificationScheduler.instance.syncAll();
                } else {
                  await LocalPushService.instance.cancelAll();
                }
              },
            ),
            GlassTile(
              icon: Icons.history,
              title: 'تاریخچه‌ی اعلان‌ها',
              subtitle: 'همه‌ی اعلان‌های قبلی رو ببین',
              onTap: _openHistory,
            ),
          ],
        ),

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
                      onChanged: (v) async {
                        setState(() => _daily = v);
                        await _s.set('notif_daily', v);
                        // 🆕
                        await NotificationScheduler.instance
                            .syncDailyReminder();
                      },
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
                      onChanged: (v) async {
                        setState(() => _budgetAlert = v);
                        await _s.set('notif_budget_alert', v);
                        // 🆕 (اختیاری — چک بودجه توسط Workmanager هر ۱۵ دقیقه اجرا می‌شه)
                      },
                    ),
                    GlassSwitchTile(
                      icon: Icons.lightbulb_outline,
                      title: 'پیشنهادهای هوشمند',
                      subtitle: 'نکته‌هایی برای کم کردن خرج',
                      value: _tips,
                      onChanged: (v) async {
                        setState(() => _tips = v);
                        await _s.set('notif_tips', v);
                      },
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
                      onChanged: (v) async {
                        setState(() => _weekly = v);
                        await _s.set('notif_weekly', v);
                        // 🆕
                        await NotificationScheduler.instance.syncWeeklyReport();
                      },
                    ),
                    GlassSwitchTile(
                      icon: Icons.calendar_month_outlined,
                      title: 'خلاصه‌ی ماهانه',
                      subtitle: 'مرور خرج و درآمد ماه، اول هر ماه',
                      value: _monthly,
                      onChanged: (v) async {
                        setState(() => _monthly = v);
                        await _s.set('notif_monthly', v);
                        // 🆕
                        await NotificationScheduler.instance
                            .syncMonthlyReport();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
