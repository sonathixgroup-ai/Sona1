// 📁 lib/presentation/thix_sante/patient/widgets/health_score_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/providers/ai_provider.dart';

class HealthScoreWidget extends ConsumerStatefulWidget {
  const HealthScoreWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<HealthScoreWidget> createState() => _HealthScoreWidgetState();
}

class _HealthScoreWidgetState extends ConsumerState<HealthScoreWidget> {
  int _score = 78;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchScore();
  }

  Future<void> _fetchScore() async {
    setState(() => _loading = true);
    final analysis = await ref.read(aiProvider).getPredictiveAnalysis();
    if (analysis != null && analysis.containsKey('healthScore')) {
      setState(() => _score = analysis['healthScore']);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Score de santé global', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const CircularProgressIndicator(color: Colors.white)
          else
            Text(
              '$_score/100',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _score / 100,
            backgroundColor: Colors.white30,
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(
            _score >= 70 ? '👍 Bonne santé' : '⚠️ Surveillez vos signes',
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
