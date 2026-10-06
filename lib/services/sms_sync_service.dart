import 'package:finance/database/app_setting.dart';
import 'package:finance/database/card_service.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/sms/bank_sms_parser.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsSyncService {
  SmsSyncService._();
  static bool _running = false;

  /// بار اول چند روز عقب‌تر پیامک‌ها خونده بشه (۰ = همه‌ی پیامک‌ها)
  static const int _firstRunDays = 365;

  /// اسم فرستنده‌های هر بانک (طبق چیزی که توی اینباکس گوشی دیده می‌شه)
  static const Map<String, List<String>> _sendersByBank = {
    'پاسارگاد': ['B.Pasargad', 'Pasargad'],
    // بانک جدید: اسم فرستنده‌اش رو اینجا اضافه کن
  };

  static List<String> _sendersFor(String bankName) {
    for (final entry in _sendersByBank.entries) {
      if (bankName.contains(entry.key)) return entry.value;
    }
    return const [];
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

      final bank = cards.getCard()['bankName']!;
      if (!SmsParserRegistry.isSupported(bank)) return 0;

      final senders = _sendersFor(bank);
      if (senders.isEmpty) return 0;

      final s = AppSettings.instance;
      final firstRun = _firstRunDays == 0
          ? 0
          : DateTime.now()
                .subtract(const Duration(days: _firstRunDays))
                .millisecondsSinceEpoch;
      final since = s.get<int>('sms_last_ts', firstRun);

      // فقط پیامک‌های فرستنده‌ی همین بانک
      final query = SmsQuery();
      final all = <SmsMessage>[];
      for (final addr in senders) {
        final result = await query.querySms(address: addr);
        all.addAll(result);
      }

      // فقط جدیدها، از قدیم به جدید
      final fresh =
          all
              .where(
                (m) => m.date != null && m.date!.millisecondsSinceEpoch > since,
              )
              .toList()
            ..sort((a, b) => a.date!.compareTo(b.date!));

      int added = 0;
      int newest = since;
      for (final m in fresh) {
        final ts = m.date!.millisecondsSinceEpoch;
        if (ts > newest) newest = ts;
        if (await importSmsForBank(bank, m.body ?? '')) added++;
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
