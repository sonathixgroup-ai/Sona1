// presentation/thix_sante/patient/details/patient_vital_chart_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientVitalChartPage extends StatefulWidget {
  const PatientVitalChartPage({super.key});

  @override
  State<PatientVitalChartPage> createState() => _PatientVitalChartPageState();
}

class _PatientVitalChartPageState extends State<PatientVitalChartPage> {
  final HealthService _healthService = HealthService.instance;
  List<VitalSign> _allVitals = [];
  VitalType _selectedType = VitalType.weight;
  bool _isLoading = true;
  String? _error;

  // Valeurs min/max pour l'affichage
  double _minY = 0;
  double _maxY = 100;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      final patientId = user.id;
      final vitals = await _healthService.fetchVitalSigns(patientId);
      setState(() {
        _allVitals = vitals;
        if (_allVitals.isNotEmpty) {
          // Sélectionner le type le plus fréquent ou le premier
          _selectedType = _getMostFrequentType(vitals);
          _computeMinMax(_selectedType);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  VitalType _getMostFrequentType(List<VitalSign> vitals) {
    final counts = <VitalType, int>{};
    for (final v in vitals) {
      counts[v.type] = (counts[v.type] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _computeMinMax(VitalType type) {
    final filtered = _allVitals.where((v) => v.type == type).toList();
    if (filtered.isEmpty) {
      _minY = 0;
      _maxY = 100;
      return;
    }
    final values = filtered.map((v) => v.value).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final margin = (max - min) * 0.2;
    _minY = (min - margin).clamp(0, double.infinity);
    _maxY = max + margin;
    if (_maxY == _minY) {
      _maxY = _minY + 10;
    }
  }

  List<FlSpot> _getSpotsForType(VitalType type) {
    final filtered = _allVitals
        .where((v) => v.type == type)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Si pas de données, retourner quelques points fictifs pour l'exemple
    if (filtered.isEmpty) {
      final now = DateTime.now();
      return [
        FlSpot(0, 0),
        FlSpot(1, 10),
        FlSpot(2, 5),
        FlSpot(3, 15),
      ];
    }

    // Normaliser les dates en nombre de jours depuis le premier
    final firstDate = filtered.first.date;
    final spots = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      final v = filtered[i];
      final days = v.date.difference(firstDate).inDays.toDouble();
      spots.add(FlSpot(days, v.value));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final title = 'Graphique des constantes';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVitals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVitals,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _allVitals.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Aucune constante enregistrée.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Sélecteur de type
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text('Constante : '),
                              Expanded(
                                child: DropdownButton<VitalType>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  items: VitalType.values.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(VitalSign.getVitalLabel(type)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedType = value;
                                        _computeMinMax(value);
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Graphique
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildLineChart(),
                          ),
                        ),
                        // Informations supplémentaires
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _infoChip('Dernière valeur', _getLastValue(_selectedType)),
                              _infoChip('Min', _getMinValue(_selectedType)),
                              _infoChip('Max', _getMaxValue(_selectedType)),
                              _infoChip('Moyenne', _getAverageValue(_selectedType)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            // Naviguer vers l'ajout d'une constante
                            context.push('/sante/patient/vital/new');
                          },
                          child: const Text('Ajouter une constante'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
    );
  }

  Widget _buildLineChart() {
    final spots = _getSpotsForType(_selectedType);
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.isEmpty ? 1 : spots.last.x + 1,
        minY: _minY,
        maxY: _maxY,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                // Afficher les jours
                final days = value.toInt();
                if (days % 5 == 0 || days == 0) {
                  return Text(
                    'J$days',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2563FF),
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2563FF).withOpacity(0.2),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: _getLastValue(_selectedType),
              color: Colors.orange.withOpacity(0.6),
              strokeWidth: 1,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                labelResolver: (line) => 'Dernier',
                style: const TextStyle(color: Colors.orange, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getLastValue(VitalType type) {
    final filtered = _allVitals.where((v) => v.type == type).toList();
    if (filtered.isEmpty) return 0;
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered.first.value;
  }

  double _getMinValue(VitalType type) {
    final filtered = _allVitals.where((v) => v.type == type).toList();
    if (filtered.isEmpty) return 0;
    return filtered.map((v) => v.value).reduce((a, b) => a < b ? a : b);
  }

  double _getMaxValue(VitalType type) {
    final filtered = _allVitals.where((v) => v.type == type).toList();
    if (filtered.isEmpty) return 0;
    return filtered.map((v) => v.value).reduce((a, b) => a > b ? a : b);
  }

  double _getAverageValue(VitalType type) {
    final filtered = _allVitals.where((v) => v.type == type).toList();
    if (filtered.isEmpty) return 0;
    final sum = filtered.map((v) => v.value).reduce((a, b) => a + b);
    return sum / filtered.length;
  }

  Widget _infoChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
