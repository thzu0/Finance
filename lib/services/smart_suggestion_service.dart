import 'package:finance/database/app_setting.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class SmartSuggestionService {
  SmartSuggestionService._();
  static final SmartSuggestionService instance = SmartSuggestionService._();

  static const _kEnabled = 'notif_enabled';
  static const _kTips = 'notif_tips';
  static const _kLastSent = 'tips_last_sent_ms';

  // ─────────────────────────────────────────
  // فرمت پول
  // ─────────────────────────────────────────
  static String _money(double amount) {
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
  // ساخت متن پیشنهاد بر اساس خلاصه‌ی ماه جاری و قبل
  // ─────────────────────────────────────────
  static Future<({String title, String body})?> _build() async {
    final now = DateTime.now();
    final s = await getMonthSummary(now);

    // نه این ماه، نه ماه قبل خرجی نبوده → اسپم نکن
    if (s.expense == 0 && s.prevExpense == 0) return null;

    // ماه قبل خرجی نداشته (کاربر جدید)
    if (s.prevExpense == 0) {
      final top = await _topCategory(now);
      if (top != null) {
        return (
          title: 'بیشترین خرج این ماه',
          body: 'بیشترین خرجت تو دسته‌ی «$top» بوده',
        );
      }
      return (
        title: 'یه نگاه به خرج‌هات',
        body: 'این ماه ${_money(s.expense)} خرج کردی',
      );
    }

    final change = ((s.expense - s.prevExpense) / s.prevExpense) * 100;

    // ۵٪ یا بیشتر کاهش → تشویق
    if (change <= -5) {
      final pct = change.abs().toStringAsFixed(0).farsiNumber;
      return (
        title: 'آفرین 👏',
        body: 'این ماه $pct٪ کمتر از ماه قبل خرج کردی',
      );
    }

    // ۱۰٪ یا بیشتر افزایش → هشدار دوستانه
    if (change >= 10) {
      final pct = change.abs().toStringAsFixed(0).farsiNumber;
      final top = await _topCategory(now);
      final extra = top != null ? '، بیشترش تو «$top»' : '';
      return (
        title: 'یه هشدار دوستانه',
        body: 'این ماه $pct٪ بیشتر از ماه قبل خرج کردی$extra',
      );
    }

    return null; // تغییر محسوس نیست، اسپم نکن
  }

  static Future<String?> _topCategory(DateTime ref) async {
    final list = await getExpenseByCategory(ref);
    if (list.isEmpty) return null;
    return list.first.label;
  }

  // ─────────────────────────────────────────
  // ارسال فوری
  // ─────────────────────────────────────────
  static Future<void> sendNow({bool force = false}) async {
    try {
      final s = AppSettings.instance;
      if (!s.get<bool>(_kEnabled, true)) return;
      if (!s.get<bool>(_kTips, false)) return;

      final sug = await _build();
      if (sug == null) return;

      // تو حالت غیر force، اگه ۷ روز نشده، چیزی نفرست
      if (!force) {
        final last = s.get<int>(_kLastSent, 0);
        final diff = DateTime.now().millisecondsSinceEpoch - last;
        if (diff < const Duration(days: 7).inMilliseconds) return;
      }

      await NotificationService.create(
        title: sug.title,
        body: sug.body,
        type: 'tips',
      );
      await LocalPushService.instance.showNow(
        id: LocalPushService.idTips,
        title: sug.title,
        body: sug.body,
        payload: LocalPushService.payloadTips,
      );
      await s.set(_kLastSent, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('SmartSuggestionService.sendNow failed: $e');
    }
  }
}
