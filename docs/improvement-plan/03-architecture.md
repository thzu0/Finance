# فاز ۳ — معماری (اولویت: بالا 🟠)

> **هدف:** خروج از سینگلتون‌های سراسری و `ValueNotifier` پراکنده به معماری قابل تست و مقیاس‌پذیر.
> **پیش‌نیاز:** فاز ۲ (renameها انجام شده باشد تا ریفکتور تمیز بماند).
> **برای شروع بگو:** `فاز ۳ معماری رو شروع کن`

---

## ۳-۱ دسته‌بندی مشکلات

### A) State Management

| # | مشکل | محل | اثر |
|---|------|-----|-----|
| A1 | سه `ValueNotifier<int>` سراسری (`transactionsTicker`, `budgetsTicker`, `notificationsTicker`) به‌جای Stream/State management | `lib/database/database_provider.dart` | هر صفحه `addListener` دستی + `setState`؛ مقیاس‌ناپذیر، تست‌ناپذیر |
| A2 | هر صفحه با `setState` و `initState` دیتا را دستی reload می‌کند | `lib/Screen/pages/home_screen.dart`, `budget_screen.dart`, `insights_screen.dart` | کد تکراری، race condition |
| A3 | `AppSettings` هم `ValueNotifier changes` دارد ولی هیچ‌کس درست گوش نمی‌دهد | `lib/database/app_setting.dart` | تغییرات تنظیمات گاهی UI را ریفرش نمی‌کند |

### B) وابستگی سراسری (Global Singletons)

| # | مشکل | محل | اثر |
|---|------|-----|-----|
| B1 | `final AppDatabase database = AppDatabase()` سراسری | `lib/database/database_provider.dart:5` | تست بدون DB واقعی ممکن نیست؛ DI وجود ندارد |
| B2 | `PinService`, `BiometricService`, `CardService`, `NotificationService` همه static | `lib/security/*`, `lib/services/*` | Mock کردن در تست سخت، وابستگی پنهان |
| B3 | `AppSettings.instance` سینگلتون با فایل I/O در `load()` | `lib/database/app_setting.dart` | تست نیاز به فایل واقعی دارد |

### C) لایه Repository ناقص

| # | مشکل | محل |
|---|------|-----|
| C1 | `transaction_repository.dart` و `budget_repository.dart` توابع top-level هستند نه کلاس Repository | `lib/database/*_repository.dart` |
| C2 | هیچ abstraction (interface) برای Repository وجود ندارد — تعویض DB ممکن نیست | — |
| C3 | منطق بیزینس (مثلاً محاسبه `spent` بودجه) داخل `budget_screen.dart` است نه Repository | `lib/Screen/pages/budget_screen.dart` |

### D) دیتابیس

| # | مشکل | محل |
|---|------|-----|
| D1 | `schemaVersion = 1` بدون `migration` — هر تغییر اسکیما نیاز به حذف اپ دارد | `lib/database/app_database.dart:16` |
| D2 | هیچ index روی `Transactions.date` و `Transactions.categoryId` (کوئری‌های Insights/Budget روی همین‌هاست) | `lib/database/tables.dart` |
| D3 | `LazyDatabase` با `NativeDatabase.createInBackground` ولی بدون WAL mode | `lib/database/app_database.dart:19` |

---

## ۳-۲ چک‌لیست اجرایی

### گام ۱ — انتخاب State Management
- [ ] یکی را انتخاب کن و مستند کن (توصیه برای این اپ: **Riverpod** یا **Bloc**؛ برای شروع Riverpod سبک‌تر است):
  - Riverpod: کمترین بازنویسی، تست آسان
  - Bloc: اگر تیم بزرگ‌تر می‌شود
  - Provider: ساده‌ترین ولی برای این حجم کافی نیست
- [ ] `flutter_riverpod` (یا انتخاب نهایی) را به `pubspec.yaml` اضافه کن

### گام ۲ — DI و Database Provider
- [ ] `AppDatabase` را به `Provider<AppDatabase>` تبدیل کن (Riverpod) یا `GetIt`:
  ```dart
  final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());
  // در تست:
  // ProviderScope(overrides: [databaseProvider.overrideWithValue(fakeDb)])
  ```
- [ ] متغیر سراسری `final database` را حذف کن؛ همه جا از `ref.watch(databaseProvider)` استفاده شود
- [ ] `AppSettings` را هم Provider کن

### گام ۳ — Repository با Interface
- [ ] اینترفیس بساز:
  ```dart
  abstract class TransactionRepository {
    Future<int> add({...});
    Stream<List<Transaction>> watchAll();
    Future<void> delete(int id);
  }
  ```
- [ ] پیاده‌سازی `DriftTransactionRepository` + تزریق `AppDatabase` از constructor
- [ ] همین الگو برای `BudgetRepository` و `NotificationRepository`

### گام ۴ — جایگزینی ValueNotifier با Stream
- [ ] `transactionsTicker`/`budgetsTicker`/`notificationsTicker` را حذف کن
- [ ] به‌جای `addListener` + `setState`، از `ref.watch(transactionsProvider)` یا `StreamBuilder` استفاده کن
- [ ] Drift خودش `watch()` دارد — مستقیم از آن استفاده کن

### گام ۵ — Migration و Index
- [ ] `onUpgrade` برای Drift اضافه کن (حتی اگر فعلاً خالی باشد):
  ```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async { /* ... */ },
  );
  ```
- [ ] Index اضافه کن:
  ```dart
  // در Tables
  @override
  List<Index> get customIndexes => [
    Index('idx_tx_date', 'CREATE INDEX idx_tx_date ON transactions(date)'),
    Index('idx_tx_category', 'CREATE INDEX idx_tx_category ON transactions(category_id)'),
  ];
  ```

---

## ۳-۳ معیار پذیرش
- هیچ `ValueNotifier` سراسری باقی نماند.
- هیچ `import 'database_provider.dart'` که متغیر سراسری `database` را بخواند باقی نماند.
- `flutter analyze` پاس، اپ روی گوشی بدون رگرسیون کار کند.
- یک تست نمونه با DB فیک/در-memory پاس شود.
