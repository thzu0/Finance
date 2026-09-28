import 'package:finance/database/database_provider.dart';
import 'package:finance/database/seed_categories.dart';

/// همه‌ی تراکنش‌ها و بودجه‌ها رو پاک می‌کنه و دسته‌ها رو دوباره seed می‌کنه.
Future<void> clearAllData() async {
  // ترتیب مهمه: اول جدول‌های وابسته
  await database.delete(database.transactions).go();
  await database.delete(database.budgets).go();
  await database.delete(database.categories).go();
  await seedCategoriesIfEmpty();
  transactionsTicker.value++;
  budgetsTicker.value++;
}
