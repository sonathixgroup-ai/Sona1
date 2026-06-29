// 📁 lib/presentation/thix_sante/common/screens/medication_reminder_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/medication_provider.dart';
import '../../widgets/pill_badge.dart';
import '../../widgets/gradient_button.dart';

class MedicationReminderScreen extends ConsumerWidget {
  const MedicationReminderScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rappels médicaments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: medicationsAsync.when(
        data: (medications) {
          final active = medications.where((m) => m.isActive).toList();
          if (active.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Aucun rappel actif', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Appuyez sur + pour ajouter', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final med = active[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication, color: Colors.green, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(med.drugName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${med.dosage} • ${med.time.format(context)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          if (med.days.isNotEmpty)
                            Text('Jours: ${med.days.join(", ")}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        PillBadge.success('Actif'),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _deleteMedication(ref, med.id),
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
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final drugCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    TimeOfDay time = TimeOfDay.now();
    List<String> days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nouveau rappel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(
                controller: drugCtrl,
                decoration: const InputDecoration(labelText: 'Médicament', border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                decoration: const InputDecoration(labelText: 'Dosage', border: OutlineInputBorder()),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Heure de prise'),
                trailing: Text(time.format(context), style: const TextStyle(fontSize: 13)),
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: time);
                  if (t != null) setState(() => time = t);
                },
              ),
              const SizedBox(height: 8),
              const Text('Jours', style: TextStyle(fontSize: 12)),
              Wrap(
                spacing: 8,
                children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) {
                  final selected = days.contains(day);
                  return FilterChip(
                    label: Text(day, style: TextStyle(fontSize: 11, color: selected ? Colors.white : Colors.grey.shade700)),
                    selected: selected,
                    onSelected: (s) {
                      setState(() {
                        if (s) days.add(day);
                        else days.remove(day);
                      });
                    },
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: 'Ajouter',
                onPressed: () async {
                  final success = await ref.read(medicationProvider.notifier).addMedication(
                    drugName: drugCtrl.text,
                    dosage: dosageCtrl.text,
                    time: time,
                    days: days,
                    startDate: DateTime.now(),
                    endDate: null,
                  );
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rappel ajouté'), backgroundColor: Colors.green),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMedication(WidgetRef ref, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer ce rappel ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(medicationProvider.notifier).toggleMedication(id, false);
    }
  }
}
