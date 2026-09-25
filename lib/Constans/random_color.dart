import 'dart:math';
import 'package:flutter/material.dart';

/// یه پالت از رنگ‌های از پیش انتخاب‌شده (خوانا و هماهنگ با ظاهر اپ).
/// به‌جای اینکه واقعاً هر جزء رنگ (R,G,B) رندوم باشه (که ممکنه رنگای
/// زشت یا خیلی تیره/روشن دربیاره)، از بین این پالت یکی رو انتخاب می‌کنیم.
const List<Color> _palette = [
  Color(0xFFFF6B6B),
  Color(0xFF4C7DFF),
  Color(0xFFF97316),
  Color(0xFFE11D48),
  Color(0xFF8B5CF6),
  Color(0xFFEAB308),
  Color(0xFF0EA5E9),
  Color(0xFF2ED8A3),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF59E0B),
  Color(0xFF6366F1),
];

/// بر اساس یه عدد seed (مثلاً id تراکنش)، همیشه همون رنگ رو از پالت
/// برمی‌گردونه. یعنی برای id=5 همیشه همون رنگه، ولی id=6 با احتمال
/// خیلی زیاد رنگ متفاوتی می‌گیره. این باعث میشه رنگ هر تراکنش
/// "به‌نظر رندوم" بیاد ولی هر بار که صفحه rebuild میشه ثابت بمونه
/// (چون واقعاً رندوم نیست، بلکه seed‌شده‌ست).
Color colorForSeed(int seed) {
  // Random(seed) هر بار با همون seed، همون توالی عددی رو میده
  final index = Random(seed).nextInt(_palette.length);
  return _palette[index];
}
