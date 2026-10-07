import 'package:finance/database/app_setting.dart';
import 'package:finance/database/budget_repository.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/services/local_push_service.dart';
import 'package:finance/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class BudgetAlertService {
  BudgetAlertService._();

  static const _kEnabled = 'notif_enabled';
  static const _kBudgetAlert = 'notif_budget_alert';
  static const _kSent = 'budget_alerts_sent';

  static const _warnLevel = 80;
  static const _overLevel = 100;

  /// بعد از ثبت هر هزینه صدا زده بشه
  static Future<void> check({required int categoryId}) async {
    try {
      final s = AppSettings.instance;
      if (!s.get<bool>(_kEnabled, true) || !s.get<bool>(_kBudgetAlert, true)) {
        return;
      }

      final j = Jalali.now();
      final rows = await getBudgetsForMonth(j.year, j.month);

      // ── هشدار بودجه‌ی همین دسته ──
      for (final r in rows) {
        if (r.budget.categoryId != categoryId) continue;
        if (r.budget.amount <= 0) continue;

        final percent = (r.spent * 100 / r.budget.amount).floor();
        await _alertForLevel(
          idKey: '${r.budget.id}',
          pushId: 1000 + r.budget.id * 2,
          label: 'بودجه‌ی ${r.category.name}',
          j: j,
          percent: percent,
        );
      }

      // ── هشدار بودجه‌ی کل (جمع همه‌ی دسته‌ها، مثل کارت بالای صفحه‌ی بودجه) ──
      // اگه فقط یه بودجه داری، با هشدار خود دسته یکیه، پس تکراری نمی‌فرستیم
      if (rows.length >= 2) {
        final totalLimit = rows.fold<double>(0, (a, r) => a + r.budget.amount);
        final totalSpent = rows.fold<double>(0, (a, r) => a + r.spent);
        if (totalLimit > 0) {
          final percent = (totalSpent * 100 / totalLimit).floor();
          await _alertForLevel(
            idKey: 'total',
            pushId: 900,
            label: 'بودجه‌ی کل',
            j: j,
            percent: percent,
          );
        }
      }
    } catch (e) {
      debugPrint('BudgetAlertService.check failed: $e');
    }
  }

  static Future<void> _alertForLevel({
    required String idKey,
    required int pushId,
    required String label,
    required Jalali j,
    required int percent,
  }) async {
    if (percent >= _overLevel) {
      await _notifyOnce(idKey, pushId + 1, label, j, _overLevel, percent);
    } else if (percent >= _warnLevel) {
      await _notifyOnce(idKey, pushId, label, j, _warnLevel, percent);
    }
  }

  static Future<void> _notifyOnce(
    String idKey,
    int pushId,
    String label,
    Jalali j,
    int level,
    int percent,
  ) async {
    // کلید یکتا: بودجه + ماه + سطح
    final key = 'budget:$idKey:${j.year}-${j.month}:$level';

    final s = AppSettings.instance;
    final sent = s
        .get<List<dynamic>>(_kSent, [])
        .map((e) => e.toString())
        .toList();
    if (sent.contains(key)) return;
    sent.add(key);
    if (sent.length > 200) sent.removeRange(0, sent.length - 200);
    await s.set(_kSent, sent);

    final over = level >= _overLevel;
    final p = percent.toString().farsiNumber;
    final title = over ? 'از سقف بودجه رد شدی' : 'نزدیک سقف بودجه‌ای';
    final body = over
        ? '$label رو رد کردی (٪$p مصرف)'
        : '٪$p از $label رو مصرف کردی';

    // تاریخچه‌ی داخل اپ
    await NotificationService.create(
      title: title,
      body: body,
      type: 'budget',
      payload: key,
    );

    // نوتیف روی گوشی
    await LocalPushService.instance.showNow(
      id: pushId,
      title: title,
      body: body,
      payload: key,
    );
  }
}
