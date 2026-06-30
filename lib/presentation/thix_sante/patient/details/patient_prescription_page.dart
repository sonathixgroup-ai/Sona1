// presentation/thix_sante/patient/details/patient_prescription_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientPrescriptionPage extends StatefulWidget {
  final String prescriptionId;

  const PatientPrescriptionPage({super.key, required this.prescriptionId});

  @override
  State<PatientPrescriptionPage> createState() =>
      _PatientPrescriptionPageState();
}

class _PatientPrescriptionPageState extends State<PatientPrescriptionPage> {
  final HealthService _healthService = HealthService.instance;
  bool _isLoading = true;
  Prescription? _prescription;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      final patientId = user.id;
      final prescriptions = await _healthService.fetchPrescriptions(patientId);
      final found = prescriptions.firstWhere(
        (p) => p.id == widget.prescriptionId,
        orElse: () => throw Exception('Ordonnance introuvable'),
      );
      setState(() {
        _prescription = found;
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
        title: const Text('Détail ordonnance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // TODO: exporter en PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export PDF à implémenter')),
              );
            },
          ),
        ],
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
                        onPressed: _loadPrescription,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _prescription == null
                  ? const Center(child: Text('Aucune ordonnance trouvée'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _prescription!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Card(
            color: p.isExpired ? Colors.grey[100] : Colors.green[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    p.isExpired ? Icons.cancel : Icons.check_circle,
                    color: p.isExpired ? Colors.red : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.isExpired ? 'Ordonnance expirée' : 'Ordonnance active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.isExpired ? Colors.red : Colors.green,
                        ),
                      ),
                      Text(
                        'Délivrée le ${_formatDate(p.date)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Informations générales
          _sectionTitle('Informations'),
          const SizedBox(height: 8),
          _infoRow('Patient', p.patientName ?? 'Inconnu'),
          _infoRow('Médecin', p.doctorName),
          _infoRow('Date de prescription', _formatDate(p.date)),
          if (p.validUntil != null)
            _infoRow('Valable jusqu\'au', _formatDate(p.validUntil!)),
          _infoRow('Statut', p.status.name),
          if (p.notes != null) _infoRow('Notes', p.notes!),
          const SizedBox(height: 20),

          // Médicaments
          _sectionTitle('Médicaments prescrits'),
          const SizedBox(height: 8),
          ...p.medications.map((med) => _MedicationTile(medication: med)),
          if (p.medications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucun médicament enregistré pour cette ordonnance.',
                style: TextStyle(color: Colors.grey),
              ),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _MedicationTile extends StatelessWidget {
  final Medication medication;

  const _MedicationTile({required this.medication});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text(
          medication.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${medication.dosage} • ${medication.frequency}'),
            if (medication.instructions != null)
              Text(
                medication.instructions!,
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
          ],
        ),
        trailing: medication.isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.cancel, color: Colors.grey),
        onTap: () {
          context.push('/sante/patient/medication/${medication.id}');
        },
      ),
    );
  }
}
