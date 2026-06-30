// presentation/thix_sante/patient/details/patient_consultation_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientConsultationPage extends StatefulWidget {
  final String consultationId;

  const PatientConsultationPage({super.key, required this.consultationId});

  @override
  State<PatientConsultationPage> createState() =>
      _PatientConsultationPageState();
}

class _PatientConsultationPageState extends State<PatientConsultationPage> {
  final HealthService _healthService = HealthService.instance;
  bool _isLoading = true;
  Appointment? _consultation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }

  Future<void> _loadConsultation() async {
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
      final appointments = await _healthService.fetchAppointments(patientId);
      final found = appointments.firstWhere(
        (a) => a.id == widget.consultationId,
        orElse: () => throw Exception('Consultation introuvable'),
      );
      setState(() {
        _consultation = found;
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
        title: const Text('Détail consultation'),
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
                        onPressed: _loadConsultation,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _consultation == null
                  ? const Center(child: Text('Aucune consultation trouvée'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final c = _consultation!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person, 'Médecin', c.doctorName),
          _infoRow(
              Icons.medical_services, 'Spécialité', c.doctorSpecialty ?? 'Généraliste'),
          _infoRow(Icons.calendar_today, 'Date', c.formattedDate),
          _infoRow(Icons.videocam, 'Type', c.type.name),
          _infoRow(Icons.info, 'Statut', c.status.name),
          if (c.notes != null) _infoRow(Icons.note, 'Notes', c.notes!),
          if (c.teleconsultationLink != null)
            ListTile(
              leading: const Icon(Icons.link, color: Colors.blue),
              title: const Text('Lien de consultation'),
              subtitle: Text(c.teleconsultationLink!),
              onTap: () {
                context.push(
                  '/sante/patient/teleconsultation/${c.id}',
                  extra: c.teleconsultationLink,
                );
              },
            ),
          const SizedBox(height: 24),
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
