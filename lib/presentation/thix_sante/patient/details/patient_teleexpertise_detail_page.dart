import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientTeleexpertiseDetailPage extends StatefulWidget {
  final String expertiseId;
  const PatientTeleexpertiseDetailPage({super.key, required this.expertiseId});

  @override
  State<PatientTeleexpertiseDetailPage> createState() => _PatientTeleexpertiseDetailPageState();
}

class _PatientTeleexpertiseDetailPageState extends State<PatientTeleexpertiseDetailPage> {
  late final Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = HealthService.instance.fetchTeleexpertiseRequestById(widget.expertiseId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Téléexpertise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/dashboard'),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            debugPrint('PatientTeleexpertiseDetailPage error: ${snap.error}');
            return const Center(child: Text('Impossible de charger la demande.'));
          }
          final m = snap.data;
          if (m == null) {
            return const Center(child: Text('Demande introuvable.'));
          }
          final subject = (m['subject'] as String?)?.trim() ?? 'Téléexpertise';
          final desc = (m['description'] as String?)?.trim();
          final status = (m['status'] as String?)?.trim() ?? 'pending';
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(subject, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text('Statut: $status')),
                  const SizedBox(width: 8),
                  if ((m['doctor_name'] as String?)?.trim().isNotEmpty == true)
                    Chip(label: Text('Dr ${(m['doctor_name'] as String).trim()}')),
                ],
              ),
              const SizedBox(height: 16),
              if (desc != null && desc.isNotEmpty)
                Text(desc, style: Theme.of(context).textTheme.bodyMedium),
              if (desc == null || desc.isEmpty)
                Text('Aucune description fournie.', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/sante/patient/teleexpertise/request'),
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle demande'),
              ),
            ],
          );
        },
      ),
    );
  }
}
