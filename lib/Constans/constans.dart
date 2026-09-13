import 'package:flutter/material.dart';

class Constans {
  // =========================
  // Background
  // =========================

  /// بک‌گراند اصلی تمام صفحات
  static const Color background = Color(0xFF080D24);

  /// سطح دوم برای Card ها
  static const Color surface = Color(0xFF0D1638);

  /// سطح روشن‌تر
  static const Color surfaceLight = Color(0xFF12204A);

  // =========================
  // Primary
  // =========================

  /// آبی اصلی اپ
  static const Color primary = Color(0xFF4682FF);

  /// آبی روشن / Glow
  static const Color electricBlue = Color(0xFF287BFF);

  /// بنفش برای Gradient و Accent
  static const Color purple = Color(0xFF713BFF);

  /// Cyan
  static const Color cyan = Color(0xFF16D9D0);

  // =========================
  // Semantic
  // =========================

  /// درآمد / موفقیت / Savings
  static const Color success = Color(0xFF20D99A);

  /// هشدار
  static const Color warning = Color(0xFFFFB82E);

  /// Expense
  static const Color expense = Color(0xFFFF4F7B);

  // =========================
  // Text
  // =========================

  static const Color textPrimary = Color(0xFFF4F7FF);

  static const Color textSecondary = Color(0xFF9AAAD0);

  static const Color textMuted = Color(0xFF6475A3);

  // =========================
  // Border
  // =========================

  static const Color border = Color(0xFF174DCC);
  static const Color borderSoft = Color(0xFF14275A);

  // =========================
  // Gradients
  // =========================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, electricBlue],
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF155BFF), Color(0xFF16BFEA)],
  );
}
