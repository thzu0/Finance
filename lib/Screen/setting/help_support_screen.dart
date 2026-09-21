// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Helpsupportscreen extends StatelessWidget {
  const Helpsupportscreen({super.key});

  // TODO: آدرس‌های واقعی پشتیبانی رو بذار
  static const String _supportEmail = 'support@minty.app';
  static const String _supportTelegram = '@minty_support';

  // TODO: متن جواب‌ها رو با رفتار واقعی اپ هماهنگ کن
  static const List<(String, String)> _faq = [
    (
      'چطور یه تراکنش جدید ثبت کنم؟',
      'از صفحه‌ی اصلی روی «افزودن هزینه» یا «افزودن درآمد» بزن، مبلغ و دسته رو انتخاب کن و ذخیره کن.',
    ),
    (
      'چطور برای یه دسته بودجه تعیین کنم؟',
      'تو صفحه‌ی بودجه روی دکمه‌ی + بزن، دسته رو انتخاب کن و سقف ماهانه‌ش رو وارد کن. از اون به بعد پیشرفتش رو تو همون صفحه می‌بینی.',
    ),
    (
      'رنگ نوار بودجه یعنی چی؟',
      'سبز یعنی هنوز زیر ۸۰٪ سقف هستی، زرد یعنی به سقف نزدیک شدی و قرمز یعنی از سقف رد شدی.',
    ),
    (
      'تحلیل‌ها چطور حساب می‌شن؟',
      'تو صفحه‌ی تحلیل‌ها خرجت رو با دوره‌ی قبل مقایسه می‌کنیم و سهم هر دسته رو تو دونات نشون می‌دیم. با تب هفته، ماه و سال بازه رو عوض می‌کنی.',
    ),
  ];

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showGlassSnack(context, 'کپی شد');
  }

  Future<void> _sendFeedback(BuildContext context) async {
    final v = await showGlassForm(
      context,
      title: 'ارسال بازخورد',
      confirmText: 'ارسال',
      fields: const [GlassFormField(label: 'پیامت رو بنویس', maxLines: 5)],
      validate: (v) => v[0].isEmpty ? 'پیام نمی‌تونه خالی باشه' : null,
    );
    if (v == null || !context.mounted) return;
    // TODO: ارسال واقعی بازخورد
    showGlassSnack(context, 'ممنون از بازخوردت');
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'راهنما و پشتیبانی',
      children: [
        const SectionLabel('سوالات متداول'),
        GlassGroup(
          children: [
            for (final f in _faq)
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  iconColor: kSectionBlue,
                  collapsedIconColor: Constans.textSecondary,
                  expandedAlignment: AlignmentDirectional.centerStart,
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(f.$1, style: glassText(16)),
                  children: [
                    Text(
                      f.$2,
                      style: glassText(14, color: Constans.textSecondary),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SectionLabel('تماس با ما'),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.mail_outline,
              title: 'ایمیل پشتیبانی',
              subtitle: _supportEmail,
              onTap: () => _copy(context, _supportEmail),
              trailing: Icon(
                Icons.copy_rounded,
                color: Constans.textSecondary,
                size: 20,
              ),
            ),
            GlassTile(
              icon: Icons.send_outlined,
              title: 'تلگرام',
              subtitle: _supportTelegram,
              onTap: () => _copy(context, _supportTelegram),
              trailing: Icon(
                Icons.copy_rounded,
                color: Constans.textSecondary,
                size: 20,
              ),
            ),
            GlassTile(
              icon: Icons.rate_review_outlined,
              title: 'ارسال بازخورد',
              subtitle: 'نظر و پیشنهادت رو برامون بنویس',
              onTap: () => _sendFeedback(context),
            ),
          ],
        ),
      ],
    );
  }
}
