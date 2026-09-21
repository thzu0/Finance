// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/extentions/extentions.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class Aboutscreen extends StatelessWidget {
  const Aboutscreen({super.key});

  // TODO: اسم و نسخه‌ی واقعی برنامه
  static const String _appName = 'Minty';
  static const String _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'درباره‌ی ما',
      children: [
        const SizedBox(height: 8),
        // لوگو
        Center(
          child: GlassBox(
            height: 96,
            width: 96,
            radius: 30,
            child: const Icon(
              Icons.diamond_outlined,
              size: 48,
              color: kSectionBlue,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(child: Text(_appName, style: glassText(36))),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'کنترل آینده‌ی مالیت دست خودته',
            style: glassText(16, color: Constans.textSecondary),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: GlassBox(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              'نسخه ${_version.farsiNumber}',
              style: glassText(14, color: Constans.textSecondary),
            ),
          ),
        ),
        const SectionLabel('درباره‌ی برنامه'),
        GlassBox(
          padding: const EdgeInsets.all(16),
          child: Text(
            'مینتی کمکت می‌کنه خرج و درآمدت رو ثبت کنی، برای هر دسته بودجه بذاری و ببینی پولت کجا می‌ره؛ همه‌ی اینا تو یه برنامه‌ی ساده و روان.',
            style: glassText(15, color: Constans.textSecondary),
          ),
        ),
        const SectionLabel('امکانات'),
        const GlassGroup(
          children: [
            GlassTile(
              icon: Icons.receipt_long_outlined,
              title: 'ثبت سریع درآمد و هزینه',
            ),
            GlassTile(
              icon: Icons.pie_chart_outline,
              title: 'بودجه‌بندی برای هر دسته',
            ),
            GlassTile(icon: Icons.insights, title: 'تحلیل و مقایسه‌ی خرج‌ها'),
            GlassTile(icon: Icons.flag_outlined, title: 'هدف‌های مالی'),
          ],
        ),
        const SectionLabel('بیشتر'),
        GlassGroup(
          children: [
            GlassTile(
              icon: Icons.description_outlined,
              title: 'مجوزهای متن‌باز',
              onTap: () => showLicensePage(
                context: context,
                applicationName: _appName,
                applicationVersion: _version,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ساخته‌شده با عشق',
              style: glassText(14, color: Constans.textSecondary),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.favorite, color: kDanger, size: 16),
          ],
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '© ۱۴۰۵ $_appName',
            style: glassText(13, color: Constans.textSecondary),
          ),
        ),
      ],
    );
  }
}
