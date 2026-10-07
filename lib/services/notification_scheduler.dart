import 'package:drift/drift.dart'
    show ComparableExpr, BooleanExpressionOperators;
import 'package:finance/database/app_setting.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_service.dart' as db;
import 'package:finance/database/transaction_repository.dart';

import 'package:finance/extentions/extentions.dart';

import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:finance/services/smart_suggestion_service.dart';

class NotificationScheduler {
  NotificationScheduler._();
  static final NotificationScheduler instance = NotificationScheduler._();

  final _s = AppSettings.instance;
  final _n = LocalPushService.instance;

  // ═══════════════════════════════════════════
  // ثبت خودکار نوتیف‌هایی که زمانشون گذشته
  // ═══════════════════════════════════════════
  /// اگه امروز زمان یادآور گذشته ولی توی تاریخچه ثبت نشده، ثبتش کن
  Future<void> syncMissedDailyReminder() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_daily', true)) return;

    final hour = _s.get<int>('notif_daily_hour', 21);
    final minute = _s.get<int>('notif_daily_minute', 0);

    final now = DateTime.now();
    final todayScheduled = DateTime(now.year, now.month, now.day, hour, minute);

    // اگه وقت امروز نرسیده، کاری نکن
    if (now.isBefore(todayScheduled)) return;

    // چک کن آیا امروز یه نوتیف daily ثبت شده
    final startOfDay = DateTime(now.year, now.month, now.day);
    final existing =
        await (database.select(database.notifications)..where(
              (n) =>
                  n.type.equals('daily') &
                  n.createdAt.isBiggerOrEqualValue(startOfDay),
            ))
            .get();

    if (existing.isNotEmpty) return;

