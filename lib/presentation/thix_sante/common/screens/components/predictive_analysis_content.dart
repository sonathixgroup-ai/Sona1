// 📁 lib/presentation/thix_sante/common/screens/_components/predictive_analysis_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/ai_provider.dart';
import '../../../providers/constant_provider.dart';
import '../../../providers/symptom_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/health_card.dart';

class PredictiveAnalysisContent extends ConsumerStatefulWidget {
  const PredictiveAnalysisContent({Key? key}) : super(key: key);

  @override
  ConsumerState<PredictiveAnalysisContent> createState() => _PredictiveAnalysisContentState();
}

class _PredictiveAnalysisContentState extends ConsumerState<PredictiveAnalysisContent> {
  Map<String, dynamic>? _prediction;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrediction();
  }

  Future<void> _loadPrediction() async {
    setState(() => _isLoading = true);
    final result = await ref.read(aiProvider.notifier).getPredictiveAnalysis();
    if (result != null && mounted) {
      setState(() => _prediction = result);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final constants = ref.watch(constantProvider).valueOrNull;
    final symptoms = ref.watch(symptomProvider).valueOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score de santé global
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Score de santé global',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _prediction?['healthScore']?.toString() ?? '--',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_prediction?['healthScore'] ?? 0) / 100,
                  backgroundColor: Colors.white30,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Risques détectés
          const Text(
            '⚠️ Risques détectés',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_prediction?['risks'] != null && _prediction!['risks'].isNotEmpty)
            ...(_prediction!['risks'] as List).map((risk) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Icon(
                    _getRiskIcon(risk['severity']),
                    color: _getRiskColor(risk['severity']),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          risk['name'],
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          risk['description'],
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getRiskColor(risk['severity']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${risk['probability']}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _getRiskColor(risk['severity'])),
                    ),
                  ),
                ],
              ),
            ))
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun risque majeur détecté. Continuez à suivre votre santé.',
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Recommandations
          const Text(
            '📋 Recommandations personnalisées',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_prediction?['recommendations'] != null)
            ...(_prediction!['recommendations'] as List).map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )),

          const SizedBox(height: 20),
          GradientButton(
            text: 'Actualiser l\'analyse',
            onPressed: _loadPrediction,
            isLoading: _isLoading,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  IconData _getRiskIcon(String severity) {
    switch (severity) {
      case 'high': return Icons.warning;
      case 'medium': return Icons.info_outline;
      default: return Icons.check_circle_outline;
    }
  }

  Color _getRiskColor(String severity) {
    switch (severity) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.green;
    }
  }
}
