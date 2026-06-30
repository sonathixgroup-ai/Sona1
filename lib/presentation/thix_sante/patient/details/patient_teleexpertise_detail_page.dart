// presentation/thix_sante/patient/details/patient_teleexpertise_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientTeleexpertiseDetailPage extends StatefulWidget {
  final String expertiseId;

  const PatientTeleexpertiseDetailPage({
    super.key,
    required this.expertiseId,
  });

  @override
  State<PatientTeleexpertiseDetailPage> createState() =>
      _PatientTeleexpertiseDetailPageState();
}

class _PatientTeleexpertiseDetailPageState
    extends State<PatientTeleexpertiseDetailPage> {
  final HealthService _healthService = HealthService.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _request;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = await _healthService.fetchTeleexpertiseRequestById(
        widget.expertiseId,
      );

      if (request == null) {
        throw Exception('Demande introuvable');
      }

      setState(() {
        _request = request;
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
        title: const Text('Détail téléexpertise'),
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
                        onPressed: _loadRequest,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _request == null
                  ? const Center(child: Text('Aucune demande trouvée'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final r = _request!;
    final status = (r['status'] as String?)?.toLowerCase() ?? 'pending';
    final createdAt = r['created_at'] != null
        ? DateTime.tryParse(r['created_at'] as String)
        : null;
    final doctorName = r['doctor_name'] as String?;
    final response = r['response'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Card(
            color: _statusColor(status).withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(status),
                        ),
                      ),
                      Text(
                        'Demande du ${createdAt != null ? _formatDate(createdAt) : 'date inconnue'}',
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
          _infoRow('Sujet', r['subject'] ?? 'Sans sujet'),
          if (doctorName != null) _infoRow('Médecin', doctorName),
          if (createdAt != null) _infoRow('Date', _formatDate(createdAt)),
          _infoRow('Statut', _statusLabel(status)),
          if (r['description'] != null) _infoRow('Description', r['description']!),
          const SizedBox(height: 20),

          // Réponse du médecin
          if (response != null && response.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Réponse du médecin'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    response,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Bouton pour re-demander si nécessaire
          if (status == 'completed' || status == 'rejected')
            OutlinedButton.icon(
              onPressed: () {
                // Naviguer vers la page de demande
                context.push('/sante/patient/teleexpertise/request');
              },
              icon: const Icon(Icons.add),
              label: const Text('Faire une nouvelle demande'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

          const SizedBox(height: 12),

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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'in_progress':
        return Icons.medical_services;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Répondu';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }
}
