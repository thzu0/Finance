import 'package:finance/Constans/constans.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FlChart extends StatefulWidget {
  final double height;
  const FlChart({super.key, this.height = 140});

  @override
  State<FlChart> createState() => _FlChartState();
}

class _FlChartState extends State<FlChart> {
  @override
  Widget build(BuildContext context) {
    final rawData = [10, 14, 11, 17, 15, 22, 19, 27, 24, 32, 35, 40];

    return SizedBox(
      height: widget.height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                rawData.length,
                (i) => FlSpot(i.toDouble(), rawData[i].toDouble()),
              ),
              isCurved: true,
              curveSmoothness: 0.35,
              color: Constans.electricBlue,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) =>
                    spot ==
                    barData.spots.last, // دات روی نقطه‌ی آخر (سمت چپ چارت)
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
