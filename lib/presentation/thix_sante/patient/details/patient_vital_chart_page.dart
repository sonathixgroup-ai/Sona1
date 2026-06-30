import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/ widgets/health_charts.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientVitalChartPage extends StatefulWidget {
  const PatientVitalChartPage({super.key});

  @override
  State<PatientVitalChartPage> createState() => _PatientVitalChartPageState();
}

class _PatientVitalChartPageState extends State<PatientVitalChartPage> {
  VitalType _type = VitalType.weight;

  @override
  Widget build(BuildContext context) {
    final patientId = AuthController.instance.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphiques'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/dashboard'),
        ),
        actions: [
          PopupMenuButton<VitalType>(
            initialValue: _type,
            onSelected: (v) => setState(() => _type = v),
            itemBuilder: (context) => VitalType.values
                .map((e) => PopupMenuItem(value: e, child: Text(_label(e))))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(_label(_type))),
            ),
          ),
        ],
      ),
      body: patientId == null
          ? const Center(child: Text('Vous devez être connecté.'))
          : FutureBuilder<List<VitalSign>>(
              future: HealthService.instance.fetchVitalSigns(patientId),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  debugPrint('PatientVitalChartPage error: ${snap.error}');
                  return const Center(child: Text('Impossible de charger les constantes.'));
                }
                final all = snap.data ?? const [];
                final vitals = all.where((v) => v.type == _type).toList();
                if (vitals.isEmpty) {
                  return const Center(child: Text('Aucune donnée à afficher.'));
                }

                final last = vitals.take(7).toList().reversed.toList();
                final data = <BarData>[];
                for (final v in last) {
                  data.add(BarData(label: '${v.date.day}/${v.date.month}', value: v.value));
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    HealthBarChart(data: data, title: _label(_type)),
                    const SizedBox(height: 12),
                    ...vitals.take(20).map(
                          (v) => ListTile(
                            title: Text('${v.value} ${v.unit}'.trim()),
                            subtitle: Text('${v.date.day}/${v.date.month}/${v.date.year}'),
                          ),
                        ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/sante/patient/record/add'),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  String _label(VitalType t) {
    switch (t) {
      case VitalType.weight:
        return 'Poids';
      case VitalType.bloodPressureSystolic:
      case VitalType.bloodPressureDiastolic:
        return 'Tension';
      case VitalType.heartRate:
        return 'Fréquence cardiaque';
      case VitalType.temperature:
        return 'Température';
      case VitalType.glucose:
        return 'Glycémie';
      default:
        return VitalSign.getVitalLabel(t);
    }
  }
}
