import 'package:drift/drift.dart';
import 'app_database.dart';
import 'database_provider.dart';

Future<void> seedCategoriesIfEmpty() async {
  final existing = await database.select(database.categories).get();
  if (existing.isNotEmpty) return; // قبلاً پر شده، دوباره کاری نکن

  // ← هر دسته‌ی هزینه یه رنگ جدا از این لیست می‌گیره (رنگ سوم توی تاپل)
  // به‌جای اینکه همه یه رنگ ثابت داشته باشن.
  // این رنگا از پیش انتخاب شدن (نه رندوم موقع اجرا) چون اگه واقعاً رندوم
  // بود، هر بار که seed اجرا میشد (مثلاً نصب مجدد اپ)، رنگا فرق می‌کرد
  // و هیچ ثباتی نداشت. اینجوری همیشه همون هماهنگی رنگی رو داری.
  final expense = [
    ('خورد و خوراک', 'restaurant', '#FF6B6B'),
    ('حمل و نقل', 'directions_car', '#4C7DFF'),
    ('خرید', 'shopping_bag', '#F97316'),
    ('سرگرمی', 'movie', '#E11D48'),
    ('سلامت', 'health_and_safety', '#8B5CF6'),
    ('قبض‌ها', 'receipt_long', '#EAB308'),
    ('آموزش', 'school', '#0EA5E9'),
    ('سایر', 'more_horiz', '#6B7280'),
  ];

  // ← برخلاف هزینه، اینجا رنگ رو توی تاپل نگه نمی‌داریم چون
  // طبق خواسته‌ت، همه‌ی دسته‌های درآمد باید همون یه رنگ سبز ثابت
  // ('#1FBF8F') رو داشته باشن. یعنی این لیست فقط شامل (نام، آیکون)ه.
  final income = [
    ('حقوق', 'account_balance_wallet'),
    ('فریلنس', 'laptop_mac'),
    ('هدیه', 'card_giftcard'),
    ('سرمایه‌گذاری', 'trending_up'),
    ('سایر', 'more_horiz'),
  ];

  // رنگ ثابت سبز برای همه‌ی دسته‌های درآمد
  const incomeColor = '#1FBF8F';

  for (final (name, icon, color) in expense) {
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name,
            icon: icon,
            color: color, // ← رنگ مخصوص همین دسته
            type: 'expense',
          ),
        );
  }

  for (final (name, icon) in income) {
    await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name,
            icon: icon,
            color: incomeColor, // ← همیشه همون سبز ثابت
            type: 'income',
          ),
        );
  }
}

Future<List<Category>> getCategoriesByType(String type) {
  return (database.select(
    database.categories,
  )..where((c) => c.type.equals(type))).get();
}
