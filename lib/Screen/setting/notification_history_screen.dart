// ignore: file_names
import 'package:drift/drift.dart' hide Column;
import 'package:finance/Constans/constans.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum _Menu { select, readAll, clearAll }

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

  // حالت انتخاب چندتایی
  bool _selectMode = false;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
    notificationsTicker.addListener(_onTicker);
  }

  @override
  void dispose() {
    notificationsTicker.removeListener(_onTicker);
    super.dispose();
  }

  // رفرش بی‌صدا: با هر تغییر، اسپینر لودینگ پرش نکنه
  void _onTicker() => _load(silent: true);

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final q = database.select(database.notifications)
        ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
      final items = await q.get();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
        // انتخاب‌هایی که دیگه وجود ندارن حذف بشن
        _selected.removeWhere((id) => !items.any((n) => n.id == id));
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

  // ─── تست (فقط توی دیباگ نشون داده می‌شه) ───
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
    notificationsTicker.value++;
  }

  // ═════════════════════════════════════════════
  // حذف
  // ═════════════════════════════════════════════

  /// حذف یک یا چند اعلان، با امکان «برگردون».
  /// اول از لیست محلی برمی‌داریم (Dismissible همین رو لازم داره)، بعد از دیتابیس.
  Future<void> _deleteWithUndo(List<AppNotification> removed) async {
    if (removed.isEmpty) return;
    final ids = removed.map((n) => n.id).toList();

    setState(() {
      _items = _items.where((n) => !ids.contains(n.id)).toList();
      _selected.removeAll(ids);
    });

    await (database.delete(
      database.notifications,
    )..where((x) => x.id.isIn(ids))).go();
    notificationsTicker.value++;
    if (!mounted) return;

    final label = removed.length == 1
        ? 'اعلان پاک شد'
        : '${removed.length} اعلان پاک شد'.farsiNumber;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16265E),
          // SnackBarهای دارای action به‌صورت پیش‌فرض خودبه‌خود بسته نمی‌شن
          persist: false,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: kAccent.withValues(alpha: 0.5)),
          ),
          content: Text(
            label,
            textDirection: TextDirection.rtl,
            style: glassText(15),
          ),
          action: SnackBarAction(
            label: 'برگردون',
            textColor: kAccent,
            onPressed: () => _undo(removed),
          ),
        ),
      );
  }

  Future<void> _undo(List<AppNotification> removed) async {
    // همون id و تاریخ قبلی برمی‌گرده، پس ترتیب لیست عوض نمی‌شه
    await database.batch(
      (b) => b.insertAll(
        database.notifications,
        removed,
        mode: InsertMode.insertOrReplace,
      ),
    );
    notificationsTicker.value++;
  }

  Future<void> _deleteSelected() async {
    final removed = _items.where((n) => _selected.contains(n.id)).toList();
    setState(() => _selectMode = false);
    await _deleteWithUndo(removed);
  }

  Future<void> _clearAll() async {
    final ok = await showGlassConfirm(
      context,
      title: 'پاک کردن همه‌ی اعلان‌ها',
      message: 'همه‌ی اعلان‌های تاریخچه پاک می‌شن و برگشتی نداره. مطمئنی؟',
      confirmText: 'پاک کن',
      danger: true,
    );
    if (!ok || !mounted) return;

    await database.delete(database.notifications).go();
    notificationsTicker.value++;
    if (!mounted) return;
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
    showGlassSnack(context, 'همه‌ی اعلان‌ها پاک شد');
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    await (database.update(database.notifications)
          ..where((x) => x.id.equals(n.id)))
        .write(const NotificationsCompanion(isRead: Value(true)));
    notificationsTicker.value++;
  }

  Future<void> _markAllRead() async {
    await (database.update(database.notifications)
          ..where((x) => x.isRead.equals(false)))
        .write(const NotificationsCompanion(isRead: Value(true)));
    notificationsTicker.value++;
  }

  // ═════════════════════════════════════════════
  // انتخاب
  // ═════════════════════════════════════════════
  void _enterSelection([AppNotification? first]) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectMode = true;
      if (first != null) _selected.add(first.id);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggle(AppNotification n) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(n.id)) _selected.add(n.id);
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selected.length == _items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_items.map((n) => n.id));
      }
    });
  }

  // ═════════════════════════════════════════════
  // UI
  // ═════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // دکمه‌ی برگشت اول از حالت انتخاب خارج می‌شه
      canPop: !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelection();
      },
      child: GlassPage(
        title: 'اعلان‌ها',
        leading: _buildMenu(),
        children: [
          // ─── لودینگ ───
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          // ─── خطا ───
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'خطا: $_error',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: kDanger,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _load,
                    child: const Text(
                      'دوباره امتحان کن',
                      style: TextStyle(fontFamily: 'Vazirmatn'),
                    ),
                  ),
                ],
              ),
            )
          // ─── خالی ───
          else if (_items.isEmpty)
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
          // ─── لیست ───
          else ...[
            _buildHeader(),
            GlassGroup(children: [for (final n in _items) _buildRow(n)]),
            if (!_selectMode)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Text(
                  'برای حذف، اعلان رو بکش یا نگه دار',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: Constans.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 100),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(AppNotification n) {
    final tile = _NotificationTile(
      notification: n,
      icon: _iconFor(n.type),
      color: _colorFor(n.type),
      relativeTime: _relativeTime(n.createdAt).farsiNumber,
      selecting: _selectMode,
      selected: _selected.contains(n.id),
      onTap: () => _selectMode ? _toggle(n) : _markAsRead(n),
      onLongPress: () => _selectMode ? _toggle(n) : _enterSelection(n),
    );

    // توی حالت انتخاب، کشیدن خاموشه تا با تیک زدن قاطی نشه
    if (_selectMode) return KeyedSubtree(key: ValueKey(n.id), child: tile);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.horizontal,
      background: _swipeBg(Alignment.centerRight),
      secondaryBackground: _swipeBg(Alignment.centerLeft),
      onDismissed: (_) => _deleteWithUndo([n]),
      child: tile,
    );
  }

  Widget _swipeBg(Alignment alignment) {
    return Container(
      color: kDanger.withValues(alpha: 0.2),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Icon(Icons.delete_outline, color: kDanger),
    );
  }

  Widget _buildHeader() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selectMode ? _selectionHeader() : _normalHeader(),
    );
  }

  Widget _normalHeader() {
    final unread = _items.where((n) => !n.isRead).length;
    final summary = unread > 0
        ? '${_items.length} اعلان، $unread تا خوانده‌نشده'
        : '${_items.length} اعلان';

    return Padding(
      key: const ValueKey('normal'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary.farsiNumber,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                color: Constans.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// منوی سه‌نقطه توی AppBar (سمت چپ)؛ توی حالت انتخاب یا لیست خالی نیست
  Widget? _buildMenu() {
    if (_loading || _error != null || _items.isEmpty || _selectMode) {
      return null;
    }
    final unread = _items.where((n) => !n.isRead).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GlassBox(
          height: 44,
          width: 44,
          radius: 14,
          child: PopupMenuButton<_Menu>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, size: 22, color: Constans.textPrimary),
            color: kDialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: kAccent.withValues(alpha: 0.5)),
            ),
            onSelected: (m) {
              switch (m) {
                case _Menu.select:
                  _enterSelection();
                  break;
                case _Menu.readAll:
                  _markAllRead();
                  break;
                case _Menu.clearAll:
                  _clearAll();
                  break;
              }
            },
            itemBuilder: (_) => [
              _menuItem(_Menu.select, Icons.checklist_rtl, 'انتخاب'),
              _menuItem(
                _Menu.readAll,
                Icons.done_all,
                'همه رو خوانده کن',
                enabled: unread > 0,
              ),
              _menuItem(
                _Menu.clearAll,
                Icons.delete_sweep_outlined,
                'پاک کردن همه',
                color: kDanger,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_Menu> _menuItem(
    _Menu value,
    IconData icon,
    String label, {
    bool enabled = true,
    Color? color,
  }) {
    final c = color ?? Constans.textPrimary;
    return PopupMenuItem<_Menu>(
      value: value,
      enabled: enabled,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 10),
            Text(label, style: glassText(15, color: c)),
          ],
        ),
      ),
    );
  }

  Widget _selectionHeader() {
    final count = _selected.length;
    final all = count == _items.length;

    return Padding(
      key: const ValueKey('selection'),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _exitSelection,
            icon: const Icon(Icons.close, color: Constans.textSecondary),
          ),
          Expanded(
            child: Text(
              '$count انتخاب شده'.farsiNumber,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Constans.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: _toggleAll,
            child: Text(
              all ? 'برداشتن همه' : 'انتخاب همه',
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: count == 0 ? null : _deleteSelected,
            icon: Icon(
              Icons.delete_outline,
              color: count == 0 ? Constans.textSecondary : kDanger,
            ),
          ),
        ],
      ),
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
  final bool selecting;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.relativeTime,
    required this.selecting,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final leadColor = selecting
        ? (selected ? kAccent : Constans.textSecondary)
        : color;
    final leadIcon = selecting
        ? (selected ? Icons.check_circle : Icons.radio_button_unchecked)
        : icon;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? kAccent.withValues(alpha: 0.1)
              : notification.isRead
              ? Colors.transparent
              : color.withValues(alpha: 0.05),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: leadColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(leadIcon, size: 20, color: leadColor),
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
                      if (!notification.isRead && !selecting)
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
