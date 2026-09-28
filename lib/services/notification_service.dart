import 'package:drift/drift.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/database_provider.dart';

class NotificationService {
  NotificationService._();

  /// ساخت یه اعلان جدید
  static Future<int> create({
    required String title,
    required String body,
    required String type,
    String? payload,
  }) async {
    final id = await database
        .into(database.notifications)
        .insert(
          NotificationsCompanion.insert(
            title: title,
            body: body,
            type: type,
            payload: Value(payload),
            createdAt: DateTime.now(),
          ),
        );
    notificationsTicker.value++;
    return id;
  }

  /// همه‌ی اعلان‌ها (جدیدترین اول)
  static Stream<List<AppNotification>> watchAll() {
    final q = database.select(database.notifications)
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    return q.watch();
  }

  /// تعداد اعلان‌های خونده‌نشده
  static Stream<int> watchUnreadCount() {
    final count = database.notifications.id.count();
    final q = database.selectOnly(database.notifications)
      ..addColumns([count])
      ..where(database.notifications.isRead.equals(false));
    return q.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// علامت‌گذاری یه اعلان به‌عنوان خونده‌شده
  static Future<void> markAsRead(int id) async {
    await (database.update(database.notifications)
          ..where((n) => n.id.equals(id)))
        .write(const NotificationsCompanion(isRead: Value(true)));
    notificationsTicker.value++;
  }

  /// علامت‌گذاری همه به‌عنوان خونده‌شده
  static Future<void> markAllAsRead() async {
    await database
        .update(database.notifications)
        .write(const NotificationsCompanion(isRead: Value(true)));
    notificationsTicker.value++;
  }

  /// حذف یه اعلان
  static Future<void> delete(int id) async {
    await (database.delete(
      database.notifications,
    )..where((n) => n.id.equals(id))).go();
    notificationsTicker.value++;
  }

  /// حذف همه‌ی اعلان‌ها
  static Future<void> clearAll() async {
    await database.delete(database.notifications).go();
    notificationsTicker.value++;
  }
}
