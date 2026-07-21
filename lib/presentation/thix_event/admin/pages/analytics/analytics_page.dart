// lib/presentation/thix_event/admin/pages/analytics/analytics_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../widgets/admin_app_bar.dart';
import '../../widgets/admin_stat_card.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Variables pour les KPIs
  double _fillRate = 0.0;
  double _avgCart = 0.0;
  double _noShowRate = 0.0;
  double _avgRevenuePerEvent = 0.0;

  // Variables pour le graphique
  List<FlSpot> _revenueSpots = [];
  List<String> _dateLabels = [];
  double _maxRevenueY = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1️⃣ Appel RPC pour les statistiques globales (KPIs)
      final statsResponse = await supabase.rpc('get_dashboard_stats');
      
      // 2️⃣ Appel RPC pour les données du graphique (7 derniers jours)
      final chartResponse = await supabase.rpc('get_revenue_chart_data', params: {'days': 7});

      if (mounted) {
        setState(() {
          // Parsing des KPIs
          if (statsResponse != null) {
            _fillRate = (statsResponse['fill_rate'] ?? 0.0).toDouble();
            _avgCart = (statsResponse['avg_cart'] ?? 0.0).toDouble();
            _noShowRate = (statsResponse['no_show_rate'] ?? 0.0).toDouble();
            _avgRevenuePerEvent = (statsResponse['revenue_per_event'] ?? 0.0).toDouble();
          }

          // Parsing des données du graphique
          if (chartResponse != null && chartResponse is List) {
            _revenueSpots.clear();
            _dateLabels.clear();
            double maxY = 0.0;

            for (int i = 0; i < chartResponse.length; i++) {
              final item = chartResponse[i];
              final dateStr = item['date_day'].toString();
              final revenue = (item['daily_revenue'] ?? 0.0).toDouble();

              if (revenue > maxY) maxY = revenue;

              // Formatage de la date (ex: "12 Mar")
              final DateTime parsedDate = DateTime.parse(dateStr);
              _dateLabels.add(DateFormat('dd MMM', 'fr').format(parsedDate));
              _revenueSpots.add(FlSpot(i.toDouble(), revenue));
            }
            
            // On donne un peu de marge au dessus du graphique
            _maxRevenueY = maxY > 0 ? maxY * 1.2 : 100.0; 
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M FC';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k FC';
    }
    return '${amount.toStringAsFixed(0)} FC';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: const AdminAppBar(title: 'Analytics • Performance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A1F44)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Erreur de chargement des données', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1F44))),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAnalytics,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A1F44)),
                        child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFF0A1F44),
                  onRefresh: _fetchAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // 🟢 KPIs DYNAMIQUES
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          AdminStatCard(
                            label: 'Taux remplissage',
                            value: '${_fillRate.toStringAsFixed(1)}%',
                            icon: Icons.pie_chart_rounded,
                          ),
                          AdminStatCard(
                            label: 'Panier moyen',
                            value: _formatCurrency(_avgCart),
                            icon: Icons.shopping_cart_rounded,
                          ),
                          AdminStatCard(
                            label: 'No-show (Absences)',
                            value: '${_noShowRate.toStringAsFixed(1)}%',
                            icon: Icons.person_off_rounded,
                          ),
                          AdminStatCard(
                            label: 'Revenu / Événement',
                            value: _formatCurrency(_avgRevenuePerEvent),
                            icon: Icons.trending_up_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🟢 GRAPHIQUE DES REVENUS (FL_CHART)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE7EEFC)),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF0A1F44).withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bar_chart_rounded, color: Color(0xFF0A1F44), size: 18),
                                SizedBox(width: 8),
                                Text('Revenus des 7 derniers jours', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0A1F44))),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            SizedBox(
                              height: 220,
                              child: _revenueSpots.isEmpty
                                  ? const Center(child: Text('Aucune donnée pour cette période.', style: TextStyle(color: Color(0xFF7386A8), fontSize: 12)))
                                  : LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: _maxRevenueY > 0 ? _maxRevenueY / 4 : 1,
                                          getDrawingHorizontalLine: (value) => FlLine(color: const Color(0xFFE7EEFC), strokeWidth: 1),
                                        ),
                                        titlesData: FlTitlesData(
                                          show: true,
                                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              interval: 1,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index >= 0 && index < _dateLabels.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 10.0),
                                                    child: Text(
                                                      _dateLabels[index],
                                                      style: const TextStyle(color: Color(0xFF7386A8), fontSize: 10, fontWeight: FontWeight.w600),
                                                    ),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: _maxRevenueY > 0 ? _maxRevenueY / 4 : 1,
                                              reservedSize: 40,
                                              getTitlesWidget: (value, meta) {
                                                if (value == 0) return const SizedBox.shrink();
                                                return Text(
                                                  _formatCurrency(value),
                                                  style: const TextStyle(color: Color(0xFF7386A8), fontSize: 9, fontWeight: FontWeight.w600),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        minX: 0,
                                        maxX: (_dateLabels.length - 1).toDouble(),
                                        minY: 0,
                                        maxY: _maxRevenueY,
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: _revenueSpots,
                                            isCurved: true,
                                            color: const Color(0xFF6B3CE2), // THIX Primary
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(show: true),
                                            belowBarData: BarAreaData(
                                              show: true,
                                              color: const Color(0xFF6B3CE2).withOpacity(0.1),
                                            ),
                                          ),
                                        ],
                                        lineTouchData: LineTouchData(
                                          touchTooltipData: LineTouchTooltipData(
                                            getTooltipColor: (touchedSpot) => const Color(0xFF0A1F44),
                                            getTooltipItems: (touchedSpots) {
                                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                                return LineTooltipItem(
                                                  '${_dateLabels[touchedSpot.x.toInt()]}\n',
                                                  const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  children: [
                                                    TextSpan(
                                                      text: '${touchedSpot.y.toStringAsFixed(0)} FC',
                                                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w900),
                                                    ),
                                                  ],
                                                );
                                              }).toList();
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
