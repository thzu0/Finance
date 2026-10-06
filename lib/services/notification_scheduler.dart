import 'package:finance/database/app_setting.dart';
import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_service.dart' as db;

class NotificationScheduler {
  NotificationScheduler._();
  static final NotificationScheduler instance = NotificationScheduler._();

  final _s = AppSettings.instance;
  final _n = LocalPushService.instance;

  // ═══════════════════════════════════════════
  // ۱) یادآور روزانه
  // ═══════════════════════════════════════════
  Future<void> syncDailyReminder() async {
    final enabled =
        _s.get<bool>('notif_enabled', true) &&
        _s.get<bool>('notif_daily', true);

    if (!enabled) {
      await _n.cancel(LocalPushService.idDailyReminder);
      return;
    }

    final hour = _s.get<int>('notif_daily_hour', 21);
    final minute = _s.get<int>('notif_daily_minute', 0);

    await _n.scheduleDaily(
      id: LocalPushService.idDailyReminder,
      title: 'یادآوری ثبت تراکنش‌ها',
      body: 'امروز چه خرج‌هایی داشتی؟ بیا ثبتشون کن',
      payload: LocalPushService.payloadDaily,
      hour: hour,
      minute: minute,
    );
  }

  Future<void> fireDailyReminder() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_daily', true)) return;

    const title = 'یادآوری ثبت تراکنش‌ها';
    const body = 'امروز چه خرج‌هایی داشتی؟ بیا ثبتشون کن';

    await db.NotificationService.create(
      title: title,
      body: body,
      type: 'daily',
    );

    await _n.showNow(
      id: LocalPushService.idDailyReminder,
      title: title,
      body: body,
      payload: LocalPushService.payloadDaily,
    );
  }

  // ═══════════════════════════════════════════
  // ۲) هشدار بودجه
  // ═══════════════════════════════════════════
  Future<void> checkBudgetAlert() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_budget_alert', true)) return;

    // TODO: منطق چک بودجه — با اسکیمای واقعی دیتابیس پر شود
  }

  Future<void> notifyBudgetReached(String categoryName, double percent) async {
    final pct = (percent * 100).round();
    final title = 'هشدار بودجه';
    final body = 'به $pct٪ سقف دسته‌ی «$categoryName» رسیدی';

    await db.NotificationService.create(
      title: title,
      body: body,
      type: 'budget',
      payload: categoryName,
    );

    await _n.showNow(
      id: LocalPushService.idBudgetAlert,
      title: title,
      body: body,
      payload: LocalPushService.payloadBudget,
    );
  }

  // ═══════════════════════════════════════════
  // ۳) گزارش هفتگی
  // ═══════════════════════════════════════════
  Future<void> syncWeeklyReport() async {
    final enabled =
        _s.get<bool>('notif_enabled', true) &&
        _s.get<bool>('notif_weekly', true);

    if (!enabled) {
      await _n.cancel(LocalPushService.idWeeklyReport);
      return;
    }

    await _n.scheduleWeekly(
      id: LocalPushService.idWeeklyReport,
      title: 'گزارش هفتگی',
      body: 'خلاصه‌ی خرج این هفته‌ت آماده‌ست',
      payload: LocalPushService.payloadWeekly,
      dayOfWeek: DateTime.saturday,
      hour: 20,
      minute: 0,
    );
  }

  Future<void> fireWeeklyReport() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_weekly', true)) return;

    const title = 'گزارش هفتگی';
    const body = 'این هفته چقدر خرج کردی؟ ببین';

    await db.NotificationService.create(
      title: title,
      body: body,
      type: 'weekly',
    );

    await _n.showNow(
      id: LocalPushService.idWeeklyReport,
      title: title,
      body: body,
      payload: LocalPushService.payloadWeekly,
    );
  }

  // ═══════════════════════════════════════════
  // ۴) گزارش ماهانه
  // ═══════════════════════════════════════════
  Future<void> syncMonthlyReport() async {
    final enabled =
        _s.get<bool>('notif_enabled', true) &&
        _s.get<bool>('notif_monthly', true);

    if (!enabled) {
      await _n.cancel(LocalPushService.idMonthlyReport);
      return;
    }

    await _n.scheduleMonthly(
      id: LocalPushService.idMonthlyReport,
      title: 'خلاصه‌ی ماهانه',
      body: 'مرور خرج و درآمد ماه گذشته‌ت آماده‌ست',
      payload: LocalPushService.payloadMonthly,
      dayOfMonth: 1,
      hour: 10,
      minute: 0,
    );
  }

  Future<void> fireMonthlyReport() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_monthly', true)) return;

    const title = 'خلاصه‌ی ماهانه';
    const body = 'مرور خرج و درآمد ماه گذشته‌ت آماده‌ست';

    await db.NotificationService.create(
      title: title,
      body: body,
      type: 'monthly',
    );

    await _n.showNow(
      id: LocalPushService.idMonthlyReport,
      title: title,
      body: body,
      payload: LocalPushService.payloadMonthly,
    );
  }

  // ═══════════════════════════════════════════
  // همگام‌سازی کل
  // ═══════════════════════════════════════════
  Future<void> syncAll() async {
    await syncDailyReminder();
    await syncWeeklyReport();
    await syncMonthlyReport();
  }
}
