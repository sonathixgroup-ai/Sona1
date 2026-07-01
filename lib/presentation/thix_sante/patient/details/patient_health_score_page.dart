// presentation/thix_sante/patient/details/patient_health_score_page.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientHealthScorePage extends StatefulWidget {
  const PatientHealthScorePage({super.key});

  @override
  State<PatientHealthScorePage> createState() =>
      _PatientHealthScorePageState();
}

class _PatientHealthScorePageState extends State<PatientHealthScorePage> {
  final HealthService _healthService = HealthService.instance;
  bool _isLoading = true;
  String? _error;
  HealthSummary? _summary;
  List<VitalSign> _vitals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

      final summary = await _healthService.fetchHealthSummary(patientId);
      final vitals = await _healthService.fetchVitalSigns(patientId);

      setState(() {
        _summary = summary;
        _vitals = vitals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Score de santé'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
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
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _summary == null
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Score principal
                          _buildScoreCard(),
                          const SizedBox(height: 20),

                          // Détails des composantes du score
                          _buildScoreComponents(),
                          const SizedBox(height: 20),

                          // Évolution des constantes
                          _buildVitalsChart(),
                          const SizedBox(height: 20),

                          // Conseils personnalisés
                          _buildTips(),
                          const SizedBox(height: 20),

                          // Bouton retour
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text('Retour'),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildScoreCard() {
    final score = _summary!.healthScore;
    final color = _scoreColor(score);
    final label = _scoreLabel(score);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Votre score de santé global',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '$score%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Mis à jour le ${_formatDate(_summary!.lastUpdate)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreComponents() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du score',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _componentRow(
              'Consultations cette année',
              _summary!.consultationsThisYear,
              _summary!.consultationsThisYear > 5 ? 'Bon' : 'À améliorer',
              _summary!.consultationsThisYear > 5 ? Colors.green : Colors.orange,
            ),
            _componentRow(
              'Examens complétés',
              _summary!.examsCompleted,
              _summary!.examsCompleted > 3 ? 'Bon' : 'À améliorer',
              _summary!.examsCompleted > 3 ? Colors.green : Colors.orange,
            ),
            _componentRow(
              'Médicaments actifs',
              _summary!.activeMedications,
              _summary!.activeMedications > 0 ? 'Suivi' : 'Aucun',
              _summary!.activeMedications > 0 ? Colors.blue : Colors.grey,
            ),
            _componentRow(
              'Rendez-vous à venir',
              _summary!.upcomingAppointments,
              _summary!.upcomingAppointments > 0 ? 'Planifié' : 'Aucun',
              _summary!.upcomingAppointments > 0 ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _componentRow(String label, int value, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsChart() {
    if (_vitals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Prendre les 7 dernières constantes de poids (ou autre)
    final weightVitals = _vitals
        .where((v) => v.type == VitalType.weight)
        .take(7)
        .toList()
        .reversed
        .toList();

    if (weightVitals.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = weightVitals.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.value,
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évolution du poids',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2,
                  maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weightVitals.length) {
                            return Text(
                              '${weightVitals[index].date.day}/${weightVitals[index].date.month}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF2563FF),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2563FF).withOpacity(0.2),
                      ),
                    ),
                  ],
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTips() {
    final score = _summary!.healthScore;
    String tip;
    if (score >= 80) {
      tip = 'Excellent ! Continuez à maintenir une bonne hygiène de vie et suivez vos rendez-vous médicaux.';
    } else if (score >= 60) {
      tip = 'Vous êtes sur la bonne voie. Pensez à consulter régulièrement votre médecin et à suivre vos traitements.';
    } else if (score >= 40) {
      tip = 'Des efforts sont nécessaires. Prenez rendez-vous avec votre médecin pour un bilan complet.';
    } else {
      tip = 'Il est important de consulter rapidement un médecin pour évaluer votre état de santé.';
    }

    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Conseil personnalisé',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tip,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'À surveiller';
  }
}
