// 📁 lib/presentation/thix_sante/common/screens/_components/symptom_tracker_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/symptom_provider.dart';
import '../../../providers/alert_provider.dart';
import '../../widgets/health_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/empty_state.dart';

class SymptomTrackerContent extends ConsumerStatefulWidget {
  const SymptomTrackerContent({Key? key}) : super(key: key);

  @override
  ConsumerState<SymptomTrackerContent> createState() => _SymptomTrackerContentState();
}

class _SymptomTrackerContentState extends ConsumerState<SymptomTrackerContent> {
  final _formKey = GlobalKey<FormState>();
  String _selectedSymptom = 'Fièvre';
  int _intensity = 3;
  DateTime _date = DateTime.now();
  String? _notes;

  final List<String> _symptomes = [
    'Fièvre', 'Toux', 'Fatigue', 'Maux de tête', 
    'Douleur thoracique', 'Essoufflement', 'Nausées', 
    'Douleur abdominale', 'Courbatures', 'Mal de gorge'
  ];

  final Map<String, IconData> _symptomIcons = {
    'Fièvre': Icons.thermostat,
    'Toux': Icons.medical_services,
    'Fatigue': Icons.bed,
    'Maux de tête': Icons.psychology,
    'Douleur thoracique': Icons.favorite,
    'Essoufflement': Icons.air,
    'Nausées': Icons.sick,
    'Douleur abdominale': Icons.stomach,
    'Courbatures': Icons.fitness_center,
    'Mal de gorge': Icons.health_and_safety,
  };

  @override
  Widget build(BuildContext context) {
    final symptomsAsync = ref.watch(symptomProvider);
    final isLoading = ref.watch(symptomProvider.notifier).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Formulaire d'ajout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 Enregistrer un symptôme',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  // Sélecteur de symptôme
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSymptom,
                      items: _symptomes.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(_symptomIcons[s], size: 18, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(s, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedSymptom = v!),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Intensité
                  Row(
                    children: [
                      Text('Intensité: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Expanded(
                        child: Slider(
                          value: _intensity.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _intensity.toString(),
                          activeColor: Colors.green,
                          onChanged: (v) => setState(() => _intensity = v.round()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getIntensityText(_intensity),
                          style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Date
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            '${_date.day}/${_date.month}/${_date.year}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Notes
                  TextFormField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Notes supplémentaires...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => _notes = v,
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    text: 'Enregistrer',
                    onPressed: isLoading ? null : _saveSymptom,
                    isLoading: isLoading,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Historique
          const Text(
            '📋 Historique des symptômes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          symptomsAsync.when(
            data: (symptoms) {
              if (symptoms.isEmpty) {
                return const EmptyStateWidget(
                  title: 'Aucun symptôme enregistré',
                  subtitle: 'Commencez à suivre vos symptômes ci-dessus',
                  icon: Icons.sick_outlined,
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: symptoms.length,
                itemBuilder: (context, index) {
                  final s = symptoms[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                            color: _getIntensityColor(s.intensity).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _symptomIcons[s.nom] ?? Icons.sick,
                            size: 20,
                            color: _getIntensityColor(s.intensity),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.nom,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                                  Text(
                                    '${s.date.day}/${s.date.month}/${s.date.year}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                  if (s.notes != null && s.notes!.isNotEmpty)
                                    Text(
                                      s.notes!,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getIntensityColor(s.intensity),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getIntensityText(s.intensity),
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade400),
                                  onPressed: () => _deleteSymptom(s.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(fontSize: 12))),
          ),
        ],
      ),
    );
  }

  String _getIntensityText(int intensity) {
    switch (intensity) {
      case 1: return 'Très léger';
      case 2: return 'Léger';
      case 3: return 'Modéré';
      case 4: return 'Fort';
      case 5: return 'Très fort';
      default: return 'Modéré';
    }
  }

  Color _getIntensityColor(int intensity) {
    switch (intensity) {
      case 1: return Colors.green;
      case 2: return Colors.lightGreen;
      case 3: return Colors.orange;
      case 4: return Colors.deepOrange;
      case 5: return Colors.red;
      default: return Colors.orange;
    }
  }

  void _saveSymptom() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(symptomProvider.notifier).addSymptom(
        nom: _selectedSymptom,
        intensité: _intensity,
        date: _date,
        notes: _notes,
      );
      if (success && mounted) {
        _notes = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Symptôme enregistré'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _deleteSymptom(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce symptôme ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(symptomProvider.notifier).deleteSymptom(id);
    }
  }
}
