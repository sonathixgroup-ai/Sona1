// presentation/thix_sante/patient/details/patient_pharmacy_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientPharmacyDetailPage extends StatefulWidget {
  final String pharmacyId;

  const PatientPharmacyDetailPage({super.key, required this.pharmacyId});

  @override
  State<PatientPharmacyDetailPage> createState() =>
      _PatientPharmacyDetailPageState();
}

class _PatientPharmacyDetailPageState
    extends State<PatientPharmacyDetailPage> {
  final HealthService _healthService = HealthService.instance;
  Pharmacy? _pharmacy;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPharmacy();
  }

  Future<void> _loadPharmacy() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pharmacy = await _healthService.fetchPharmacyById(
        widget.pharmacyId,
      );
      if (pharmacy == null) {
        throw Exception('Pharmacie introuvable');
      }
      setState(() {
        _pharmacy = pharmacy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail pharmacie'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPharmacy,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _pharmacy == null
                  ? const Center(
                      child: Text(
                        'Pharmacie introuvable',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _pharmacy!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et statut
          Card(
            color: p.isOpen ? Colors.green[50] : Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy,
                      color: Color(0xFF2563FF),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.isOpen ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.isOpen ? 'Ouvert' : 'Fermé',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Informations générales
          _sectionTitle('Informations'),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on, 'Adresse', p.address),
          if (p.phone != null)
            _infoRow(Icons.phone, 'Téléphone', p.phone!),
          if (p.email != null)
            _infoRow(Icons.email, 'Email', p.email!),

          const SizedBox(height: 20),

          // Coordonnées GPS (si disponibles)
          if (p.latitude != null && p.longitude != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Localisation'),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Lat : ${p.latitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Lng : ${p.longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: ouvrir Google Maps
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ouverture de l\'itinéraire à implémenter'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Voir l\'itinéraire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Bouton de retour
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
