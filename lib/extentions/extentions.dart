import 'package:finance/database/app_setting.dart';

// این اکستنشن رو جای اکستنشن قبلی تو lib/extentions/extentions.dart بذار
// (اگه اون فایل چیزای دیگه‌ای هم داره، فقط همین اکستنشن رو عوض کن و
// ایمپورت بالا رو هم اضافه کن).
extension FarsiNumberExtensions on String {
  String get farsiNumber {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const farsi = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

    // تنظیمات: 0 = ارقام فارسی ، 1 = ارقام انگلیسی
    final useEnglish = AppSettings.instance.get<int>('digits', 0) == 1;

    String text = this;
    for (int i = 0; i < english.length; i++) {
      text = useEnglish
          ? text.replaceAll(farsi[i], english[i])
          : text.replaceAll(english[i], farsi[i]);
    }
    return text;
  }
}
