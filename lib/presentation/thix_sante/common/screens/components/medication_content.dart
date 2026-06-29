// 📁 lib/presentation/thix_sante/common/screens/_components/medication_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/medication_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill_badge.dart';

class MedicationContent extends ConsumerStatefulWidget {
  const MedicationContent({Key? key}) : super(key: key);

  @override
  ConsumerState<MedicationContent> createState() => _MedicationContentState();
}

class _MedicationContentState extends ConsumerState<MedicationContent> {
  final _formKey = GlobalKey<FormState>();
  final _drugCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _selectedDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];
  bool _showForm = false;

  final List<String> _allDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final medicationsAsync = ref.watch(medicationProvider);
    final isLoading = ref.watch(medicationProvider.notifier).isLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bouton ajout
          GradientButton(
            text: _showForm ? 'Masquer le formulaire' : '+ Ajouter un médicament',
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: _showForm ? Icons.expand_less : Icons.add,
          ),
          const SizedBox(height: 12),
          // Formulaire
          if (_showForm)
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
                  children: [
                    TextFormField(
                      controller: _drugCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom du médicament',
                        hintText: 'Amoxicilline',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      validator: (v) => v?.isEmpty == true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _dosageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dosage',
                        hintText: '500mg',
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 13),
                      validator: (v) => v?.isEmpty == true ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    // Heure
                    GestureDetector(
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: _time);
                        if (t != null) setState(() => _time = t);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time, size: 18),
                            const SizedBox(width: 8),
                            Text('Prise à: ${_time.format(context)}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Jours
                    Wrap(
                      spacing: 8,
                      children: _allDays.map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey.shade700)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) _selectedDays.add(day);
                              else _selectedDays.remove(day);
                            });
                          },
                          backgroundColor: Colors.grey.shade100,
                          selectedColor: Colors.green,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (d != null) setState(() => _startDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Début: ${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final d = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)), firstDate: DateTime.now(), lastDate: DateTime(2030));
                              if (d != null) setState(() => _endDate = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16),
                                  const SizedBox(width: 8),
                                  Text('Fin: ${_endDate?.day ?? '?'}/${_endDate?.month ?? '?'}/${_endDate?.year ?? '?'}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      text: 'Ajouter',
                      onPressed: isLoading ? null : _saveMedication,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Liste des traitements
          const Text(
            '💊 Traitements en cours',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          medicationsAsync.when(
            data: (medications) {
              final active = medications.where((m) => m.isActive).toList();
              if (active.isEmpty) {
                return const EmptyStateWidget(
                  title: 'Aucun traitement actif',
                  subtitle: 'Ajoutez vos médicaments pour recevoir des rappels',
                  icon: Icons.medication_outlined,
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: active.length,
                itemBuilder: (context, index) {
                  final m = active[index];
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medication, size: 20, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.drugName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              Text('${m.dosage} - ${m.time.format(context)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              if (m.endDate != null)
                                Text('Jusqu\'au ${m.endDate!.day}/${m.endDate!.month}/${m.endDate!.year}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            PillBadge.success('Actif'),
                            const SizedBox(height: 4),
                            IconButton(
                              icon: Icon(Icons.check_circle_outline, size: 18, color: Colors.green.shade300),
                              onPressed: () => _toggleMedication(m.id, false),
                            ),
                          ],
                        ),
                      ],
                    ),
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

  void _saveMedication() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(medicationProvider.notifier).addMedication(
        drugName: _drugCtrl.text,
        dosage: _dosageCtrl.text,
        time: _time,
        days: _selectedDays,
        startDate: _startDate,
        endDate: _endDate,
      );
      if (success && mounted) {
        _drugCtrl.clear();
        _dosageCtrl.clear();
        setState(() => _showForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Médicament ajouté'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _toggleMedication(String id, bool active) async {
    await ref.read(medicationProvider.notifier).toggleMedication(id, active);
  }
}
