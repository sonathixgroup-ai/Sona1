// 📁 lib/presentation/thix_sante/common/screens/_components/constants_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/constant_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/chart_widget.dart';
import 'package:fl_chart/fl_chart.dart';

class ConstantsContent extends ConsumerStatefulWidget {
  const ConstantsContent({Key? key}) : super(key: key);

  @override
  ConsumerState<ConstantsContent> createState() => _ConstantsContentState();
}

class _ConstantsContentState extends ConsumerState<ConstantsContent> {
  int _selectedTab = 0;
  final _systolicCtrl = TextEditingController();
  final _diastolicCtrl = TextEditingController();
  final _glycemiaCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  final List<String> _tabs = ['Tension', 'Glycémie', 'Poids'];

  @override
  Widget build(BuildContext context) {
    final constantsAsync = ref.watch(constantProvider);
    final isLoading = ref.watch(constantProvider.notifier).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Formulaire d'ajout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: _tabs.asMap().entries.map((entry) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = entry.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTab == entry.key ? Colors.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            entry.value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedTab == entry.key ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                if (_selectedTab == 0) _buildTensionForm(),
                if (_selectedTab == 1) _buildGlycemiaForm(),
                if (_selectedTab == 2) _buildWeightForm(),
                const SizedBox(height: 12),
                GradientButton(
                  text: 'Enregistrer',
                  onPressed: isLoading ? null : _saveConstant,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Graphique et historique
          const Text(
            '📊 Évolution',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          constantsAsync.when(
            data: (constants) {
              if (constants.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Aucune donnée enregistrée', style: TextStyle(fontSize: 12)),
                  ),
                );
              }
              final spots = List.generate(
                constants.length > 7 ? 7 : constants.length,
                (i) {
                  final c = constants.reversed.toList()[i];
                  double value = 0;
                  if (_selectedTab == 0) value = c.tensionSystolic?.toDouble() ?? 0;
                  else if (_selectedTab == 1) value = c.glycemie?.toDouble() ?? 0;
                  else value = c.poids?.toDouble() ?? 0;
                  return FlSpot(i.toDouble(), value);
                },
              ).reversed.toList();
              return Column(
                children: [
                  HealthChartWidget(
                    spots: spots,
                    title: _tabs[_selectedTab],
                    unit: _selectedTab == 0 ? 'mmHg' : (_selectedTab == 1 ? 'g/L' : 'kg'),
                    color: Colors.green,
                    minY: _selectedTab == 0 ? 60 : (_selectedTab == 1 ? 0.5 : 40),
                    maxY: _selectedTab == 0 ? 200 : (_selectedTab == 1 ? 3 : 150),
                  ),
                  const SizedBox(height: 16),
                  ...constants.reversed.toList().take(10).map((c) => _buildHistoryItem(c)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(fontSize: 12))),
          ),
        ],
      ),
    );
  }

  Widget _buildTensionForm() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _systolicCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Systolique',
              hintText: '120',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _diastolicCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Diastolique',
              hintText: '80',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildGlycemiaForm() {
    return TextField(
      controller: _glycemiaCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Glycémie (g/L)',
        hintText: '1.05',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildWeightForm() {
    return TextField(
      controller: _weightCtrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Poids (kg)',
        hintText: '72.5',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildHistoryItem(dynamic c) {
    String value = '';
    Color color = Colors.green;
    if (_selectedTab == 0) {
      value = '${c.tensionSystolic}/${c.tensionDiastolic} mmHg';
      final syst = c.tensionSystolic ?? 0;
      if (syst > 130) color = Colors.orange;
      if (syst > 160) color = Colors.red;
    } else if (_selectedTab == 1) {
      value = '${c.glycemie} g/L';
      final gly = c.glycemie ?? 0;
      if (gly > 1.10) color = Colors.orange;
      if (gly > 1.26) color = Colors.red;
    } else {
      value = '${c.poids} kg';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                '${c.date.day}/${c.date.month}/${c.date.year}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  void _saveConstant() async {
    double? systolic, diastolic, glycemia, weight;
    if (_selectedTab == 0) {
      systolic = double.tryParse(_systolicCtrl.text);
      diastolic = double.tryParse(_diastolicCtrl.text);
      if (systolic == null || diastolic == null) return;
    } else if (_selectedTab == 1) {
      glycemia = double.tryParse(_glycemiaCtrl.text);
      if (glycemia == null) return;
    } else {
      weight = double.tryParse(_weightCtrl.text);
      if (weight == null) return;
    }
    final success = await ref.read(constantProvider.notifier).addConstant(
      tensionSystolic: systolic,
      tensionDiastolic: diastolic,
      glycemie: glycemia,
      poids: weight,
    );
    if (success && mounted) {
      _systolicCtrl.clear();
      _diastolicCtrl.clear();
      _glycemiaCtrl.clear();
      _weightCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Constante enregistrée'), backgroundColor: Colors.green),
      );
    }
  }
}
