# فاز ۱ — امنیت (اولویت: حیاتی 🔴)

> **هدف:** بستن حفره‌های امنیتی که در امتیازدهی نمره ۴.۵/۱۰ گرفتند.
> **پیش‌نیاز:** هیچ — این فاز باید اول انجام شود.
> **برای شروع در چت جدا بگو:** `فاز ۱ امنیت رو شروع کن`

---

## ۱-۱ دسته‌بندی مشکلات امنیتی

### A) ذخیره‌سازی ناامن (Critical)

| # | مشکل | محل | ریسک |
|---|------|-----|------|
| A1 | `pinHash` و `pinSalt` داخل `settings.json` متنی ذخیره می‌شوند | `lib/security/pin_service.dart` + `lib/database/app_setting.dart` | هر اپ با دسترسی فایل یا بکاپ می‌تواند هش را بخواند؛ آفلاین Brute-force ممکن است |
| A2 | شماره کارت، نام صاحب، تاریخ انقضا متنی در `settings.json` | `lib/database/card_service.dart` | نشت PII؛ حتی ماسک هم نمی‌شود |
| A3 | دیتابیس SQLite بدون رمزگذاری | `lib/database/app_database.dart` (`sqlite3_flutter_libs`) | استخراج فایل `finance.sqlite` = کل تراکنش‌ها لو می‌رود |
| A4 | `flutter_secure_storage: 11.2.0` نصب است ولی استفاده نمی‌شود | `pubspec.yaml` | وابستگی بلااستفاده |

### B) منطق قفل و احراز هویت (High)

| # | مشکل | محل | ریسک |
|---|------|-----|------|
| B1 | `onForgot` در `AppLockGate` بدون تایید دوم کل دیتا را پاک و قفل را غیرفعال می‌کند | `lib/security/app_lock_gate.dart:76-80` | پاک شدن تصادفی/عمدی با یک تپ |
| B2 | مهلت ۳۰ ثانیه (`_grace`) ثابت و غیرقابل تنظیم | همان فایل | UX یا خیلی سخت‌گیر یا خیلی شل |
| B3 | `PinService.verify` همگام (sync) و بدون Rate-limit | `lib/security/pin_service.dart:28` | Brute-force سریع روی UI |

### C) مجوزها و حریم خصوصی (Medium)

| # | مشکل | محل | ریسک |
|---|------|-----|------|
| C1 | `Permission.sms` درخواست می‌شود ولی متن پیامک‌ها لاگ/ذخیره نامحدود می‌شود؟ | `lib/services/sms_permission.dart` + `card_service` | اگر SMS parser خام باشد، اطلاعات حساس لاگ می‌شود |
| C2 | `clearAllData()` ترتیب حذف را رعایت می‌کند ولی `Notifications` را پاک نمی‌کند | `lib/database/data_reset.dart` | نشت اعلان‌های قدیمی پس از «حذف همه» |

---

## ۱-۲ چک‌لیست اجرایی (به ترتیب)

### گام ۱ — انتقال Secretها به SecureStorage
- [ ] سرویس `SecureStore` بساز (`lib/security/secure_store.dart`) دور `FlutterSecureStorage`
- [ ] `PinService`: `pinHash`/`pinSalt` را از `AppSettings` به `SecureStore` منتقل کن + migration یک‌باره برای کاربران فعلی
- [ ] `CardService`: شماره کارت و holder را در `SecureStore` بگذار؛ فقط ۴ رقم آخر را در `AppSettings` برای نمایش نگه دار
- [ ] تست دستی: نصب روی گوشی، ست کردن PIN و کارت، چک کردن عدم وجودشان در `settings.json`

### گام ۲ — رمزگذاری دیتابیس
- [ ] `sqlite3_flutter_libs` → `sqlcipher_flutter_libs` (یا `drift_sqlcipher`)
- [ ] کلید را با `SecureStore` تولید/ذخیره کن (یک‌بار، ۳۲ بایت random)
- [ ] `_openConnection()` را به `NativeDatabase` رمزگذاری‌شده تغییر بده
- [ ] migration: اگر `finance.sqlite` قدیمی بدون رمز وجود دارد، آن را باز کن، dump بگیر، روی DB جدید رمزگذاری‌شده restore کن سپس فایل قدیمی را حذف کن
- [ ] کامنت `// فعلاً این، بعداً جاش رو با sqlcipher عوض می‌کنیم` را حذف کن

### گام ۳ — سخت‌سازی قفل
- [ ] `onForgot`: دیالوگ تایید دو مرحله‌ای (تایپ کلمه `حذف` یا PIN قدیمی) + دکمه قرمز
- [ ] Rate-limit برای `verify`: بعد از ۵ تلاش ناموفق، ۳۰ ثانیه قفل + شمارش نمایش داده شود
- [ ] `_grace` را به تنظیمات ببر (`AppSettings: lockGraceSeconds`) با پیش‌فرض ۳۰
- [ ] `clearAllData()`: علاوه بر ۳ جدول، `notifications` را هم پاک کند (یا گزینه جدا)

### گام ۴ — کاهش سطح دسترسی SMS
- [ ] فقط در صورت `isSmsParsingEnabled()==true` به SMS گوش بده
- [ ] متن خام SMS را هرگز لاگ نکن (`print` خام SMS ممنوع)
- [ ] پس از پارس، فقط فیلدهای استخراج‌شده (مبلغ، تاریخ) را ذخیره کن نه متن کامل

---

## ۱-۳ معیار پذیرش (Definition of Done)
- `grep -r "pinHash\|pinSalt\|card_number" lib --include="*.dart"` هیچ ارجاعی به `AppSettings` نداشته باشد.
- `flutter analyze` بدون هشدار امنیتی.
- تست دستی: بکاپ `settings.json` و `finance.sqlite` بدون کلید SecureStorage غیرقابل خواندن باشد.
