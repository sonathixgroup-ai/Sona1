// presentation/thix_sante/doctor/doctor_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';
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
      final user = AuthController.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final doctorId = user.id;
      final today = DateTime.now();
      final appts = await _service.fetchDoctorAppointmentsForDay(doctorId, today);
      final patientsCount = await _service.fetchDoctorDistinctPatientsCount(doctorId);
      final teleCount = await _service.fetchDoctorPendingTeleexpertiseCount(doctorId);
      final alertsCount = await _service.fetchDoctorCriticalAlertsCount(doctorId);
      final recentPatients = _deriveRecentPatients(appts);

      if (!mounted) return;
      setState(() {
        _patientsCount = patientsCount;
        _appointmentsToday = appts.length;
        _pendingTeleexpertise = teleCount;
        _criticalAlerts = alertsCount;
        _todayAppointments = appts;
        _recentPatients = recentPatients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DoctorDashboard: load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Doctor> _deriveRecentPatients(List<Appointment> appts) {
    final seen = <String>{};
    final res = <Doctor>[];
    for (final a in appts) {
      final pid = (a.patientId ?? '').trim();
      if (pid.isEmpty || !seen.add(pid)) continue;
      final name = (a.patientName ?? '').trim();
      final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
      final first = parts.isNotEmpty ? parts.first : 'Patient';
      final last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      res.add(Doctor(id: pid, firstName: first, lastName: last, specialty: ''));
      if (res.length >= 5) break;
    }
    return res;
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
                        onSwitchRoleTap: () => _openRoleSwitchSheet(context),
                        onNotificationsTap: () {
                          // Notifications
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),
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
                          _buildTodayAppointments(),
                          const SizedBox(height: 16),
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
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.go('/sante/doctor/care');
          } else if (index == 2) {
            _showQuickActions(context);
          } else if (index == 3) {
            context.go('/sante/doctor/connect');
          } else if (index == 4) {
            context.go('/sante/doctor/profile');
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/sante/doctor/consult');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openRoleSwitchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThixRole>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _RoleSwitchSheet(currentRole: ThixRole.doctor),
    );

    if (selected == null || selected == ThixRole.doctor) return;
    await _selectRoleAndNavigate(context, selected);
  }

  Future<void> _selectRoleAndNavigate(BuildContext context, ThixRole role) async {
    try {
      ThixRoleController.instance.selectRole(role, manual: true);
      try {
        await Supabase.instance.client.auth.updateUser(UserAttributes(data: {'thix_role': role.name}));
      } catch (e) {
        debugPrint('THIX Santé: role metadata update failed: $e');
      }

      if (!context.mounted) return;
      switch (role) {
        case ThixRole.patient:
          context.go('/sante/patient/dashboard');
        case ThixRole.doctor:
          context.go('/sante/doctor/dashboard');
        case ThixRole.pharmacy:
          context.go('/sante/pharmacy/dashboard');
      }
    } catch (e, st) {
      debugPrint('THIX Santé: selectRoleAndNavigate failed: $e');
      debugPrint(st.toString());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(HealthConstants.errorGeneric), backgroundColor: Colors.red),
      );
    }
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
                  context.push('/sante/doctor/agenda');
                },
              ),
            )),
        if (_todayAppointments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Aucun rendez-vous aujourd\'hui.', style: TextStyle(color: Colors.grey)),
          ),
        TextButton(
          onPressed: () => context.push('/sante/doctor/agenda'),
          child: const Text('Voir l\'agenda complet'),
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
                context.push('/sante/doctor/patient/${patient.id}', extra: patient);
              },
            )),
        TextButton(
          onPressed: () => context.push('/sante/doctor/patients'),
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
                context.pop();
                context.push('/sante/doctor/patient/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt, color: Colors.green),
              title: const Text('Nouvelle prescription'),
              onTap: () {
                context.pop();
                context.push('/sante/doctor/prescription/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Téléconsultation'),
              onTap: () {
                context.pop();
                context.push('/sante/doctor/teleconsult');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSwitchSheet extends StatelessWidget {
  final ThixRole currentRole;
  const _RoleSwitchSheet({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Changer de rôle', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Quitter le mode médecin et accéder à un autre espace.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor)),
            const SizedBox(height: 12),
            for (final role in ThixRoleController.availableRoles)
              _RoleTile(role: role, selected: role == currentRole, onTap: () => context.pop(role)),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final ThixRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTile({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? role.accent : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: role.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
              child: Icon(role.icon, color: role.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(role.shortLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: HealthConstants.primaryColor),
          ],
        ),
      ),
    );
  }
}
