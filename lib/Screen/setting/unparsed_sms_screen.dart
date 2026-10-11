import 'package:drift/drift.dart' hide Column;
import 'package:finance/Constans/constans.dart';
import 'package:finance/database/app_database.dart';
import 'package:finance/database/database_provider.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';
import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

/// پیامک‌های فرستنده‌ی انتخاب‌شده که شبیه تراکنش بودن ولی خونده نشدن
class UnparsedSmsScreen extends StatefulWidget {
  const UnparsedSmsScreen({super.key});

  @override
  State<UnparsedSmsScreen> createState() => _UnparsedSmsScreenState();
}

class _UnparsedSmsScreenState extends State<UnparsedSmsScreen> {
  List<UnparsedSms> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    unparsedSmsTicker.addListener(_load);
  }

  @override
  void dispose() {
    unparsedSmsTicker.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final q = database.select(database.unparsedSmsMessages)
      ..orderBy([(m) => OrderingTerm.desc(m.receivedAt)]);
    final items = await q.get();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  String _formatTime(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${j.year}/${two(j.month)}/${two(j.day)}  ${two(dt.hour)}:${two(dt.minute)}'
        .farsiNumber;
  }

  Future<void> _delete(UnparsedSms item) async {
    await (database.delete(
      database.unparsedSmsMessages,
    )..where((m) => m.id.equals(item.id))).go();
    unparsedSmsTicker.value++;
  }

  Future<void> _clearAll() async {
    final ok = await showGlassConfirm(
      context,
      title: 'پاک کردن همه‌ی پیامک‌های نخونده',
      message: 'همه‌ی این پیامک‌ها از اپ پاک می‌شن و برگشتی نداره. مطمئنی؟',
      confirmText: 'پاک کن',
      danger: true,
    );
    if (!ok || !mounted) return;
    await database.delete(database.unparsedSmsMessages).go();
    unparsedSmsTicker.value++;
    if (!mounted) return;
    showGlassSnack(context, 'همه‌ی پیامک‌ها پاک شد');
  }

  Widget? _buildClearButton() {
    if (_loading || _items.isEmpty) return null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GlassBox(
          height: 44,
          width: 44,
          radius: 14,
          child: IconButton(
            onPressed: _clearAll,
            icon: const Icon(
              Icons.delete_sweep_outlined,
              size: 22,
              color: kDanger,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'پیامک‌های نخونده',
      leading: _buildClearButton(),
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_items.isEmpty)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: Constans.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'پیامک نخونده‌ای نداری',
                    style: glassText(16, color: Constans.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Text(
              '${_items.length} پیامک شبیه تراکنش بود ولی خونده نشد'.farsiNumber,
              style: glassText(14, color: Constans.textSecondary),
            ),
          ),
          GlassGroup(children: [for (final m in _items) _buildRow(m)]),
          const SizedBox(height: 100),
        ],
      ],
    );
  }

  Widget _buildRow(UnparsedSms m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTime(m.receivedAt),
                  style: glassText(13, color: kSectionBlue),
                ),
                const SizedBox(height: 6),
                Text(
                  m.body,
                  style: glassText(15, color: Constans.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _delete(m),
            icon: const Icon(Icons.delete_outline, color: kDanger),
          ),
        ],
      ),
    );
  }
}
