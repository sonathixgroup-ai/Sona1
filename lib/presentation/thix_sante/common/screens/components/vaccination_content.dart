// 📁 lib/presentation/thix_sante/common/screens/_components/vaccination_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/patient_provider.dart';
import '../../widgets/pill_badge.dart';
import '../../widgets/gradient_button.dart';

class VaccinationContent extends ConsumerStatefulWidget {
  const VaccinationContent({Key? key}) : super(key: key);

  @override
  ConsumerState<VaccinationContent> createState() => _VaccinationContentState();
}

class _VaccinationContentState extends ConsumerState<VaccinationContent> {
  @override
  Widget build(BuildContext context) {
    final vaccinationsAsync = ref.watch(patientVaccinationsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // QR Code pour le carnet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  child: const Icon(Icons.qr_code_scanner, size: 28, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Carnet de vaccination numérique',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Scannez pour partager votre carnet',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                GradientButton(
                  text: 'Voir QR',
                  onPressed: () => _showQrDialog(),
                  width: 100,
                  height: 36,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '📅 Calendrier vaccinal',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          vaccinationsAsync.when(
            data: (vaccinations) {
              final upcoming = vaccinations.where((v) => !v.isDone && v.dueDate.isAfter(DateTime.now())).toList();
              final done = vaccinations.where((v) => v.isDone).toList();

              return Column(
                children: [
                  if (upcoming.isNotEmpty) ...[
                    const Text('À venir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...upcoming.map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.vaccines, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                Text('À faire avant: ${v.dueDate.day}/${v.dueDate.month}/${v.dueDate.year}', style: TextStyle(fontSize: 11, color: Colors.orange.shade700)),
                              ],
                            ),
                          ),
                          PillBadge.warning('À venir'),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                  if (done.isNotEmpty) ...[
                    const Text('Effectués', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...done.map((v) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text('${v.dateDone?.day}/${v.dateDone?.month}/${v.dateDone?.year}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          PillBadge.success('Effectué'),
                        ],
                      ),
                    )),
                  ],
                  if (vaccinations.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('Aucun vaccin enregistré', style: TextStyle(fontSize: 12)),
                      ),
                    ),
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

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('QR Code Vaccination', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.qr_code, size: 150, color: Colors.black)),
            ),
            const SizedBox(height: 16),
            const Text('Scannez ce QR pour accéder au carnet', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
