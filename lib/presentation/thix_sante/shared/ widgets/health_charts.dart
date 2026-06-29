// presentation/thix_sante/shared/widgets/health_charts.dart
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';

/// Graphique à barres simple pour afficher des données de santé
class HealthBarChart extends StatelessWidget {
  final List<BarData> data;
  final String title;
  final Color? barColor;
  final double barWidth;

  const HealthBarChart({
    super.key,
    required this.data,
    required this.title,
    this.barColor,
    this.barWidth = 20,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final color = barColor ?? HealthConstants.primaryColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((bar) {
                final height = maxValue > 0 ? (bar.value / maxValue) * 120 : 0.0;
                return Column(
                  children: [
                    Text(
                      bar.value.toString(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: barWidth,
                      height: height.clamp(0.0, 120.0),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class BarData {
  final String label;
  final double value;

  BarData({required this.label, required this.value});
}

/// Widget pour afficher un indicateur de santé (score, tendance)
class HealthScoreIndicator extends StatelessWidget {
  final int score; // 0-100
  final String label;
  final bool showLabel;

  const HealthScoreIndicator({
    super.key,
    required this.score,
    this.label = 'Score de santé',
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForScore(score);
    final percentage = score.clamp(0, 100);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showLabel)
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Confiance',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForScore(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
