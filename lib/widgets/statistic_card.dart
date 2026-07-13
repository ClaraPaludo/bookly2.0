import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class StatisticCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatisticCard({
    super.key,
    required this.value,
    required this.label,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 76,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.subtitle, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
