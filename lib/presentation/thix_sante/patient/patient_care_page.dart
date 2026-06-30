// presentation/thix_sante/patient/patient_care_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PatientCarePage extends StatefulWidget {
  const PatientCarePage({super.key});

  @override
  State<PatientCarePage> createState() => _PatientCarePageState();
}

class _PatientCarePageState extends State<PatientCarePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService.instance;

  List<Appointment> _appointments = [];
  List<Prescription> _prescriptions = [];
  List<ExamResult> _examResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      const patientId = 'patient-123';
      final appointments = await _healthService.fetchAppointments(patientId);
      final prescriptions = await _healthService.fetchPrescriptions(patientId);
      final exams = await _healthService.fetchExamResults(patientId);
      setState(() {
        _appointments = appointments;
        _prescriptions = prescriptions;
        _examResults = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes soins'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Rendez-vous'),
            Tab(icon: Icon(Icons.folder_open), text: 'Dossier médical'),
            Tab(icon: Icon(Icons.medical_services), text: 'Téléexpertise'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              context.push('/sante/patient/scan');
            },
            tooltip: 'Scanner une ordonnance',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsTab(),
                  _buildMedicalRecordTab(),
                  _buildTeleexpertiseTab(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showNewAppointmentDialog();
          } else if (_tabController.index == 1) {
            // Ajouter au dossier médical
          } else {
            _requestTeleexpertise();
          }
        },
        icon: Icon(_tabController.index == 0 ? Icons.add : Icons.medical_information),
        label: Text(_tabController.index == 0 ? 'Prendre RDV' : 'Demander avis'),
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go('/sante');
          } else if (index == 2) {
            _showQuickAction(context);
          } else if (index == 3) {
            context.go('/sante/patient/messages');
          } else if (index == 4) {
            context.go('/sante/patient/profile');
          }
        },
      ),
    );
  }

  // ===== Onglet Rendez-vous =====
  Widget _buildAppointmentsTab() {
    if (_appointments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun rendez-vous', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Prenez un rendez-vous avec votre médecin', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    final sorted = List<Appointment>.from(_appointments)
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final appt = sorted[index];
        final isTeleconsult = appt.type == AppointmentType.teleconsultation || appt.type == AppointmentType.teleexpertise;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isTeleconsult ? Colors.purple : Colors.blue,
                      child: Icon(isTeleconsult ? Icons.videocam : Icons.medical_services, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(appt.doctorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${appt.doctorSpecialty ?? 'Généraliste'} • ${appt.relativeDate}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appt.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_getStatusLabel(appt.status), style: TextStyle(color: _getStatusColor(appt.status), fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (appt.notes != null) Text(appt.notes!, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isTeleconsult && appt.teleconsultationLink != null && appt.status == AppointmentStatus.confirmed)
                      ElevatedButton.icon(
                        onPressed: () {
                          context.push('/sante/patient/teleconsultation/${appt.id}', extra: appt.teleconsultationLink);
                        },
                        icon: const Icon(Icons.videocam),
                        label: const Text('Rejoindre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (!isTeleconsult && appt.status == AppointmentStatus.scheduled)
                      OutlinedButton(
                        onPressed: () => _cancelAppointment(appt.id),
                        child: const Text('Annuler'),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        context.push('/sante/patient/appointment/${appt.id}', extra: appt);
                      },
                      child: const Text('Détails'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== Onglet Dossier médical =====
  Widget _buildMedicalRecordTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Ordonnances'),
              Tab(text: 'Examens'),
              Tab(text: 'Historique'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPrescriptionsList(),
                _buildExamsList(),
                _buildMedicalHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionsList() {
    if (_prescriptions.isEmpty) {
      return const Center(child: Text('Aucune ordonnance disponible.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final p = _prescriptions[index];
        return Card(
          elevation: 1,
          child: ListTile(
            leading: const Icon(Icons.receipt_long, color: Colors.blue),
            title: Text('Ordonnance du ${p.date.day}/${p.date.month}/${p.date.year}'),
            subtitle: Text('Dr. ${p.doctorName} • ${p.medications.length} médicaments'),
            trailing: Chip(
              label: Text(p.isExpired ? 'Expirée' : 'Active',
                  style: TextStyle(color: p.isExpired ? Colors.red : Colors.green)),
            ),
            onTap: () {
              context.push('/sante/patient/prescription/${p.id}', extra: p);
            },
          ),
        );
      },
    );
  }

  Widget _buildExamsList() {
    if (_examResults.isEmpty) {
      return const Center(child: Text('Aucun examen enregistré.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _examResults.length,
      itemBuilder: (context, index) {
        final exam = _examResults[index];
        return Card(
          elevation: 1,
          child: ListTile(
            leading: Icon(
              exam.status == ExamStatus.completed ? Icons.check_circle : Icons.pending,
              color: exam.status == ExamStatus.completed ? Colors.green : Colors.orange,
            ),
            title: Text(exam.examName),
            subtitle: Text('${exam.date.day}/${exam.date.month}/${exam.date.year}'),
            trailing: Text(
              exam.status == ExamStatus.completed ? 'Résultat disponible' : 'En attente',
              style: TextStyle(fontSize: 12, color: exam.status == ExamStatus.completed ? Colors.green : Colors.grey),
            ),
            onTap: () {
              if (exam.status == ExamStatus.completed) {
                context.push('/sante/patient/exam/${exam.id}', extra: exam);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildMedicalHistory() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text('Historique médical', style: TextStyle(fontSize: 18)),
          Text('Consultez votre historique complet', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          Text('Antécédents : Aucun signalé'),
          Text('Allergies : Aucune signalée'),
        ],
      ),
    );
  }

  // ===== Onglet Téléexpertise =====
  Widget _buildTeleexpertiseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services, color: Colors.purple, size: 32),
                    SizedBox(width: 12),
                    Text('Téléexpertise', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text('Demandez un avis médical à distance à un spécialiste.',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 16),
                Row(
                  children: [
                    Chip(label: Text('Avis rapide'), avatar: Icon(Icons.speed, size: 16)),
                    SizedBox(width: 8),
                    Chip(label: Text('Spécialistes confirmés'), avatar: Icon(Icons.verified, size: 16)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Vos demandes récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.person, color: Colors.white)),
          title: const Text('Dr. Martin - Cardiologue'),
          subtitle: const Text('Demande en attente de réponse • 2 jours'),
          trailing: const Chip(label: Text('En cours'), backgroundColor: Colors.orange),
        ),
        ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
          title: const Text('Dr. Dubois - Dermatologue'),
          subtitle: const Text('Avis reçu • 5 jours'),
          trailing: const Chip(label: Text('Terminé'), backgroundColor: Colors.green),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _requestTeleexpertise,
            icon: const Icon(Icons.add),
            label: const Text('Demander un avis médical'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // ===== Actions =====
  void _showNewAppointmentDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Prendre un rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Choisissez un type de consultation', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Consultation en présentiel'),
              subtitle: const Text('Chez votre médecin traitant'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/appointment/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Téléconsultation'),
              subtitle: const Text('Via Jitsi, depuis chez vous'),
              onTap: () {
                Navigator.pop(context);
                // Simuler et rediriger vers la page de téléconsultation Jitsi
                context.push('/sante/patient/teleconsultation/demo');
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.orange),
              title: const Text('Téléexpertise'),
              subtitle: const Text('Demande d\'avis à un spécialiste'),
              onTap: () {
                Navigator.pop(context);
                _requestTeleexpertise();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _requestTeleexpertise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demande d\'avis médical'),
        content: const Text('Votre demande de téléexpertise a été transmise à un spécialiste. Vous serez notifié dès qu\'un avis sera disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler le rendez-vous ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirm == true) {
      await _healthService.cancelAppointment(id);
      _loadData();
    }
  }

  void _showQuickAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: const Text('Prendre un rendez-vous'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/appointment/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.purple),
              title: const Text('Scanner une ordonnance'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/scan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.teal),
              title: const Text('Consulter l\'assistant IA'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/ia');
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled: return Colors.blue;
      case AppointmentStatus.confirmed: return Colors.green;
      case AppointmentStatus.completed: return Colors.grey;
      case AppointmentStatus.cancelled: return Colors.red;
      case AppointmentStatus.missed: return Colors.orange;
    }
  }

  String _getStatusLabel(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled: return 'Planifié';
      case AppointmentStatus.confirmed: return 'Confirmé';
      case AppointmentStatus.completed: return 'Terminé';
      case AppointmentStatus.cancelled: return 'Annulé';
      case AppointmentStatus.missed: return 'Non honoré';
    }
  }
}
