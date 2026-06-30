// presentation/thix_sante/doctor/doctor_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_header.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  final HealthService _service = HealthService.instance;
  bool _isLoading = true;
  int _patientsCount = 0;
  int _appointmentsToday = 0;
  int _pendingTeleexpertise = 0;
  int _criticalAlerts = 0;
  List<Appointment> _todayAppointments = [];
  List<Doctor> _recentPatients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Simuler des données (à remplacer par de vraies API)
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _patientsCount = 156;
        _appointmentsToday = 12;
        _pendingTeleexpertise = 3;
        _criticalAlerts = 2;
        _todayAppointments = [
          Appointment(
            id: 'a1',
            doctorId: 'doc1',
            doctorName: 'Dr. Dupont',
            patientId: 'p1',
            patientName: 'Michel L.',
            date: DateTime.now().add(const Duration(hours: 1)),
            type: AppointmentType.inPerson,
            status: AppointmentStatus.confirmed,
          ),
          Appointment(
            id: 'a2',
            doctorId: 'doc1',
            doctorName: 'Dr. Dupont',
            patientId: 'p2',
            patientName: 'Sophie M.',
            date: DateTime.now().add(const Duration(hours: 3)),
            type: AppointmentType.teleconsultation,
            status: AppointmentStatus.scheduled,
            teleconsultationLink: 'https://meet.jit.si/consult12',
          ),
        ];
        _recentPatients = [
          Doctor(id: 'p1', firstName: 'Michel', lastName: 'L.', specialty: 'Patient'),
          Doctor(id: 'p2', firstName: 'Sophie', lastName: 'M.', specialty: 'Patient'),
          Doctor(id: 'p3', firstName: 'Jean', lastName: 'P.', specialty: 'Patient'),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: HealthHeader(
                        role: ThixRole.doctor,
                        onNotificationsTap: () {
                          context.push('/sante/doctor/notifications');
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
                          // Cartes statistiques
                          Row(
                            children: [
                              Expanded(
                                child: _statCard('Patients', _patientsCount.toString(), Icons.people, Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard('RDV aujourd\'hui', _appointmentsToday.toString(), Icons.calendar_today, Colors.green),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _statCard('Téléexpertises', _pendingTeleexpertise.toString(), Icons.medical_services, Colors.purple),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _statCard('Alertes', _criticalAlerts.toString(), Icons.warning, Colors.red),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Rendez-vous du jour
                          _buildTodayAppointments(),
                          const SizedBox(height: 16),
                          // Patients récents
                          _buildRecentPatients(),
                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 0, // Accueil
        onTap: (index) {
          if (index == 1) {
            context.go('/sante/doctor/care');
          } else if (index == 2) {
            _showQuickActions(context);
          } else if (index == 3) {
            context.go('/sante/doctor/messages');
          } else if (index == 4) {
            context.go('/sante/doctor/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sante/doctor/consultation/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rendez-vous du jour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._todayAppointments.map((appt) => Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: appt.type == AppointmentType.teleconsultation ? Colors.purple : Colors.blue,
                  child: Icon(appt.type == AppointmentType.teleconsultation ? Icons.videocam : Icons.person, color: Colors.white),
                ),
                title: Text(appt.patientName ?? 'Patient'),
                subtitle: Text('${appt.date.hour}h${appt.date.minute.toString().padLeft(2, '0')} • ${appt.type.name}'),
                trailing: Chip(
                  label: Text(
                    appt.status == AppointmentStatus.confirmed ? 'Confirmé' : 'Planifié',
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: appt.status == AppointmentStatus.confirmed ? Colors.green : Colors.orange,
                ),
                onTap: () {
                  context.push('/sante/doctor/appointment/${appt.id}', extra: appt);
                },
              ),
            )),
        if (_todayAppointments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun rendez-vous aujourd\'hui.', style: TextStyle(color: Colors.grey)),
          ),
      ],
    );
  }

  Widget _buildRecentPatients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patients récents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._recentPatients.map((patient) => ListTile(
              leading: CircleAvatar(child: Text(patient.firstName[0])),
              title: Text('${patient.firstName} ${patient.lastName}'),
              subtitle: Text('Dernière consultation : il y a 2 jours'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/sante/doctor/patient/${patient.id}');
              },
            )),
        TextButton(
          onPressed: () {
            context.push('/sante/doctor/patients');
          },
          child: const Text('Voir tous les patients'),
        ),
      ],
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('Nouveau patient'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/patient/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Nouvelle prescription'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/prescription/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Téléconsultation'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/doctor/teleconsultation/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}
