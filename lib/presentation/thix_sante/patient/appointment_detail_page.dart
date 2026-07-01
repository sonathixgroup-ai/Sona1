// presentation/thix_sante/patient/details/patient_appointment_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientAppointmentDetailPage extends StatefulWidget {
  final String appointmentId;

  const PatientAppointmentDetailPage({
    super.key,
    required this.appointmentId,
  });

  @override
  State<PatientAppointmentDetailPage> createState() =>
      _PatientAppointmentDetailPageState();
}

class _PatientAppointmentDetailPageState
    extends State<PatientAppointmentDetailPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  Appointment? _appointment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer le rendez-vous depuis Supabase
      final response = await _supabase
          .from('health_appointments')
          .select('*')
          .eq('id', widget.appointmentId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Rendez-vous introuvable');
      }

      // Convertir en modèle Appointment
      final typeName = (response['type'] as String?) ?? AppointmentType.inPerson.name;
      final statusName = (response['status'] as String?) ?? AppointmentStatus.scheduled.name;

      setState(() {
        _appointment = Appointment(
          id: response['id'] as String,
          doctorId: response['doctor_id'] as String? ?? '',
          doctorName: response['doctor_name'] as String? ?? 'Médecin',
          doctorSpecialty: response['doctor_specialty'] as String?,
          patientId: response['patient_id'] as String? ?? user.id,
          patientName: response['patient_name'] as String?,
          date: DateTime.parse(response['scheduled_at'] as String),
          type: AppointmentType.values.firstWhere(
            (e) => e.name == typeName,
            orElse: () => AppointmentType.inPerson,
          ),
          status: AppointmentStatus.values.firstWhere(
            (e) => e.name == statusName,
            orElse: () => AppointmentStatus.scheduled,
          ),
          notes: response['notes'] as String?,
          teleconsultationLink: response['teleconsultation_link'] as String?,
          isEmergency: response['is_emergency'] as bool? ?? false,
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler le rendez-vous ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirm != true || _appointment == null) return;

    try {
      await _supabase
          .from('health_appointments')
          .update({'status': AppointmentStatus.cancelled.name})
          .eq('id', _appointment!.id);

      // Mettre à jour l'état local
      setState(() {
        _appointment = Appointment(
          id: _appointment!.id,
          doctorId: _appointment!.doctorId,
          doctorName: _appointment!.doctorName,
          doctorSpecialty: _appointment!.doctorSpecialty,
          patientId: _appointment!.patientId,
          patientName: _appointment!.patientName,
          date: _appointment!.date,
          type: _appointment!.type,
          status: AppointmentStatus.cancelled,
          notes: _appointment!.notes,
          teleconsultationLink: _appointment!.teleconsultationLink,
          isEmergency: _appointment!.isEmergency,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rendez-vous annulé'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail rendez-vous'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        actions: [
          if (_appointment != null &&
              _appointment!.status != AppointmentStatus.cancelled &&
              _appointment!.status != AppointmentStatus.completed)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push(
                  '/sante/patient/appointment/${_appointment!.id}?edit=true',
                );
              },
              tooltip: 'Modifier',
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
                        onPressed: _loadAppointment,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _appointment == null
                  ? const Center(child: Text('Aucun rendez-vous trouvé'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _appointment!;
    final isTeleconsult =
        a.type == AppointmentType.teleconsultation ||
        a.type == AppointmentType.teleexpertise;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Card(
            color: _statusColor(a.status).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _statusIcon(a.status),
                    color: _statusColor(a.status),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusLabel(a.status),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(a.status),
                        ),
                      ),
                      Text(
                        '${a.type.name} • ${DateFormat('dd/MM/yyyy').format(a.date)}',
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

          // Informations principales
          _sectionTitle('Informations'),
          const SizedBox(height: 8),
          _infoRow(Icons.person, 'Médecin', a.doctorName),
          _infoRow(
              Icons.medical_services, 'Spécialité', a.doctorSpecialty ?? 'Généraliste'),
          _infoRow(Icons.calendar_today, 'Date', a.formattedDate),
          _infoRow(Icons.videocam, 'Type', a.type.name),
          if (a.isEmergency)
            _infoRow(Icons.emergency, 'Urgence', 'Oui'),
          if (a.notes != null)
            _infoRow(Icons.note, 'Notes', a.notes!),

          const SizedBox(height: 20),

          // Lien de téléconsultation
          if (isTeleconsult && a.teleconsultationLink != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Téléconsultation'),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue[50],
                  child: ListTile(
                    leading: const Icon(Icons.video_call, color: Colors.blue),
                    title: const Text('Rejoindre la consultation'),
                    subtitle: Text(a.teleconsultationLink!),
                    trailing: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/sante/patient/teleconsultation/${a.id}',
                          extra: a.teleconsultationLink,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Rejoindre'),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),

          // Boutons d'action
          if (a.status != AppointmentStatus.cancelled &&
              a.status != AppointmentStatus.completed &&
              a.status != AppointmentStatus.missed)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelAppointment,
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
              ],
            )
          else
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
          SizedBox(
            width: 100,
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

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Colors.blue;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.missed:
        return Colors.orange;
    }
  }

  IconData _statusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return Icons.schedule;
      case AppointmentStatus.confirmed:
        return Icons.check_circle;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
      case AppointmentStatus.missed:
        return Icons.warning;
    }
  }

  String _statusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return 'Planifié';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.missed:
        return 'Non honoré';
    }
  }
}
