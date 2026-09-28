import 'package:finance/database/app_setting.dart';

class CardService {
  CardService._();
  static final CardService instance = CardService._();

  static final _s = AppSettings.instance;

  /// ذخیره‌ی اطلاعات کارت
  Future<void> saveCard({
    required String number,
    required String holderName,
    required String expiry,
    required String bankName,
  }) async {
    await _s.set('card_number', number);
    await _s.set('card_holder', holderName);
    await _s.set('card_expiry', expiry);
    await _s.set('card_bank', bankName);
  }

  /// خوندن اطلاعات کارت
  Map<String, String> getCard() => {
    'number': _s.get<String>('card_number', ''),
    'holderName': _s.get<String>('card_holder', ''),
    'expiry': _s.get<String>('card_expiry', ''),
    'bankName': _s.get<String>('card_bank', ''),
  };

  /// آیا کارتی ذخیره شده؟
  bool hasCard() => _s.get<String>('card_number', '').isNotEmpty;

  /// حذف کارت
  Future<void> deleteCard() async {
    await _s.set('card_number', '');
    await _s.set('card_holder', '');
    await _s.set('card_expiry', '');
    await _s.set('card_bank', '');
  }
}
