// 📁 lib/presentation/thix_sante/patient/widgets/stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/health_card.dart';
import '../../../common/providers/symptom_provider.dart';
import '../../../common/providers/medication_provider.dart';
import '../../../common/providers/constant_provider.dart';

class StatsCard extends ConsumerWidget {
  const StatsCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symptomsAsync = ref.watch(symptomProvider);
    final medicationsAsync = ref.watch(medicationProvider);
    final constantsAsync = ref.watch(constantProvider);

    int symptomCount = 0;
    if (symptomsAsync.hasValue) symptomCount = symptomsAsync.value!.length;
    int medCount = 0;
    if (medicationsAsync.hasValue) medCount = medicationsAsync.value!.where((m) => m.isActive).length;
    int constantCount = 0;
    if (constantsAsync.hasValue) constantCount = constantsAsync.value!.length;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        HealthCard(
          title: 'Symptômes',
          value: '$symptomCount',
          subtitle: 'enregistrés',
          icon: Icons.sick,
          iconColor: Colors.orange,
        ),
        HealthCard(
          title: 'Traitements',
          value: '$medCount',
          subtitle: 'actifs',
          icon: Icons.medication,
          iconColor: Colors.blue,
        ),
        HealthCard(
          title: 'Constantes',
          value: '$constantCount',
          subtitle: 'mesures',
          icon: Icons.monitor_heart,
          iconColor: Colors.red,
        ),
        HealthCard(
          title: 'Rendez-vous',
          value: '2',
          subtitle: 'à venir',
          icon: Icons.calendar_today,
          iconColor: Colors.purple,
        ),
      ],
    );
  }
}
