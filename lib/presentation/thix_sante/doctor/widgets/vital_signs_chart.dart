// 📁 lib/presentation/thix_sante/doctor/widgets/vital_signs_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../common/widgets/section_title.dart';

class VitalSignsChart extends StatelessWidget {
  final List<FlSpot> systolicSpots;
  final List<FlSpot> diastolicSpots;
  final List<String> labels;

  const VitalSignsChart({
    Key? key,
    required this.systolicSpots,
    required this.diastolicSpots,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          const SectionTitle(title: 'Tension artérielle', showDivider: false),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: systolicSpots,
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: diastolicSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}', style: const TextStyle(fontSize: 9));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Text(labels[index], style: const TextStyle(fontSize: 9));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                minY: 40,
                maxY: 200,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Systolique', Colors.red),
              const SizedBox(width: 16),
              _buildLegend('Diastolique', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
