// presentation/thix_sante/patient/details/patient_record_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientRecordPage extends StatefulWidget {
  const PatientRecordPage({super.key});

  @override
  State<PatientRecordPage> createState() => _PatientRecordPageState();
}

class _PatientRecordPageState extends State<PatientRecordPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService.instance;
  final SupabaseClient _supabase = SupabaseConfig.client;

  bool _isLoading = true;
  String? _error;

  // Données patient
  String _patientId = '';
  String _patientName = '';
  String _bloodType = '';
  String _allergies = '';
  String _emergencyContact = '';
  String _address = '';

  // Historiques
  List<Appointment> _consultations = [];
  List<ExamResult> _exams = [];
  List<Prescription> _prescriptions = [];
  List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      _patientId = user.id;
      _patientName = user.displayName ?? 'Patient';

      // Récupérer les informations du patient
      final profile = await _supabase
          .from('patient_profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        _bloodType = profile['blood_type'] ?? '';
        _allergies = profile['allergies'] ?? '';
        _emergencyContact = profile['emergency_contact'] ?? '';
        _address = profile['address'] ?? '';
      }

      // Récupérer les données
      final consultations = await _healthService.fetchAppointments(user.id);
      final exams = await _healthService.fetchExamResults(user.id);
      final prescriptions = await _healthService.fetchPrescriptions(user.id);

      // Récupérer les documents uploadés
      try {
        final docs = await _supabase
            .from('patient_records')
            .select('*')
            .eq('patient_id', user.id)
            .order('created_at', ascending: false);
        if (docs is List) {
          _documents = docs.map((e) => e as Map<String, dynamic>).toList();
        }
      } catch (_) {
        _documents = [];
      }

      setState(() {
        _consultations = consultations;
        _exams = exams;
        _prescriptions = prescriptions;
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
        title: const Text('Dossier médical'),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profil'),
            Tab(icon: Icon(Icons.history), text: 'Consultations'),
            Tab(icon: Icon(Icons.science), text: 'Examens'),
            Tab(icon: Icon(Icons.receipt), text: 'Documents'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                        onPressed: _loadData,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProfileTab(),
                    _buildConsultationsTab(),
                    _buildExamsTab(),
                    _buildDocumentsTab(),
                  ],
                ),
    );
  }

  // ============================================================
  // 1. PROFIL
  // ============================================================
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF2563FF).withOpacity(0.1),
                child: Text(
                  _patientName.isNotEmpty ? _patientName[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563FF),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patientName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ID Patient : $_patientId',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Informations personnelles
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow('Groupe sanguin', _bloodType.isNotEmpty ? _bloodType : 'Non renseigné'),
                  _divider(),
                  _infoRow('Allergies', _allergies.isNotEmpty ? _allergies : 'Aucune déclarée'),
                  _divider(),
                  _infoRow('Contact d\'urgence', _emergencyContact.isNotEmpty ? _emergencyContact : 'Non renseigné'),
                  _divider(),
                  _infoRow('Adresse', _address.isNotEmpty ? _address : 'Non renseignée'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Bouton pour ajouter au dossier
          ElevatedButton.icon(
            onPressed: () {
              context.push('/sante/patient/record/add');
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563FF),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. CONSULTATIONS
  // ============================================================
  Widget _buildConsultationsTab() {
    if (_consultations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucune consultation enregistrée.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _consultations.length,
      itemBuilder: (context, index) {
        final appt = _consultations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _statusColor(appt.status),
              child: Icon(
                _statusIcon(appt.status),
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              appt.doctorName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${appt.doctorSpecialty ?? 'Généraliste'} • ${DateFormat('dd/MM/yyyy').format(appt.date)}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/sante/patient/consultation/${appt.id}');
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // 3. EXAMENS
  // ============================================================
  Widget _buildExamsTab() {
    if (_exams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun examen enregistré.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Icon(
              exam.status == ExamStatus.completed
                  ? Icons.check_circle
                  : Icons.pending,
              color: exam.status == ExamStatus.completed
                  ? Colors.green
                  : Colors.orange,
            ),
            title: Text(
              exam.examName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${exam.status == ExamStatus.completed ? 'Terminé' : 'En attente'} • ${DateFormat('dd/MM/yyyy').format(exam.date)}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/sante/patient/exam/${exam.id}');
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // 4. DOCUMENTS
  // ============================================================
  Widget _buildDocumentsTab() {
    if (_documents.isEmpty && _prescriptions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Aucun document enregistré.',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Ajoutez des documents via le bouton "+".',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _documents.length + _prescriptions.length,
      itemBuilder: (context, index) {
        // Afficher d'abord les documents uploadés, puis les ordonnances
        if (index < _documents.length) {
          final doc = _documents[index];
          return _buildDocumentItem(
            title: doc['title'] ?? 'Document',
            subtitle: doc['record_type'] ?? 'Autre',
            date: DateTime.parse(doc['created_at'] as String),
            icon: Icons.insert_drive_file,
          );
        } else {
          final presc = _prescriptions[index - _documents.length];
          return _buildDocumentItem(
            title: 'Ordonnance du ${DateFormat('dd/MM/yyyy').format(presc.date)}',
            subtitle: 'Dr. ${presc.doctorName} • ${presc.medications.length} médicament(s)',
            date: presc.date,
            icon: Icons.receipt_long,
            isPrescription: true,
            prescriptionId: presc.id,
          );
        }
      },
    );
  }

  Widget _buildDocumentItem({
    required String title,
    required String subtitle,
    required DateTime date,
    required IconData icon,
    bool isPrescription = false,
    String? prescriptionId,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2563FF)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$subtitle • ${DateFormat('dd/MM/yyyy').format(date)}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (isPrescription && prescriptionId != null) {
            context.push('/sante/patient/prescription/$prescriptionId');
          } else {
            // Pour les documents, on pourrait ouvrir un aperçu
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aperçu du document à implémenter')),
            );
          }
        },
      ),
    );
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.grey[200],
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
}
