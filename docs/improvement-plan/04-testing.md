# فاز ۴ — تست (اولویت: متوسط 🟡)

> **هدف:** رساندن پوشش تست از ۱/۱۰ به قابل اعتماد برای ریفکتورهای بعدی.
> **پیش‌نیاز:** فاز ۳ (حداقل DI انجام شده باشد تا تست با DB فیک ممکن شود).
> **برای شروع بگو:** `فاز ۴ تست رو شروع کن`

---

## ۴-۱ وضعیت فعلی

| # | مشکل | محل |
|---|------|-----|
| T1 | `test/widget_test.dart` همان تست پیش‌فرض کانتر است و Fail می‌شود (MyApp دیگر Counter ندارد) | `test/widget_test.dart` |
| T2 | پوشش واقعی ۰٪ — هیچ Unit/Widget/Integration تستی وجود ندارد | `test/` |
| T3 | بدون تست، هر تغییر در Repository یا Security پرریسک است | کل پروژه |
| T4 | `pubspec.yaml` هیچ وابستگی تست اضافی ندارد (`mockito`/`mocktail`/`fake_async`) | `pubspec.yaml` |

---

## ۴-۲ چک‌لیست اجرایی

### گام ۱ — زیرساخت تست
- [ ] وابستگی‌ها را اضافه کن:
  ```yaml
  dev_dependencies:
    mocktail: ^1.0.0
    fake_async: ^1.3.0
  ```
- [ ] تست پیش‌فرض `widget_test.dart` را حذف یا با یک Smoke Test واقعی جایگزین کن:
  ```dart
  testWidgets('app starts and shows onboarding or home', (t) async {
    await t.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
  ```
- [ ] Helper برای DB در-memory بساز: `test/helpers/fake_database.dart` با `NativeDatabase.memory()`

### گام ۲ — Unit Tests (اولویت اول)
- [ ] `test/security/pin_service_test.dart` — setPin, verify, disable, salt یکتا بودن
- [ ] `test/database/bank_bin_detector_test.dart` — همه BINهای جدول + شماره با فاصله/خط‌تیره + ناشناس
- [ ] `test/database/transaction_repository_test.dart` — add, delete, watch, محاسبه total
- [ ] `test/database/budget_repository_test.dart` — محاسبه spent، بازه custom
- [ ] `test/services/sms_parser_test.dart` — پارس پیامک‌های نمونه هر بانک (بعد از نوشتن parser)

### گام ۳ — Widget Tests
- [ ] `test/widgets/pin_screen_test.dart` — ورود درست/غلط، نمایش خطا
- [ ] `test/widgets/budget_screen_test.dart` — نمایش نوار پیشرفت بودجه
- [ ] `test/widgets/insights_screen_test.dart` — رندر چارت با دیتای فیک

### گام ۴ — Integration Test (اختیاری)
- [ ] `integration_test/app_test.dart` — سناریو: Onboarding → ثبت تراکنش → مشاهده در Home → ست کردن بودجه → چک Insights

### گام ۵ — CI
- [ ] اسکریپت `flutter test` را به CI اضافه کن (GitHub Actions):
  ```yaml
  - run: flutter analyze
  - run: flutter test --coverage
  ```

---

## ۴-۳ معیار پذیرش
- `flutter test` سبز، `flutter analyze` سبز.
- پوشش Unit برای `security/` و `database/bank_bin_detector` بالای ۸۰٪.
- تست پیش‌فرض کانتر حذف شده باشد.
