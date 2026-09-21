// ignore: file_names
import 'package:finance/Constans/constans.dart';
import 'package:finance/widget/glass_box_widget.dart';

import 'package:flutter/material.dart';

class Languagescreen extends StatefulWidget {
  const Languagescreen({super.key});

  @override
  State<Languagescreen> createState() => _LanguagescreenState();
}

class _LanguagescreenState extends State<Languagescreen> {
  String _selected = 'fa';

  // (کد زبان، اسم به خود زبان، اسم به فارسی)
  static const List<(String, String, String)> _languages = [
    ('fa', 'فارسی', 'Persian'),
    ('en', 'English', 'انگلیسی'),
    ('ar', 'العربية', 'عربی'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'زبان',
      children: [
        const SizedBox(height: 4),
        GlassGroup(
          children: [
            for (final l in _languages)
              GlassTile(
                icon: Icons.language,
                title: l.$2,
                subtitle: l.$3,
                onTap: () {
                  setState(() => _selected = l.$1);
                  // TODO: عوض کردن واقعی زبان و ذخیره‌ی انتخاب
                  showGlassSnack(context, 'زبان روی «${l.$2}» تنظیم شد');
                },
                trailing: Icon(
                  _selected == l.$1
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _selected == l.$1 ? kAccent : Constans.textSecondary,
                  size: 26,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
