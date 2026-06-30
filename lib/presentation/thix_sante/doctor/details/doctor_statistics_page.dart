// presentation/thix_sante/doctor/details/doctor_statistics_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class DoctorStatisticsPage extends StatefulWidget {
  const DoctorStatisticsPage({super.key});

  @override
  State<DoctorStatisticsPage> createState() => _DoctorStatisticsPageState();
}

class _DoctorStatisticsPageState extends State<DoctorStatisticsPage> {
  @override
  Widget build(BuildContext context) {
    // Données pour le graphique
    final data = [
      charts.Series<Map<String, dynamic>, int>(
        id: 'Consultations',
        colorFn: (_, __) => charts.ColorUtil.fromDartColor(Colors.blue),
        domainFn: (datum, _) => datum['day'] as int,
        measureFn: (datum, _) => datum['count'] as int,
        data: [
          {'day': 1, 'count': 3},
          {'day': 2, 'count': 5},
          {'day': 3, 'count': 4},
          {'day': 4, 'count': 7},
          {'day': 5, 'count': 6},
          {'day': 6, 'count': 2},
          {'day': 7, 'count': 4},
        ],
      ),
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
              child: charts.LineChart(
                data,
                animate: true,
                defaultRenderer: charts.LineRendererConfig(includePoints: true),
                behaviors: [charts.ChartTitle('Jour', behaviorPosition: charts.BehaviorPosition.bottom)],
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