    await db.NotificationService.create(
      title: 'یادآوری ثبت تراکنش‌ها',
      body: 'امروز چه خرج‌هایی داشتی؟ بیا ثبتشون کن',
      type: 'daily',
    );
  }

  /// همین کار برای گزارش هفتگی
  Future<void> syncMissedWeeklyReport() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_weekly', true)) return;

    final now = DateTime.now();
    // آخرین شنبه ساعت ۲۰:۰۰
    var scheduled = DateTime(now.year, now.month, now.day, 20, 0);
    while (scheduled.weekday != DateTime.saturday) {
      scheduled = scheduled.subtract(const Duration(days: 1));
    }
    if (scheduled.isAfter(now)) {
      scheduled = scheduled.subtract(const Duration(days: 7));
    }

    final existing =
        await (database.select(database.notifications)..where(
              (n) =>
                  n.type.equals('weekly') &
                  n.createdAt.isBiggerOrEqualValue(scheduled),
            ))
            .get();

    if (existing.isNotEmpty) return;

    // 🆕 متن واقعی رو حساب کن
    final t = await _buildWeeklyText();

    await db.NotificationService.create(
      title: t.title,
      body: t.body,
      type: 'weekly',
    );
  }

  /// و برای خلاصه‌ی ماهانه
  Future<void> syncMissedMonthlyReport() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_monthly', true)) return;

    final now = DateTime.now();
    final firstOfMonth = DateTime(now.year, now.month, 1, 10, 0);

    // اگه اولین روز ماه ساعت ۱۰ نرسیده، کاری نکن
    if (now.isBefore(firstOfMonth)) return;

    final existing =
        await (database.select(database.notifications)..where(
              (n) =>
                  n.type.equals('monthly') &
                  n.createdAt.isBiggerOrEqualValue(firstOfMonth),
            ))
            .get();

    if (existing.isNotEmpty) return;

    // 🆕 متن واقعی رو حساب کن
    final t = await _buildMonthlyText();

    await db.NotificationService.create(
      title: t.title,
      body: t.body,
      type: 'monthly',
    );
  }

  /// همه‌ی missedها رو چک کن
  Future<void> syncMissedAll() async {
    await syncMissedDailyReminder();
    await syncMissedWeeklyReport();
    await syncMissedMonthlyReport();
    await syncMissedTips(); // 🆕
  }

  // ─────────────────────────────────────────
  // فرمت پول: ۲.۳ میلیون تومان / ۲۵۰ هزار تومان / ۵۰۰ تومان
  // ─────────────────────────────────────────
  String _money(double amount) {
    if (amount <= 0) return '۰ تومان';
    if (amount >= 1000000) {
      final m = (amount / 1000000).toStringAsFixed(1);
      return '${m.farsiNumber} میلیون تومان';
    }
    if (amount >= 1000) {
      final k = (amount / 1000).toStringAsFixed(0);
      return '${k.farsiNumber} هزار تومان';
    }
    return '${amount.toStringAsFixed(0).farsiNumber} تومان';
  }

  // ─────────────────────────────────────────
  // متن پویا برای گزارش هفتگی
  // ─────────────────────────────────────────
  Future<({String title, String body})> _buildWeeklyText() async {
    final w = await getWeekSummary();

    if (w.expense == 0) {
      return (title: 'گزارش هفتگی', body: 'هفته‌ی قبل خرجی ثبت نکردی');
    }

    if (w.prevExpense == 0) {
      return (
        title: 'گزارش هفتگی',
        body: 'هفته‌ی قبل ${_money(w.expense)} خرج کردی',
      );
    }

    final change = ((w.expense - w.prevExpense) / w.prevExpense) * 100;

    if (change <= -5) {
      final pct = change.abs().toStringAsFixed(0).farsiNumber;
      return (
        title: 'گزارش هفتگی',
        body:
            'هفته‌ی قبل ${_money(w.expense)} خرج کردی، $pct٪ کمتر از هفته‌ی قبل‌تر',
      );
    }

    if (change >= 10) {
      final pct = change.abs().toStringAsFixed(0).farsiNumber;
      return (
        title: 'گزارش هفتگی',
        body:
            'هفته‌ی قبل ${_money(w.expense)} خرج کردی، $pct٪ بیشتر از هفته‌ی قبل‌تر',
      );
    }

    return (
      title: 'گزارش هفتگی',
      body:
          'هفته‌ی قبل ${_money(w.expense)} خرج کردی، تقریباً مثل هفته‌ی قبل‌تر',
    );
  }

  // ─────────────────────────────────────────
  // متن پویا برای خلاصه‌ی ماهانه
  // ─────────────────────────────────────────
  Future<({String title, String body})> _buildMonthlyText() async {
    // ماه گذشته‌ی شمسی نسبت به امروز
    final now = DateTime.now();
    final j = Jalali.fromDateTime(now);
    final prevRef = j.month == 1
        ? Jalali(j.year - 1, 12, 15).toDateTime()
        : Jalali(j.year, j.month - 1, 15).toDateTime();

    final s = await getMonthSummary(prevRef);

    if (s.income == 0 && s.expense == 0) {
      return (title: 'خلاصه‌ی ماهانه', body: 'ماه گذشته تراکنشی ثبت نکردی');
    }

    final savings = s.income - s.expense;
    final exp = _money(s.expense);
    final inc = _money(s.income);

    if (savings > 0) {
      return (
        title: 'خلاصه‌ی ماهانه',
        body:
            'ماه گذشته $exp خرج و $inc درآمد داشتی، ${_money(savings)} پس‌انداز',
      );
    }

    if (savings < 0) {
      return (
        title: 'خلاصه‌ی ماهانه',
        body:
            'ماه گذشته $exp خرج و $inc درآمد داشتی، ${_money(savings.abs())} کسری',
      );
    }

    return (
      title: 'خلاصه‌ی ماهانه',
      body: 'ماه گذشته $exp خرج و $inc درآمد داشتی، دقیقاً سر به سر',
    );
  }

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

    final t = await _buildWeeklyText();

    await db.NotificationService.create(
      title: t.title,
      body: t.body,
      type: 'weekly',
    );

    await _n.showNow(
      id: LocalPushService.idWeeklyReport,
      title: t.title,
      body: t.body,
      payload: '${LocalPushService.payloadWeekly}|${t.title}|${t.body}',
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

    final t = await _buildMonthlyText();

    await db.NotificationService.create(
      title: t.title,
      body: t.body,
      type: 'monthly',
    );

    await _n.showNow(
      id: LocalPushService.idMonthlyReport,
      title: t.title,
      body: t.body,
      payload: '${LocalPushService.payloadMonthly}|${t.title}|${t.body}',
    );
  }

  // ═══════════════════════════════════════════
  // ۵) پیشنهادهای هوشمند
  // ═══════════════════════════════════════════
  Future<void> syncTips() async {
    final enabled =
        _s.get<bool>('notif_enabled', true) &&
        _s.get<bool>('notif_tips', false);

    if (!enabled) {
      await _n.cancel(LocalPushService.idTips);
      return;
    }

    await _n.scheduleWeekly(
      id: LocalPushService.idTips,
      title: 'پیشنهاد هوشمند',
      body: 'یه نکته برای کم کردن خرج',
      payload: LocalPushService.payloadTips,
      dayOfWeek: DateTime.tuesday,
      hour: 20,
      minute: 0,
    );
  }

  Future<void> fireTips() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_tips', false)) return;
    await SmartSuggestionService.sendNow();
  }

  Future<void> syncMissedTips() async {
    if (!_s.get<bool>('notif_enabled', true)) return;
    if (!_s.get<bool>('notif_tips', false)) return;
    await SmartSuggestionService.sendNow();
  }

  // ═══════════════════════════════════════════
  // همگام‌سازی کل
  // ═══════════════════════════════════════════
  Future<void> syncAll() async {
    await syncDailyReminder();
    await syncWeeklyReport();
    await syncMonthlyReport();
    await syncTips(); // 🆕
  }
}
