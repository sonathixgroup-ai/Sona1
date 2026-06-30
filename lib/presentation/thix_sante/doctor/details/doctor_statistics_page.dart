// presentation/thix_sante/doctor/details/doctor_statistics_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DoctorStatisticsPage extends StatefulWidget {
  const DoctorStatisticsPage({super.key});

  @override
  State<DoctorStatisticsPage> createState() => _DoctorStatisticsPageState();
}

class _DoctorStatisticsPageState extends State<DoctorStatisticsPage> {
  @override
  Widget build(BuildContext context) {
    final spots = const [
      FlSpot(1, 3),
      FlSpot(2, 5),
      FlSpot(3, 4),
      FlSpot(4, 7),
      FlSpot(5, 6),
      FlSpot(6, 2),
      FlSpot(7, 4),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _statCard('Patients', '156'),
                _statCard('Consultations', '120'),
                _statCard('Téléconsultations', '30'),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Consultations par jour', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 7,
                  minY: 0,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
