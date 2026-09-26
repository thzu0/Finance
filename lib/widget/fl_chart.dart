import 'package:finance/Constans/constans.dart';
import 'package:finance/database/transaction_repository.dart';
import 'package:finance/widget/form_widget.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FlChart extends StatelessWidget {
  final double height;
  final List<TrendPoint> points; // ← تغییر کرد: به‌جای List<double>

  const FlChart({super.key, this.height = 140, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'داده‌ی کافی برای نمودار نیست',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          // ← تغییر کرد: قبلاً enabled: false بود؛ حالا لمس فعاله
          // و یه باکس راهنما (تولتیپ) نشون میده.
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => Constans.background,
              tooltipBorder: BorderSide(
                color: Constans.electricBlue.withValues(alpha: 0.5),
              ),

              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final point = points[spot.x.toInt()];
                  return LineTooltipItem(
                    '\u200F${formatJalali(point.date)}\n', // ← \u200F اضافه شد
                    TextStyle(
                      fontFamily: 'Lalezar',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '\u200F${formatAmount(point.balance.round())} تومان', // ← اینجا هم
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Constans.electricBlue,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                points.length,
                (i) => FlSpot(i.toDouble(), points[i].balance),
              ),
              isCurved: true,
              curveSmoothness: 0.35,
              color: Constans.electricBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) => spot == barData.spots.last,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: Constans.electricBlue,
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Constans.electricBlue.withValues(alpha: 0.35),
                    Constans.electricBlue.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
