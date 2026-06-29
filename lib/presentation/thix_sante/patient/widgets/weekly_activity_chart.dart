// 📁 lib/presentation/thix_sante/patient/widgets/weekly_activity_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../common/widgets/section_title.dart';

class WeeklyActivityChart extends ConsumerWidget {
  const WeeklyActivityChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Exemple de données (à connecter à un provider d'activité)
    final steps = [8500, 7200, 9800, 5400, 11200, 8900, 7600];
    final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    final spots = List.generate(steps.length, (i) => FlSpot(i.toDouble(), steps[i].toDouble()));

    return Column(
      children: [
        const SectionTitle(title: 'Activité hebdomadaire', showDivider: false),
        const SizedBox(height: 8),
        Container(
          height: 180,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: BarChart(
            BarChartData(
              barGroups: steps.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: Colors.green,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) {
                    return Text('${value.toInt()}', style: const TextStyle(fontSize: 9));
                  }),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < days.length) {
                        return Text(days[index], style: const TextStyle(fontSize: 9));
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text('Pas cette semaine', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
