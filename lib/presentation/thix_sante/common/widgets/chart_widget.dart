// 📁 lib/presentation/thix_sante/common/widgets/chart_widget.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Graphique de tendance (ligne/barre) pour constantes vitales
class HealthChartWidget extends StatelessWidget {
  final List<FlSpot> spots;
  final String title;
  final String? unit;
  final Color color;
  final double minY;
  final double maxY;
  final bool showBarChart;

  const HealthChartWidget({
    Key? key,
    required this.spots,
    required this.title,
    this.unit,
    this.color = Colors.green,
    this.minY = 0,
    this.maxY = 200,
    this.showBarChart = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Aucune donnée disponible',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: showBarChart
                ? BarChart(
                    BarChartData(
                      barGroups: spots.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.y,
                              color: color,
                              width: 20,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(show: true),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(show: true),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true),
                      minY: minY,
                      maxY: maxY,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
