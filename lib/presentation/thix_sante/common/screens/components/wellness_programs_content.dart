// 📁 lib/presentation/thix_sante/common/screens/_components/wellness_programs_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WellnessProgramsContent extends ConsumerStatefulWidget {
  const WellnessProgramsContent({Key? key}) : super(key: key);

  @override
  ConsumerState<WellnessProgramsContent> createState() => _WellnessProgramsContentState();
}

class _WellnessProgramsContentState extends ConsumerState<WellnessProgramsContent> {
  final List<Map<String, dynamic>> _programs = [
    {'name': 'Méditation anti-stress', 'duration': '7 jours', 'level': 'Débutant', 'icon': Icons.self_improvement, 'color': Colors.purple},
    {'name': 'Yoga doux', 'duration': '14 jours', 'level': 'Débutant', 'icon': Icons.yoga, 'color': Colors.orange},
    {'name': 'Exercices respiratoires', 'duration': '5 jours', 'level': 'Tous niveaux', 'icon': Icons.air, 'color': Colors.cyan},
    {'name': 'Bien-être au travail', 'duration': '10 jours', 'level': 'Intermédiaire', 'icon': Icons.work, 'color': Colors.teal},
    {'name': 'Sommeil réparateur', 'duration': '21 jours', 'level': 'Débutant', 'icon': Icons.bedtime, 'color': Colors.indigo},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Questionnaire initial
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Programme personnalisé',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Répondez à 5 questions pour un programme sur mesure',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Commencer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '📋 Programmes recommandés',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._programs.map((p) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (p['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(p['icon'], color: p['color'], size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(
                        '${p['duration']} • ${p['level']}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Démarrer',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Challenge de la semaine',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '7 jours sans écran avant le coucher',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                  ),
                  child: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
