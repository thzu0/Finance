import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:finance/Constans/constans.dart';

// ==========================================
// مدل دسته‌ی هزینه
// ==========================================
class SpendingCategory {
  final String label;
  final double percent;

  const SpendingCategory({required this.label, required this.percent});
}

// ==========================================
// سیستم رنگ‌دهی خودکار و غیرتکراری
// ==========================================
class CategoryColorProvider {
  static final CategoryColorProvider _instance =
      CategoryColorProvider._internal();
  factory CategoryColorProvider() => _instance;
  CategoryColorProvider._internal();

  final List<Color> _basePalette = const [
    Color(0xFF2A78D6),
    Color(0xFFEB6834),
    Color(0xFF6250D6),
    Color(0xFFE87BA4),
    Color(0xFFEDA100),
    Color(0xFF1BAF7A),
    Color(0xFFE34948),
    Color(0xFF9085E9),
  ];

  final Map<String, Color> _assigned = {};
  int _generatedCount = 0;

  Color colorFor(String categoryKey) {
    if (_assigned.containsKey(categoryKey)) {
      return _assigned[categoryKey]!;
    }
    for (final c in _basePalette) {
      if (!_assigned.values.contains(c)) {
        _assigned[categoryKey] = c;
        return c;
      }
    }
    final hue = (_generatedCount * 137.508) % 360;
    _generatedCount++;
    final newColor = HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
    _assigned[categoryKey] = newColor;
    return newColor;
  }

  void reset() {
    _assigned.clear();
    _generatedCount = 0;
  }
}

// ==========================================
// ویجت اصلی دونات (چارت + عدد وسط)
// ==========================================
class SpendingDonutChart extends StatelessWidget {
  final List<SpendingCategory> categories;
  final String centerAmount;
  final String centerLabel;
  final double size;
  final double seamWidth;

  const SpendingDonutChart({
    super.key,
    required this.categories,
    required this.centerAmount,
    this.centerLabel = 'این ماه',
    this.size = 160,
    this.seamWidth = 0.015,
  });

  @override
  Widget build(BuildContext context) {
    final colorProvider = CategoryColorProvider();
    final colors = categories
        .map((c) => colorProvider.colorFor(c.label))
        .toList();
    final percents = categories.map((c) => c.percent).toList();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutGradientPainter(
              colors: colors,
              percents: percents,
              seamWidth: seamWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerAmount,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Constans.textPrimary,
                ),
              ),
              Text(
                centerLabel,
                style: TextStyle(fontSize: 12, color: Constans.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// لیستِ کنارِ چارت (نقطه‌ی رنگی + اسم + درصد)
// ==========================================
class SpendingLegend extends StatelessWidget {
  final List<SpendingCategory> categories;

  const SpendingLegend({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final colorProvider = CategoryColorProvider();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: categories.map((cat) {
        final color = colorProvider.colorFor(cat.label);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '%${cat.percent.toInt()}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Constans.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                cat.label,
                style: TextStyle(fontSize: 12, color: Constans.textPrimary),
              ),
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ==========================================
// ترکیبِ چارت + لیست کنار هم
// نوشته‌ها (Legend) اول اومدن → سمت چپ
// چارت دوم اومد → سمت راست
// ==========================================
class SpendingOverview extends StatelessWidget {
  final List<SpendingCategory> categories;
  final String centerAmount;

  const SpendingOverview({
    super.key,
    required this.categories,
    required this.centerAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 2, child: SpendingLegend(categories: categories)),
        Expanded(
          flex: 3,
          child: SpendingDonutChart(
            centerAmount: centerAmount,
            categories: categories,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// نقاش گرادیان با گذار نرم فقط سر مرزها
// ==========================================
class _DonutGradientPainter extends CustomPainter {
  final List<Color> colors;
  final List<double> percents;
  final double seamWidth;

  _DonutGradientPainter({
    required this.colors,
    required this.percents,
    required this.seamWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.32;

    final total = percents.reduce((a, b) => a + b);

    final boundaries = <double>[0];
    double cum = 0;
    for (final p in percents) {
      cum += p;
      boundaries.add(cum / total);
    }

    final stops = <double>[];
    final gradientColors = <Color>[];

    for (int i = 0; i < colors.length; i++) {
      final start = boundaries[i];
      final end = boundaries[i + 1];
      stops.add(i == 0 ? 0.0 : start + seamWidth / 2);
      gradientColors.add(colors[i]);
      stops.add(end - seamWidth / 2);
      gradientColors.add(colors[i]);
    }
    stops.add(1.0);
    gradientColors.add(colors.first);

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: gradientColors,
        stops: stops,
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _DonutGradientPainter oldDelegate) => true;
}
