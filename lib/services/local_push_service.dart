import 'package:drift/drift.dart' show OrderingTerm;
import 'package:finance/database/database_provider.dart';
import 'package:finance/services/notification_service.dart' as db;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalPushService {
  LocalPushService._();

  static final LocalPushService instance = LocalPushService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ── کانال Android ──
  static const String _channelId = 'finance_app_channel';
  static const String _channelName = 'اعلان‌های مالی';
  static const String _channelDesc = 'یادآورها، هشدار بودجه و گزارش‌ها';

  // ── شناسه‌های ثابت ──
  static const int idDailyReminder = 100;
  static const int idWeeklyReport = 101;
  static const int idMonthlyReport = 102;
  static const int idBudgetAlert = 103;
  static const int idTips = 104;

  // ── payloadها ──
  static const String payloadDaily = 'daily_reminder';
  static const String payloadWeekly = 'weekly_report';
  static const String payloadMonthly = 'monthly_report';
  static const String payloadBudget = 'budget_alert';
  static const String payloadTips = 'tips';

  Future<void> init() async {
    if (_initialized) return;

    // ── timezone ──
    tz.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Tehran'));
    }

    // ── تنظیمات اولیه ──
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // ── کانال Android ──
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
      ),
    );

    // ── مجوز Android ──
    await androidPlugin?.requestNotificationsPermission();

    // ── مجوز iOS ──
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  // ─────────────────────────────────────────
  // نمایش فوری
  // ─────────────────────────────────────────
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(),
      payload: payload,
    );
  }

  // ─────────────────────────────────────────
  // زمان‌بندی روزانه
  // ─────────────────────────────────────────
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int hour,
    required int minute,
  }) async {
    await _cancel(id);

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // ─────────────────────────────────────────
  // زمان‌بندی هفتگی
  // ─────────────────────────────────────────
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int dayOfWeek, // 1=Mon ... 7=Sun
    required int hour,
    required int minute,
  }) async {
    await _cancel(id);

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != dayOfWeek || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  // ─────────────────────────────────────────
  // زمان‌بندی ماهانه
  // ─────────────────────────────────────────
  Future<void> scheduleMonthly({
    required int id,
    required String title,
    required String body,
    required String payload,
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    await _cancel(id);

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      dayOfMonth,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        dayOfMonth,
        hour,
        minute,
      );
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      payload: payload,
    );
  }

  // ─────────────────────────────────────────
  // لغو
  // ─────────────────────────────────────────
  Future<void> cancel(int id) => _cancel(id);

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _cancel(int id) => _plugin.cancel(id: id);

  // ─────────────────────────────────────────
  // جزئیات نمایش
  // ─────────────────────────────────────────
  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─────────────────────────────────────────
  // کاربر روی نوتیف زد → توی دیتابیس ذخیره کن
  // ─────────────────────────────────────────
  static void _onTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    _recordTap(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Notification tapped (background): ${response.payload}');
    _recordTap(response);
  }

  /// اطلاعات هر payload: (title, body, type)
  static (String, String, String)? _payloadInfo(String? payload) {
    switch (payload) {
      case payloadDaily:
        return (
          'یادآوری ثبت تراکنش‌ها',
          'امروز چه خرج‌هایی داشتی؟ بیا ثبتشون کن',
          'daily',
        );
      case payloadWeekly:
        return ('گزارش هفتگی', 'این هفته چقدر خرج کردی؟ ببین', 'weekly');
      case payloadMonthly:
        return (
          'خلاصه‌ی ماهانه',
          'مرور خرج و درآمد ماه گذشته‌ت آماده‌ست',
          'monthly',
        );
      case payloadBudget:
        return ('هشدار بودجه', 'به سقف بودجه‌ت رسیدی', 'budget');
      case payloadTips:
        return ('پیشنهاد هوشمند', 'یه نکته برای کم کردن خرج', 'tips');
      default:
        return null;
    }
  }

  /// نوتیف رو توی تاریخچه‌ی اپ ثبت می‌کنه (با جلوگیری از تکراری)
  static Future<void> _recordTap(NotificationResponse response) async {
    final info = _payloadInfo(response.payload);
    if (info == null) return;

    final (title, body, type) = info;

    try {
      // جلوگیری از تکراری: اگه همین نوع توی ۵ دقیقه‌ی گذشته ثبت شده، نذار
      final recent =
          await (database.select(database.notifications)
                ..where((n) => n.type.equals(type))
                ..orderBy([(n) => OrderingTerm.desc(n.createdAt)])
                ..limit(1))
              .get();

      if (recent.isNotEmpty &&
          DateTime.now().difference(recent.first.createdAt).inMinutes < 5) {
        return;
      }

      await db.NotificationService.create(title: title, body: body, type: type);
    } catch (e) {
      debugPrint('Failed to record notification tap: $e');
    }
  }
}
