// presentation/thix_sante/patient/details/patient_appointments_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';

class PatientAppointmentsListPage extends StatefulWidget {
  const PatientAppointmentsListPage({super.key});

  @override
  State<PatientAppointmentsListPage> createState() =>
      _PatientAppointmentsListPageState();
}

class _PatientAppointmentsListPageState
    extends State<PatientAppointmentsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _healthService = HealthService.instance;
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
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
      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Appointment> get _upcoming => _appointments.where((a) =>
      a.status == AppointmentStatus.scheduled ||
      a.status == AppointmentStatus.confirmed).toList();

  List<Appointment> get _past => _appointments.where((a) =>
      a.status == AppointmentStatus.completed ||
      a.status == AppointmentStatus.missed).toList();

  List<Appointment> get _cancelled =>
      _appointments.where((a) => a.status == AppointmentStatus.cancelled).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Passés'),
            Tab(text: 'Annulés'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAppointments,
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
                        onPressed: _loadAppointments,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(_upcoming),
                      _buildList(_past),
                      _buildList(_cancelled),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sante/patient/appointment/new');
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: HealthBottomNav(
        currentIndex: 0, // Accueil
        onTap: (index) {
          if (index == 1) {
            context.go('/sante/patient/health');
          } else if (index == 2) {
            // Nouveau : on ouvre le même écran de création
            context.push('/sante/patient/appointment/new');
          } else if (index == 3) {
            context.go('/sante/patient/messages');
          } else if (index == 4) {
            context.go('/sante/patient/profile');
          }
        },
      ),
    );
  }

  Widget _buildList(List<Appointment> items) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Aucun rendez-vous dans cette catégorie.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Trier par date (plus proche en premier)
    final sorted = List<Appointment>.from(items)
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final appt = sorted[index];
        return _AppointmentCard(appointment: appt);
      },
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isTeleconsult =
        appointment.type == AppointmentType.teleconsultation ||
        appointment.type == AppointmentType.teleexpertise;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          context.push('/sante/patient/appointment/${appointment.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isTeleconsult ? Colors.purple : Colors.blue,
                    child: Icon(
                      isTeleconsult ? Icons.videocam : Icons.person,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          appointment.doctorSpecialty ?? 'Généraliste',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(appointment.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(appointment.status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    appointment.formattedDate,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  if (appointment.teleconsultationLink != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push(
                          '/sante/patient/teleconsultation/${appointment.id}',
                          extra: appointment.teleconsultationLink,
                        );
                      },
                      icon: const Icon(Icons.video_call, size: 16),
                      label: const Text('Rejoindre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              if (appointment.notes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    appointment.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
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
