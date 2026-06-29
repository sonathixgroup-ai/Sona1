// 📁 lib/presentation/thix_sante/common/screens/_components/pregnancy_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PregnancyContent extends ConsumerStatefulWidget {
  const PregnancyContent({Key? key}) : super(key: key);

  @override
  ConsumerState<PregnancyContent> createState() => _PregnancyContentState();
}

class _PregnancyContentState extends ConsumerState<PregnancyContent> {
  DateTime? _dueDate;
  int _currentWeek = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Information principale
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade700, Colors.pink.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.pregnant_woman, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  'Semaine $_currentWeek',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_dueDate != null)
                  Text(
                    'Accouchement prévu: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: GestureDetector(
                    onTap: () => _selectDueDate(),
                    child: Text(
                      _dueDate == null ? 'Définir la date prévue' : 'Modifier la date',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.pink.shade700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Évolution du bébé
          const Text(
            '👶 Évolution cette semaine',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
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
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.height, size: 24, color: Colors.pink),
                          const SizedBox(height: 4),
                          Text('Taille', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Text('42 cm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.fitness_center, size: 24, color: Colors.pink),
                          const SizedBox(height: 4),
                          Text('Poids', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Text('1.5 kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(Icons.favorite, size: 24, color: Colors.pink),
                          const SizedBox(height: 4),
                          Text('Battements', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          const Text('140/min', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  'Cette semaine, votre bébé commence à ouvrir les yeux et réagit à la lumière.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Rendez-vous importants
          const Text(
            '📅 Rendez-vous importants',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildAppointmentCard('Échographie du 2ème trimestre', 'Semaine 22', Icons.ultrasound, Colors.blue),
          _buildAppointmentCard('Test du diabète gestationnel', 'Semaine 24-28', Icons.science, Colors.orange),
          _buildAppointmentCard('Consultation prénatale', 'Semaine 30', Icons.local_hospital, Colors.green),

          const SizedBox(height: 20),

          // Conseils
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Conseil de la semaine',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Buvez beaucoup d\'eau et reposez-vous sur le côté gauche',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 200)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 300)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _currentWeek = ((DateTime.now().difference(picked.add(const Duration(days: -280))).inDays) / 7).floor();
        if (_currentWeek < 0) _currentWeek = 0;
        if (_currentWeek > 40) _currentWeek = 40;
      });
    }
  }

  Widget _buildAppointmentCard(String title, String week, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(week, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }
}
