import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientPharmacyDetailPage extends StatefulWidget {
  final String pharmacyId;
  const PatientPharmacyDetailPage({super.key, required this.pharmacyId});

  @override
  State<PatientPharmacyDetailPage> createState() => _PatientPharmacyDetailPageState();
}

class _PatientPharmacyDetailPageState extends State<PatientPharmacyDetailPage> {
  late final Future<Pharmacy?> _future;

  @override
  void initState() {
    super.initState();
    _future = HealthService.instance.fetchPharmacyById(widget.pharmacyId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.popOrGo('/sante/patient/map/pharmacy/${Uri.encodeComponent(widget.pharmacyId)}'),
        ),
      ),
      body: FutureBuilder<Pharmacy?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            debugPrint('PatientPharmacyDetailPage error: ${snap.error}');
            return const Center(child: Text('Impossible de charger la pharmacie.'));
          }
          final p = snap.data;
          if (p == null) return const Center(child: Text('Pharmacie introuvable.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(label: Text(p.isOpen ? 'Ouvert' : 'Fermé')),
                  const SizedBox(width: 8),
                  if ((p.phone ?? '').isNotEmpty) Chip(label: Text(p.phone!)),
                ],
              ),
              const SizedBox(height: 16),
              Text(p.address.isEmpty ? 'Adresse non renseignée.' : p.address),
              const SizedBox(height: 16),
              if (p.latitude != null && p.longitude != null)
                Text('Coordonnées: ${p.latitude!.toStringAsFixed(4)}, ${p.longitude!.toStringAsFixed(4)}'),
            ],
          );
        },
      ),
    );
  }
}
