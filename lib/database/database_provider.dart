import 'package:flutter/foundation.dart';
import 'app_database.dart';

// نمونه‌ی اصلی دیتابیس که همه‌جای اپ استفاده میشه (از قبل داشتی)
final AppDatabase database = AppDatabase();

/// یه «زنگ اطلاع‌رسانی» سراسریه.
/// هر جای اپ که یه تراکنش اضافه، حذف یا ویرایش بشه،
/// مقدار این متغیر رو یکی زیاد می‌کنیم (transactionsTicker.value++).
/// هر صفحه‌ای که به این متغیر "گوش" بده (addListener)،
/// همون لحظه خبردار میشه که یه چیزی توی دیتابیس تغییر کرده
/// و می‌تونه خودش رو دوباره از دیتابیس آپدیت کنه (بدون نیاز به ری‌استارت اپ).
final ValueNotifier<int> transactionsTicker = ValueNotifier(0);

// ← جدید: هر وقت بودجه‌ای اضافه یا حذف شد (خودِ بودجه، نه تراکنش‌هاش)،
// این مقدار عوض میشه تا Budgetsscreen خبردار شه و دوباره بخونه.
final ValueNotifier<int> budgetsTicker = ValueNotifier(0);

/// هر وقت اعلان جدیدی اضافه/خونده/حذف شد، این مقدار عوض می‌شه
/// تا صفحه‌هایی که لیست اعلان‌ها یا badge رو نشون می‌دن refresh بشن.
final ValueNotifier<int> notificationsTicker = ValueNotifier(0);
