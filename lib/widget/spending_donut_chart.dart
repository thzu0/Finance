import 'dart:math' as math;
import 'package:finance/extentions/extentions.dart';
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
    Color.fromARGB(255, 31, 130, 249), // آبی جیغ
    Color.fromARGB(255, 249, 93, 31), // نارنجی جیغ
    Color.fromARGB(255, 60, 31, 249), // بنفش جیغ
    Color.fromARGB(255, 249, 31, 115), // صورتی جیغ
    Color.fromARGB(255, 249, 179, 31), // کهربایی جیغ
    Color.fromARGB(255, 31, 249, 172), // سبزآبی جیغ
    Color.fromARGB(255, 249, 31, 31), // قرمز جیغ
    Color.fromARGB(255, 56, 31, 249), // بنفش/نیلی جیغ
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image.asset(
                  //   'assets/images/toman_white.png',
                  //   width: 20,
                  //   height: 25,
                  //   filterQuality: FilterQuality.high,
                  // ),
                  SizedBox(width: 4),
                  Text(
                    centerAmount,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Constans.textPrimary,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
              Text(
                centerLabel,
                style: TextStyle(
                  fontSize: 16,
                  color: Constans.textSecondary,
                  fontFamily: 'Lalezar',
                ),
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
// لیبل تو یه خط، درصد ته ردیف جلوی لیبل
// ==========================================
class SpendingLegend extends StatelessWidget {
  final List<SpendingCategory> categories;

  const SpendingLegend({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final colorProvider = CategoryColorProvider();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: categories.map((cat) {
        final color = colorProvider.colorFor(cat.label);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cat.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    color: Constans.textPrimary,
                    fontFamily: 'Lalezar',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${cat.percent.toInt()}%'.farsiNumber,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Constans.textSecondary,
                  fontFamily: 'Vazirmatn',
                ),
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
        Expanded(child: SpendingLegend(categories: categories)),
        const SizedBox(width: 30),
        SpendingDonutChart(
          centerAmount: centerAmount,
          categories: categories,
          size: 180,
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
