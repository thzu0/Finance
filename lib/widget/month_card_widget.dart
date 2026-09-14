import 'package:finance/Constans/constans.dart';
import 'package:flutter/material.dart';

class MonthOverviewCard extends StatelessWidget {
  const MonthOverviewCard({
    super.key,
    required this.icon,
    required this.label,
    required this.amount,
    required this.percent,
    required this.isPositive,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String amount;
  final String percent;
  final bool isPositive;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Constans.border.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 14,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Constans.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              fontFamily: 'Vazirmatn',
              color: Constans.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                percent,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Vazirmatn',
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Constans.success : Constans.expense,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 20,
                color: isPositive ? Constans.success : Constans.expense,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
