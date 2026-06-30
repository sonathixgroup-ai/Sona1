// presentation/thix_sante/patient/details/patient_appointments_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';

class PatientAppointmentsListPage extends StatefulWidget {
  const PatientAppointmentsListPage({super.key});

  @override
  State<PatientAppointmentsListPage> createState() => _PatientAppointmentsListPageState();
}

class _PatientAppointmentsListPageState extends State<PatientAppointmentsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthService _service = HealthService.instance;
  List<Appointment> _appointments = [];
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
      final list = await _service.fetchAppointments('patient-123');
      setState(() {
        _appointments = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Appointment> _getFiltered(AppointmentStatus? status) {
    if (status == null) return _appointments;
    return _appointments.where((a) => a.status == status).toList();
  }

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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(_getFiltered(null).where((a) => a.status == AppointmentStatus.scheduled || a.status == AppointmentStatus.confirmed).toList()),
                  _buildList(_getFiltered(null).where((a) => a.status == AppointmentStatus.completed || a.status == AppointmentStatus.missed).toList()),
                  _buildList(_getFiltered(null).where((a) => a.status == AppointmentStatus.cancelled).toList()),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sante/patient/appointment/new');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(List<Appointment> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Aucun rendez-vous dans cette catégorie.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final appt = items[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: appt.type == AppointmentType.teleconsultation ? Colors.purple : Colors.blue,
              child: Icon(appt.type == AppointmentType.teleconsultation ? Icons.videocam : Icons.person, color: Colors.white),
            ),
            title: Text(appt.doctorName),
            subtitle: Text('${appt.doctorSpecialty ?? 'Généraliste'} • ${appt.formattedDate}'),
            trailing: Icon(
              appt.status == AppointmentStatus.confirmed ? Icons.check_circle : Icons.access_time,
              color: appt.status == AppointmentStatus.confirmed ? Colors.green : Colors.orange,
            ),
            onTap: () {
              context.push('/sante/patient/appointment/${appt.id}', extra: appt);
            },
          ),
        );
      },
    );
  }
}
