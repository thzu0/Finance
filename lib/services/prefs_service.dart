import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String _onboardingKey = 'has_seen_onboarding';

  /// ذخیره اینکه کاربر onboarding رو دیده
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// چک کردن اینکه کاربر قبلاً دیده یا نه
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// ریست کردن (فقط برای تست)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }
}
