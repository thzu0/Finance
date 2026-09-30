import 'package:finance/Constans/constans.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:flutter/material.dart';

/// نوشته‌ی واحد پول (تومان یا ریال) بر اساس تنظیمات برنامه.
/// color: 'white' | 'green' | 'red'
/// height فقط برای تعیین اندازه‌ی فونت استفاده میشه (همون پارامتر قبلی).
class CurrencyMark extends StatelessWidget {
  const CurrencyMark({
    super.key,
    this.color = 'white',
    this.width,
    this.height,
  });

  final String color;
  final double? width;
  final double? height;

  Color get _color {
    switch (color) {
      case 'green':
        return Constans.success;
      case 'red':
        return Constans.expense;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = height != null ? height! * 0.6 : 16.0;
    return Text(
      currencyName,
      style: TextStyle(
        fontFamily: 'Lalezar',
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: _color,
      ),
    );
  }
}
