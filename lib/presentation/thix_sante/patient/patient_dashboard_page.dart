// presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/emergency_button.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/health_cards.dart';
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
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      final patientId = user.id;

      // Appels réels au service – pas de mock dans cette page
      final summary = await _healthService.fetchHealthSummary(patientId);
      final appointments = await _healthService.fetchUpcomingAppointments(patientId);
      final medications = await _healthService.fetchMedications(patientId, activeOnly: true);
      final articles = await _healthService.fetchHealthArticles(limit: 3);
      final alerts = await _healthService.fetchHealthAlerts(patientId);

      setState(() {
        _summary = summary;
        _upcomingAppointments = appointments;
        _currentMedications = medications;
        _articles = articles;
        _unreadNotifications = alerts.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _PatientTopBar(
                          unreadCount: _unreadNotifications,
                          onNotificationsTap: () => context.push('/sante/patient/notifications'),
                          onSwitchRoleTap: () => _openRoleSwitchSheet(context),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _PatientHeroCard(
                          onOpenRecord: () => context.push('/sante/patient/profile'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: _PatientQuickActionsRow(
                          items: [
                            _QuickActionItem(
                              label: 'Rendez-vous',
                              icon: Icons.calendar_month,
                              color: HealthConstants.secondaryColor,
                              onTap: () => context.push('/sante/patient/appointments'),
                            ),
                            _QuickActionItem(
                              label: 'Consultation',
                              icon: Icons.video_call,
                              color: HealthConstants.primaryColor,
                              onTap: () => context.push('/sante/patient/appointment/new'),
                            ),
                            _QuickActionItem(
                              label: 'Examens',
                              icon: Icons.science,
                              color: Colors.purple,
                              onTap: () => context.push('/sante/patient/exams'),
                            ),
                            _QuickActionItem(
                              label: 'Ordonnances',
                              icon: Icons.receipt_long,
                              color: Colors.orange,
                              onTap: () => context.push('/sante/patient/prescriptions'),
                            ),
                            _QuickActionItem(
                              label: 'Urgences',
                              icon: Icons.health_and_safety,
                              color: Colors.red,
                              onTap: () => _showEmergencySheet(context),
                            ),
                            _QuickActionItem(
                              label: 'Plus',
                              icon: Icons.more_horiz,
                              color: Colors.blueGrey,
                              onTap: () => _showQuickActions(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (_summary != null) ...[
                            _SectionHeader(
                              title: 'Résumé de santé',
                              trailing: 'Voir tout',
                              onTrailingTap: () => context.push('/sante/patient/health'),
                            ),
                            const SizedBox(height: 10),
                            HealthSummaryCard(
                              consultations: _summary!.consultationsThisYear,
                              exams: _summary!.examsCompleted,
                              medications: _summary!.activeMedications,
                              appointments: _summary!.upcomingAppointments,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _SectionHeader(
                            title: 'Prochains rendez-vous',
                            trailing: 'Voir tout',
                            onTrailingTap: () => context.push('/sante/patient/appointments'),
                          ),
                          const SizedBox(height: 10),
                          _buildUpcomingAppointments(),
                          const SizedBox(height: 14),
                          _SectionHeader(
                            title: 'Traitements',
                            trailing: 'Voir tout',
                            onTrailingTap: () => context.push('/sante/patient/medications'),
                          ),
                          const SizedBox(height: 10),
                          _buildCurrentMedications(),
                          const SizedBox(height: 14),

                          // ════════════════════════════════════════════════════
                          // Services santé – grille 2 colonnes
                          // ════════════════════════════════════════════════════
                          _buildHealthServices(),
                          const SizedBox(height: 24),

                          // ════════════════════════════════════════════════════
                          // Services rapides – liste
                          // ════════════════════════════════════════════════════
                          _buildQuickServices(),
                          const SizedBox(height: 24),

                          // ════════════════════════════════════════════════════
                          // Assurance santé
                          // ════════════════════════════════════════════════════
                          _buildInsuranceSection(),
                          const SizedBox(height: 24),

                          // ════════════════════════════════════════════════════
                          // Articles "Pour vous"
                          // ════════════════════════════════════════════════════
                          if (_articles.isNotEmpty) ...[
                            _SectionHeader(title: 'Pour vous'),
                            const SizedBox(height: 10),
                            _buildHealthArticles(),
                            const SizedBox(height: 14),
                          ],

                          // ════════════════════════════════════════════════════
                          // Bouton urgence 15
                          // ════════════════════════════════════════════════════
                          const EmergencyButton(),
                          const SizedBox(height: 8),
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

  // ═══════════════════════════════════════════════════════════════════
  //  ACTIONS D'URGENCE
  // ═══════════════════════════════════════════════════════════════════
  void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Urgences', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                'Accès rapide aux actions critiques.',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).hintColor),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.phone_in_talk, color: Colors.red),
                title: const Text('Appeler les urgences'),
                subtitle: const Text('Numéro local selon votre pays'),
                onTap: () => ctx.pop(),
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: HealthConstants.secondaryColor),
                title: const Text('Partager ma position'),
                onTap: () => ctx.pop(),
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble, color: HealthConstants.primaryColor),
                title: const Text('Contacter un médecin'),
                onTap: () {
                  ctx.pop();
                  context.push('/sante/patient/chat/new');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CHANGEMENT DE RÔLE
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _openRoleSwitchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThixRole>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _RoleSwitchSheet(currentRole: ThixRole.patient),
    );
    if (selected == null || selected == ThixRole.patient) return;
    await _selectRoleAndNavigate(context, selected);
  }

  Future<void> _selectRoleAndNavigate(BuildContext context, ThixRole role) async {
    try {
      ThixRoleController.instance.selectRole(role, manual: true);
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'thix_role': role.name}),
        );
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

  // ═══════════════════════════════════════════════════════════════════
  //  PROCHAINS RENDEZ-VOUS
  // ═══════════════════════════════════════════════════════════════════
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
        ..._upcomingAppointments.take(3).map((appt) => UpcomingAppointmentCard(
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

  // ═══════════════════════════════════════════════════════════════════
  //  MÉDICAMENTS EN COURS
  // ═══════════════════════════════════════════════════════════════════
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
        ..._currentMedications.take(3).map((med) => Card(
              elevation: 1,
              child: ListTile(
                leading: const Icon(Icons.medication, color: HealthConstants.secondaryColor),
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

  // ═══════════════════════════════════════════════════════════════════
  //  ARTICLES SANTÉ
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHealthArticles() {
    if (_articles.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _articles.map((article) => HealthArticleCard(
            title: article.title,
            subtitle: article.subtitle,
            imageUrl: article.imageUrl,
            readTime: article.readTime,
            onTap: () {
              context.push('/sante/patient/article/${article.id}', extra: article);
            },
          )).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SERVICES SANTÉ (grille 2 colonnes)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHealthServices() {
    const services = [
      _ServiceData('Santé des enfants', 'Suivez la santé de vos enfants', Icons.family_restroom, '/sante/patient/family'),
      _ServiceData('Carnet de vaccination', 'Consultez et gérez les vaccins', Icons.vaccines, '/sante/patient/vaccinations'),
      _ServiceData('Suivi grossesses', 'Suivez votre grossesse pas à pas', Icons.pregnant_woman, '/sante/patient/pregnancy'),
      _ServiceData('Assurance santé', 'Protégez votre santé et celle de vos proches', Icons.shield, '/sante/patient/insurance'),
      _ServiceData('Assurance', 'Découvrez nos solutions d\'assurance adaptées', Icons.security, '/sante/patient/insurance'),
      _ServiceData('Plus de services', 'Découvrez tous nos services', Icons.more_horiz, '/sante/patient/health'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Services santé'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            return _ServiceCard(
              title: s.title,
              subtitle: s.subtitle,
              icon: s.icon,
              onTap: () => context.push(s.route),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  SERVICES RAPIDES (liste)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickServices() {
    const services = [
      _ServiceData('Consulter un médecin', 'Parlez à un professionnel', Icons.medical_services, '/sante/patient/appointment/new'),
      _ServiceData('Dossier médical', 'Accédez à votre dossier de santé', Icons.folder, '/sante/patient/record'),
      _ServiceData('Résultats d\'examens', 'Consultez vos analyses', Icons.science, '/sante/patient/exams'),
      _ServiceData('Mes ordonnances', 'Gérez et renouvelez vos ordonnances', Icons.receipt, '/sante/patient/prescriptions'),
      _ServiceData('Trouver un hôpital', 'Trouvez l\'hôpital le plus proche', Icons.local_hospital, '/sante/patient/map/hospitals'),
      _ServiceData('Trouver un médicament', 'Vérifiez la disponibilité des médicaments', Icons.medication, '/sante/patient/map/pharmacies'),
      _ServiceData('Pharmacies proches', 'Trouvez la pharmacie la plus proche', Icons.local_pharmacy, '/sante/patient/map/pharmacies'),
      _ServiceData('Urgences proches', 'Services d\'urgence disponibles 24/7', Icons.emergency, '/sante/patient/map/emergencies'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Services rapides'),
        const SizedBox(height: 10),
        ...services.map((s) => ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HealthConstants.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s.icon, color: HealthConstants.primaryColor, size: 22),
              ),
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => context.push(s.route),
            )),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ASSURANCE SANTÉ
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildInsuranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Assurance santé'),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bénéficiez d\'une couverture complète adaptée à vos besoins.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.push('/sante/patient/insurance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HealthConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('En savoir plus'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Protégez-vous et vos proches avec nos solutions.',
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/sante/patient/insurance'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: HealthConstants.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Découvrir'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  ACTIONS RAPIDES (modal)
  // ═══════════════════════════════════════════════════════════════════
  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: HealthConstants.secondaryColor),
              title: const Text('Prendre un rendez-vous'),
              onTap: () {
                context.pop();
                context.push('/sante/patient/appointment/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.purple),
              title: const Text('Scanner une ordonnance'),
              onTap: () {
                context.pop();
                context.push('/sante/patient/scan');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: HealthConstants.primaryColor),
              title: const Text('Consulter l\'assistant IA'),
              onTap: () {
                context.pop();
                context.push('/sante/patient/ia');
              },
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety, color: Colors.red),
              title: const Text('Ajouter un symptôme'),
              onTap: () {
                context.pop();
                context.push('/sante/patient/symptom/new');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
//  WIDGETS PRIVÉS
// ════════════════════════════════════════════════════════════════════════

class _PatientTopBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSwitchRoleTap;
  const _PatientTopBar({
    required this.unreadCount,
    required this.onNotificationsTap,
    required this.onSwitchRoleTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final displayName = (user?.displayName ?? '').trim();
    final initials = displayName.isEmpty
        ? 'U'
        : displayName
            .split(RegExp(r'\s+'))
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e.characters.first.toUpperCase())
            .join();
    final photoUrl = (user?.photoUrl ?? '').trim();

    return Row(
      children: [
        GestureDetector(
          onTap: onSwitchRoleTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.health_and_safety, color: HealthConstants.primaryColor),
              const SizedBox(width: 8),
              Text(
                'THIX SANTÉ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        _NotificationBell(count: unreadCount, onTap: onNotificationsTap),
        const SizedBox(width: 10),
        Stack(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      initials,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PatientHeroCard extends StatelessWidget {
  final VoidCallback onOpenRecord;
  const _PatientHeroCard({required this.onOpenRecord});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final firstName = (user?.displayName ?? '').trim().split(' ').first;
    return Container(
      decoration: BoxDecoration(
        gradient: ThixRole.patient.gradient,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, ${firstName.isEmpty ? 'Utilisateur' : firstName}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Votre santé\nentre de bonnes mains',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Consultez vos suivis et votre score\nau quotidien.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onOpenRecord,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_open, size: 18, color: HealthConstants.secondaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Dossier de santé',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: HealthConstants.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _PatientQuickActionsRow extends StatelessWidget {
  final List<_QuickActionItem> items;
  const _PatientQuickActionsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((it) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: it.onTap,
              child: Container(
                width: 86,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: it.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(it.icon, color: it.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      it.label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const _SectionHeader({required this.title, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: HealthConstants.secondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
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
            Text(
              'Changer de rôle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Quitter le mode patient et accéder à un autre espace.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: 12),
            for (final role in ThixRoleController.availableRoles)
              _RoleTile(
                role: role,
                selected: role == currentRole,
                onTap: () => context.pop(role),
              ),
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
              decoration: BoxDecoration(
                color: role.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(role.icon, color: role.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    role.shortLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                  ),
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

// ---------------------------------------------------------------------
// Service Data (utilisé pour les grilles/listes)
// ---------------------------------------------------------------------
class _ServiceData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _ServiceData(this.title, this.subtitle, this.icon, this.route);
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: HealthConstants.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: HealthConstants.primaryColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
