import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientPrescriptionsListPage extends StatefulWidget {
  const PatientPrescriptionsListPage({super.key});

  @override
  State<PatientPrescriptionsListPage> createState() => _PatientPrescriptionsListPageState();
}

class _PatientPrescriptionsListPageState extends State<PatientPrescriptionsListPage> {
  late final Future<List<Prescription>> _future;

  @override
  void initState() {
    super.initState();
    final uid = AuthController.instance.currentUser?.id;
    _future = uid == null ? Future.value(const []) : HealthService.instance.fetchPrescriptions(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordonnances'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/dashboard'),
        ),
      ),
      body: FutureBuilder<List<Prescription>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('PatientPrescriptionsListPage error: ${snap.error}');
            return const Center(child: Text("Impossible de charger les ordonnances."));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune ordonnance pour le moment.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = items[i];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: Theme.of(context).colorScheme.surface,
                title: Text('Dr ${p.doctorName}'),
                subtitle: Text('Émise le ${p.date.day}/${p.date.month}/${p.date.year} • ${p.medications.length} médicaments'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/sante/patient/prescription/${Uri.encodeComponent(p.id)}'),
              );
            },
          );
        },
      ),
    );
  }
}
