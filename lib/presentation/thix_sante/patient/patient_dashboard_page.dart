// presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_cards.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_header.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/emergency_button.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_bottom_nav.dart';
import 'package:thix_id/presentation/thix_sante/thix_role.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final HealthService _healthService = HealthService.instance;
  bool _isLoading = true;
  HealthSummary? _summary;
  List<Appointment> _upcomingAppointments = [];
  List<Medication> _currentMedications = [];
  List<HealthArticle> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      const String patientId = 'patient-123';
      final summary = await _healthService.fetchHealthSummary(patientId);
      final appointments = await _healthService.fetchUpcomingAppointments(patientId);
      final medications = await _healthService.fetchMedications(patientId, activeOnly: true);
      final articles = await _healthService.fetchHealthArticles(limit: 3);

      setState(() {
        _summary = summary;
        _upcomingAppointments = appointments;
        _currentMedications = medications;
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement : $e'), backgroundColor: Colors.red),
      );
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
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: HealthHeader(
                        role: ThixRole.patient,
                        onNotificationsTap: () {
                          context.push('/sante/patient/notifications');
                        },
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SizedBox(height: 16),

                          // Résumé de santé
                          if (_summary != null)
                            HealthSummaryCard(
                              consultations: _summary!.consultationsThisYear,
                              exams: _summary!.examsCompleted,
                              medications: _summary!.activeMedications,
                              appointments: _summary!.upcomingAppointments,
                            ),
                          const SizedBox(height: 16),

                          // Score de santé
                          if (_summary != null)
                            HealthScoreIndicator(score: _summary!.healthScore),
                          const SizedBox(height: 16),

                          // Prochains rendez-vous
                          _buildUpcomingAppointments(),
                          const SizedBox(height: 16),

                          // Médicaments en cours
                          _buildCurrentMedications(),
                          const SizedBox(height: 16),

                          // Articles santé
                          _buildHealthArticles(),
                          const SizedBox(height: 16),

                          // Bouton urgence
                          const EmergencyButton(),
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
            context.go('/sante/patient/health');
          } else if (index == 2) {
            _showQuickActions(context);
          } else if (index == 3) {
            context.go('/sante/patient/messages');
          } else if (index == 4) {
            context.go('/sante/patient/profile');
          }
        },
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    if (_upcomingAppointments.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.calendar_today),
          title: Text('Aucun rendez-vous à venir'),
          subtitle: Text('Prenez rendez-vous avec votre médecin'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prochains rendez-vous',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._upcomingAppointments.map((appt) => UpcomingAppointmentCard(
              doctorName: appt.doctorName,
              specialty: appt.doctorSpecialty ?? 'Généraliste',
              date: appt.date,
              onTap: () {
                context.push('/sante/patient/appointment/${appt.id}', extra: appt);
              },
            )),
        if (_upcomingAppointments.length > 3)
          TextButton(
            onPressed: () => context.push('/sante/patient/appointments'),
            child: const Text('Voir tous les rendez-vous'),
          ),
      ],
    );
  }

  Widget _buildCurrentMedications() {
    if (_currentMedications.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.medication),
          title: Text('Aucun médicament en cours'),
          subtitle: Text('Consultez votre médecin pour un traitement'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Médicaments en cours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._currentMedications.take(3).map((med) => Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.medication, color: Colors.blue),
                title: Text(med.name),
                subtitle: Text('${med.dosage} • ${med.frequency}'),
                trailing: med.isActive
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.cancel, color: Colors.grey),
                onTap: () {
                  context.push('/sante/patient/medication/${med.id}', extra: med);
                },
              ),
            )),
        if (_currentMedications.length > 3)
          TextButton(
            onPressed: () => context.push('/sante/patient/medications'),
            child: const Text('Voir tous les médicaments'),
          ),
      ],
    );
  }

  Widget _buildHealthArticles() {
    if (_articles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pour vous',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._articles.map((article) => HealthArticleCard(
              title: article.title,
              subtitle: article.subtitle,
              imageUrl: article.imageUrl,
              readTime: article.readTime,
              onTap: () {
                context.push('/sante/patient/article/${article.id}', extra: article);
              },
            )),
      ],
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
            ListTile(
              leading: const Icon(Icons.health_and_safety, color: Colors.red),
              title: const Text('Ajouter un symptôme'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sante/patient/symptom/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}
