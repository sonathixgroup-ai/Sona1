// 📁 lib/presentation/thix_sante/patient/widgets/active_treatments.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/providers/medication_provider.dart';
import '../../../common/widgets/section_title.dart';
import '../../../common/widgets/pill_badge.dart';

class ActiveTreatments extends ConsumerWidget {
  const ActiveTreatments({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationProvider);
    return medicationsAsync.when(
      data: (meds) {
        final active = meds.where((m) => m.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const SectionTitle(title: 'Traitements en cours', seeAllText: 'Voir tout', showDivider: false),
            const SizedBox(height: 8),
            ...active.take(3).map((med) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication, size: 20, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(med.drugName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        Text('${med.dosage} • ${med.time.format(context)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  const PillBadge(text: 'Actif', color: Colors.green),
                ],
              ),
            )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
