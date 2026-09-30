# فاز ۲ — کیفیت کد (اولویت: بالا 🟠)

> **هدف:** رساندن کیفیت کد از ۵/۱۰ به ۸/۱۰ با تمیزکاری کم‌ریسک.
> **پیش‌نیاز:** فاز ۱ (اختیاری ولی توصیه می‌شود اول امنیت بسته شود).
> **برای شروع بگو:** `فاز ۲ کیفیت کد رو شروع کن`

---

## ۲-۱ دسته‌بندی مشکلات

### A) Lint و آنالیز (سریع‌الاثر)

| # | مشکل | محل |
|---|------|-----|
| A1 | `analysis_options.yaml` دست‌نخورده — فقط `flutter_lints` پیش‌فرض، هیچ rule اضافی فعال نیست | `analysis_options.yaml` |
| A2 | ۸۲ مورد `print/debugPrint` جا مانده (بیشتر در صفحات setting) | `lib/Screen/**/`, `lib/widget/**` |
| A3 | `flutter analyze` با تنظیمات فعلی تقریباً هیچ‌چیز گزارش نمی‌کند — باگ‌ها پنهان می‌مانند | کل پروژه |

### B) نام‌گذاری و ساختار پوشه

| # | مشکل | محل |
|---|------|-----|
| B1 | `Constans` غلط املایی (درست: `Constants`) — در ۱۵+ فایل import شده | `lib/Constans/` |
| B2 | `extentions` / `extention.dart` غلط املایی (درست: `extensions`) | `lib/extentions/` |
| B3 | پوشه `Screen` با S بزرگ (خلاف قرارداد `lowercase_with_underscores`) | `lib/Screen/` |
| B4 | پوشه `Onboard` با O بزرگ | `lib/Onboard/` |
| B5 | نام کلاس‌ها `Transactionsscreen` / `Budgetsscreen` / `Insightsscreen` — جمع مضاعف و casing اشتباه | `lib/Screen/pages/` |
| B6 | فایل `custom_bottm_nav_widget.dart` غلط املایی (`bottom`) | `lib/widget/` |

### C) رشته‌های جادویی و تایپ ضعیف

| # | مشکل | محل |
|---|------|-----|
| C1 | فیلد `type` ('income'/'expense') و `period` ('week'/'month'/'year'/'custom') به‌صورت `String` خام | `lib/database/tables.dart`, `lib/database/budget_repository.dart`, `lib/Screen/pages/*` |
| C2 | `type` اعلان‌ها ('budget'/'sms'/...) هم String خام | `lib/database/tables.dart:51` |
| C3 | `color` دسته به‌صورت `String` hex ('#FF5733') بدون اعتبارسنجی | `lib/database/tables.dart:7` |
| C4 | `icon` دسته به‌صورت `String` نام آیکون بدون نگاشت تایپ‌ایمن | همان |

### D) Dead / Duplicate Code

| # | مشکل | محل |
|---|------|-----|
| D1 | دو فایل `lib/screen/root.dart` و `lib/Screen/root.dart` با محتوای یکسان (تکرار) | `lib/screen/` vs `lib/Screen/` |
| D2 | `lib/Constans/icon_map.dart` و `lib/Constans/random_color.dart` — بررسی شود آیا استفاده می‌شوند | `lib/Constans/` |
| D3 | `BankBinDetector.supportedBanks` هر بار Set جدید می‌سازد؛ قابل cache | `lib/database/bank_bin_detector.dart:68` |

---

## ۲-۲ چک‌لیست اجرایی

### گام ۱ — سخت‌گیر کردن Lint
- [ ] `analysis_options.yaml` را به این شکل ارتقا بده:
  ```yaml
  include: package:flutter_lints/flutter.yaml
  linter:
    rules:
      avoid_print: true
      prefer_single_quotes: true
      require_trailing_commas: true
      avoid_empty_else: true
      avoid_types_as_parameter_names: true
      cancel_subscriptions: true
      close_sinks: true
      literal_only_boolean_expressions: true
      no_duplicate_case_values: true
      prefer_const_constructors: true
      prefer_final_fields: true
      use_key_in_widget_constructors: true
  ```
- [ ] `flutter analyze` بزن و هشدارها را رفع کن

### گام ۲ — جایگزینی printها
- [ ] پکیج `logger` اضافه کن یا `debugPrint` را فقط در `kDebugMode` نگه دار:
  ```dart
  if (kDebugMode) debugPrint(...);
  // یا
  Logger().d(...)
  ```
- [ ] همه `print(` را حذف/جایگزین کن (۸۲ مورد)

### گام ۳ — Enumها
- [ ] بساز: `enum TransactionType { income, expense }` و `enum BudgetPeriod { week, month, year, custom }` و `enum NotificationType { budget, sms, daily, weekly, monthly, tips, system }`
- [ ] ستون‌های Drift را به `textEnum<TransactionType>()` تغییر بده (نیاز به migration)
- [ ] جایگزینی تدریجی: اول enum بساز + extension برای `String` قدیمی، بعد migration

### گام ۴ — Rename پوشه‌ها و فایل‌ها (با ابزار)
- [ ] از `dart fix` / ری‌نیم IDE استفاده کن تا importها خودکار درست شوند:
  - `Constans` → `constants`
  - `extentions` → `extensions`
  - `Screen` → `screens`
  - `Onboard` → `onboarding`
  - `Transactionsscreen` → `TransactionsScreen` (و بقیه)
  - `custom_bottm_nav_widget.dart` → `custom_bottom_nav_widget.dart`
- [ ] فایل تکراری `lib/screen/root.dart` را حذف کن (یکی را نگه دار)
- [ ] `flutter analyze` و `flutter test` بعد از هر دسته rename

---

## ۲-۳ معیار پذیرش
- `flutter analyze` بدون warning/error.
- `grep -r "print(" lib --include="*.dart"` صفر نتیجه.
- هیچ پوشه‌ای با حرف بزرگ باقی نماند.
- `String` خام برای type/period باقی نماند (یا با `// TODO(migration):` علامت‌گذاری شده باشد).
