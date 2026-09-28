import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:finance/database/app_setting.dart';

class PinService {
  static final _s = AppSettings.instance;

  static bool get isEnabled =>
      _s.get<bool>('appLock', false) &&
      _s.get<String>('pinHash', '').isNotEmpty;

  static bool get hasPin => _s.get<String>('pinHash', '').isNotEmpty;

  static String _hash(String pin, String salt) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static Future<void> setPin(String pin) async {
    final rnd = Random.secure();
    final salt = base64UrlEncode(
      List<int>.generate(16, (_) => rnd.nextInt(256)),
    );
    await _s.set('pinSalt', salt);
    await _s.set('pinHash', _hash(pin, salt));
    await _s.set('appLock', true);
  }

  static bool verify(String pin) {
    final salt = _s.get<String>('pinSalt', '');
    final hash = _s.get<String>('pinHash', '');
    return hash.isNotEmpty && _hash(pin, salt) == hash;
  }

  static Future<void> disable() async {
    await _s.set('appLock', false);
    await _s.set('pinHash', '');
    await _s.set('pinSalt', '');
  }
}
