import 'package:finance/database/app_setting.dart';
import 'package:finance/database/card_service.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/sms/bank_sms_parser.dart';
import 'package:finance/sms/sms_parser.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsSyncService {
  SmsSyncService._();
  static bool _running = false;

  /// بار اول چند روز عقب‌تر پیامک‌ها خونده بشه (۰ = همه‌ی پیامک‌ها)
  static const int _firstRunDays = 365;

  static int get _firstRunTs => _firstRunDays == 0
      ? 0
      : DateTime.now()
            .subtract(const Duration(days: _firstRunDays))
            .millisecondsSinceEpoch;

  /// فرستنده‌ی پیامک بدون حساسیت به حروف بزرگ/کوچک و فاصله‌ی دور متن مقایسه می‌شه
  static bool senderMatches(String? address, String selected) =>
      address != null &&
      address.trim().toLowerCase() == selected.trim().toLowerCase();

  /// بعد از عوض شدن فرستنده یا ۴ رقم حساب صدا بزن تا پیامک‌های قبلی
  /// دوباره با تنظیم جدید بررسی بشن (تکراری‌ها با smsId ثبت نمی‌شن).
  static Future<void> resetCursor() =>
      AppSettings.instance.set('sms_last_ts', _firstRunTs);

  /// فرستنده‌هایی که توی اینباکس پیامک تراکنشی دارن، به ترتیب تعداد.
  /// null یعنی دسترسی پیامک داده نشد.
  static Future<List<({String address, int count})>?> discoverSenders() async {
    if (!await Permission.sms.isGranted &&
        !(await Permission.sms.request()).isGranted) {
      return null;
    }
    final messages = await SmsQuery().querySms(count: 1000);
    final counts = <String, int>{};
    for (final m in messages) {
      final address = m.address?.trim();
      if (address == null || address.isEmpty) continue;
      if (parseBankSms(m.body ?? '') == null) continue;
      counts[address] = (counts[address] ?? 0) + 1;
    }
    return [
      for (final e in counts.entries) (address: e.key, count: e.value),
    ]..sort((a, b) => b.count.compareTo(a.count));
  }

  /// پیامک‌های جدید رو می‌خونه و تراکنش ثبت می‌کنه.
  /// تعداد تراکنش‌های جدید رو برمی‌گردونه.
  static Future<int> sync() async {
    if (_running) return 0;
    _running = true;
    try {
      final cards = CardService.instance;
      if (!cards.hasCard() || !cards.isSmsParsingEnabled()) return 0;
      if (!await Permission.sms.isGranted) return 0;

      final sender = cards.getSmsSender();
      if (sender.isEmpty) return 0;
      final last4 = cards.getSmsAccountLast4();

      final s = AppSettings.instance;
      final since = s.get<int>('sms_last_ts', _firstRunTs);

      // فقط پیامک‌های فرستنده‌ی انتخاب‌شده
      final all = await SmsQuery().querySms(address: sender);

      // فقط جدیدها، از قدیم به جدید
      final fresh =
          all
              .where(
                (m) =>
                    m.date != null &&
                    m.date!.millisecondsSinceEpoch > since &&
                    senderMatches(m.address, sender),
              )
              .toList()
            ..sort((a, b) => a.date!.compareTo(b.date!));

      int added = 0;
      int newest = since;
      for (final m in fresh) {
        final ts = m.date!.millisecondsSinceEpoch;
        if (ts > newest) newest = ts;
        final imported = await importSmsForBank(
          sender,
          m.body ?? '',
          receivedAt: m.date!,
          sender: m.address ?? sender,
          accountLast4Filter: last4,
        );
        if (imported) added++;
      }

      await s.set('sms_last_ts', newest);

      // لنگر ممکنه عوض شده باشه حتی اگه تراکنش جدیدی نیومده؛ هوم رفرش بشه
      if (fresh.isNotEmpty) transactionsTicker.value++;
      return added;
    } catch (_) {
      return 0;
    } finally {
      _running = false;
    }
  }
}
