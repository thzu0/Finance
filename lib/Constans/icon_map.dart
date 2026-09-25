import 'package:flutter/material.dart';

const Map<String, IconData> kIconMap = {
  'restaurant': Icons.restaurant,
  'directions_car': Icons.directions_car,
  'shopping_bag': Icons.shopping_bag,
  'movie': Icons.movie,
  'health_and_safety': Icons.health_and_safety,
  'receipt_long': Icons.receipt_long,
  'school': Icons.school,
  'more_horiz': Icons.more_horiz,
  'account_balance_wallet': Icons.account_balance_wallet,
  'laptop_mac': Icons.laptop_mac,
  'card_giftcard': Icons.card_giftcard,
  'trending_up': Icons.trending_up,
};

/// اسم رشته‌ای → آیکون واقعی (برای نمایش توی UI)
IconData iconFromName(String name) => kIconMap[name] ?? Icons.category_outlined;

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
