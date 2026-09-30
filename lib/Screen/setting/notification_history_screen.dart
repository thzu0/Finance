// ignore: file_names
import 'package:drift/drift.dart' hide Column;
import 'package:finance/Constans/constans.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';

class NotificationsHistoryScreen extends StatefulWidget {
  const NotificationsHistoryScreen({super.key});

  @override
  State<NotificationsHistoryScreen> createState() =>
      _NotificationsHistoryScreenState();
}

class _NotificationsHistoryScreenState
    extends State<NotificationsHistoryScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    notificationsTicker.addListener(_load);
  }

  @override
  void dispose() {
    notificationsTicker.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final q = database.select(database.notifications)
        ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
      final items = await q.get();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'budget':
        return Icons.warning_amber_rounded;
      case 'sms':
        return Icons.sms_outlined;
      case 'daily':
        return Icons.edit_calendar_outlined;
      case 'weekly':
        return Icons.bar_chart;
      case 'monthly':
        return Icons.calendar_month_outlined;
      case 'tips':
        return Icons.lightbulb_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'budget':
        return kDanger;
      case 'sms':
        return kSectionBlue;
      case 'tips':
        return kAccent;
      default:
        return Constans.textSecondary;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'همین الان';
    if (diff.inMinutes < 60) return '${diff.inMinutes} دقیقه پیش';
    if (diff.inHours < 24) return '${diff.inHours} ساعت پیش';
    if (diff.inDays < 7) return '${diff.inDays} روز پیش';
    return '${dt.year}/${dt.month}/${dt.day}';
  }

  Future<void> _addDummy() async {
    final now = DateTime.now();
    final samples = [
      ('daily', 'یادآوری ثبت تراکنش‌ها', 'امروز خرج‌هات رو ثبت کردی؟', now),
      (
        'budget',
        'هشدار بودجه',
        'به ۸۰٪ سقف دسته‌ی خوراک رسیدی',
        now.subtract(const Duration(hours: 3)),
      ),
      (
        'weekly',
        'گزارش هفتگی',
        'این هفته ۱٬۲۰۰٬۰۰۰ تومان خرج کردی',
        now.subtract(const Duration(days: 1)),
      ),
      (
        'tips',
        'پیشنهاد هوشمند',
        'با کم کردن قهوه‌ی بیرون ماهی ۲۰۰ هزار صرفه‌جویی کن',
        now.subtract(const Duration(days: 3)),
      ),
      (
        'sms',
        'تراکنش جدید از پیامک',
        'برداشت ۳۵۰٬۰۰۰ تومان',
        now.subtract(const Duration(minutes: 20)),
      ),
    ];

    for (final s in samples) {
      await database
          .into(database.notifications)
          .insert(
            NotificationsCompanion(
              type: Value(s.$1),
              title: Value(s.$2),
              body: Value(s.$3),
              createdAt: Value(s.$4),
            ),
          );
    }
    notificationsTicker.value++; // لیست خودش رفرش میشه
  }

  Future<void> _clearAll() async {
    final ok = await showGlassConfirm(
      context,
      title: 'پاک کردن همه‌ی اعلان‌ها',
      message: 'همه‌ی اعلان‌های تاریخچه پاک می‌شن. مطمئنی؟',
      confirmText: 'پاک کن',
      danger: true,
    );
    if (!ok) return;

    await database.delete(database.notifications).go();
    notificationsTicker.value++;
    if (!mounted) return;
    showGlassSnack(context, 'همه‌ی اعلان‌ها پاک شد');
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    await (database.update(database.notifications)
          ..where((x) => x.id.equals(n.id)))
        .write(const NotificationsCompanion(isRead: Value(true)));
    notificationsTicker.value++;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'اعلان‌ها',
      children: [
        // TODO: بعد از تست پاک کن
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.bug_report_outlined,
              title: 'تست: افزودن اعلان نمونه',
              onTap: _addDummy,
            ),
          ],
        ),
        // ─── حالت لودینگ ───
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        // ─── حالت خطا ───
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'خطا: $_error',
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                color: kDanger,
                fontSize: 13,
              ),
            ),
          )
        // ─── حالت خالی ───
        else if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Constans.textSecondary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'هنوز اعلانی نداری',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: Constans.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          )
        // ─── لیست اعلان‌ها ───
        else ...[
          GlassGroup(
            children: [
              GlassTile(
                icon: Icons.delete_sweep_outlined,
                title: 'پاک کردن همه‌ی اعلان‌ها',
                subtitle: 'همه‌ی اعلان‌های تاریخچه پاک می‌شن',
                color: kDanger,
                onTap: _clearAll,
              ),
            ],
          ),
          GlassGroup(
            children: [
              for (final n in _items)
                _NotificationTile(
                  notification: n,
                  icon: _iconFor(n.type),
                  color: _colorFor(n.type),
                  relativeTime: _relativeTime(n.createdAt),
                  onTap: () => _markAsRead(n),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════
// آیتم اعلان
// ═════════════════════════════════════════════
class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final Color color;
  final String relativeTime;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.relativeTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : color.withValues(alpha: 0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: Constans.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      color: Constans.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    relativeTime,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: Constans.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
