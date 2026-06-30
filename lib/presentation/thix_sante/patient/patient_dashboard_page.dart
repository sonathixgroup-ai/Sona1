// presentation/thix_sante/patient/patient_dashboard_page.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/health_constants.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
import 'package:thix_id/presentation/thix_sante/shared/widgets/emergency_button.dart';
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
      if (user == null) throw Exception('Utilisateur non connecté');
      final patientId = user.id;

      final summary = await _healthService.fetchHealthSummary(patientId);
      final appointments = await _healthService.fetchUpcomingAppointments(patientId);
      final medications = await _healthService.fetchMedications(patientId, activeOnly: true);
      final articles = await _healthService.fetchHealthArticles(limit: 12);
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
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5), // Facebook grey
        floatingActionButton: FloatingActionButton(
          elevation: 6,
          backgroundColor: const Color(0xFF2563FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          onPressed: () => _showQuickActions(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _BottomNav(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) context.go('/sante/patient/health');
            else if (index == 2) context.go('/sante/patient/messages');
            else if (index == 3) context.go('/sante/patient/profile');
          },
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ===== TOP BAR =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _TopBar(
                            unreadCount: _unreadNotifications,
                            onNotificationTap: () => context.push('/sante/patient/notifications'),
                            onMenuTap: () => _openRoleSwitchSheet(context),
                          ),
                        ),
                      ),
                      // ===== HERO CARD =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _HeroCard(
                            onDossierTap: () => context.push('/sante/patient/profile'),
                            score: _summary?.healthScore ?? 0,
                          ),
                        ),
                      ),
                      // ===== RÉSUMÉ DE SANTÉ =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: _SummarySection(summary: _summary!),
                        ),
                      ),
                      // ===== SERVICES RAPIDES (4×3) =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _QuickServicesGrid(),
                        ),
                      ),
                      // ===== SERVICES SANTÉ (4×3) =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _HealthServicesGrid(),
                        ),
                      ),
                      // ===== POUR VOUS (4×3) =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: _ArticlesGrid(articles: _articles),
                        ),
                      ),
                      // ===== BOUTON URGENCE =====
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: const EmergencyButton(),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomSheetTile(
                icon: Icons.calendar_today,
                title: 'Prendre rendez-vous',
                color: const Color(0xFF2563FF),
                onTap: () { Navigator.pop(context); context.push('/sante/patient/appointment/new'); },
              ),
              _BottomSheetTile(
                icon: Icons.camera_alt,
                title: 'Scanner ordonnance',
                color: Colors.purple,
                onTap: () { Navigator.pop(context); context.push('/sante/patient/scan'); },
              ),
              _BottomSheetTile(
                icon: Icons.chat,
                title: 'Assistant IA',
                color: Colors.green,
                onTap: () { Navigator.pop(context); context.push('/sante/patient/ia'); },
              ),
              _BottomSheetTile(
                icon: Icons.emergency,
                title: 'Urgence',
                color: Colors.red,
                onTap: () { Navigator.pop(context); context.push('/sante/patient/map/emergencies'); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openRoleSwitchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThixRole>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _RoleSwitchSheet(currentRole: ThixRole.patient),
    );
    if (selected == null) return;
    try {
      ThixRoleController.instance.selectRole(selected, manual: true);
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'thix_role': selected.name}),
      );
      if (!context.mounted) return;
      switch (selected) {
        case ThixRole.patient:
          context.go('/sante/patient/dashboard');
        case ThixRole.doctor:
          context.go('/sante/doctor/dashboard');
        case ThixRole.pharmacy:
          context.go('/sante/pharmacy/dashboard');
      }
    } catch (_) {}
  }
}

// ============================================================
// TOP BAR
// ============================================================
class _TopBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onNotificationTap;
  final VoidCallback onMenuTap;
  const _TopBar({
    required this.unreadCount,
    required this.onNotificationTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final photo = (user?.photoUrl ?? '').trim();
    return Row(
      children: [
        _CircleIconButton(icon: Icons.menu, onTap: onMenuTap, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563FF), Color(0xFF00D2C8)],
                  ),
                ),
                child: const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THIX SANTÉ',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    'Votre santé, notre priorité',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon: Icons.notifications_none,
              onTap: onNotificationTap,
              size: 40,
            ),
            if (unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 20,
          backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
          child: photo.isEmpty ? const Icon(Icons.person, size: 20) : null,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.grey[700]),
      ),
    );
  }
}

// ============================================================
// HERO CARD
// ============================================================
class _HeroCard extends StatelessWidget {
  final VoidCallback onDossierTap;
  final int score;
  const _HeroCard({
    required this.onDossierTap,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthController.instance.currentUser;
    final firstName = (user?.displayName ?? '').split(' ').first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563FF), Color(0xFF00D2C8)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563FF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour, $firstName 👋',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre santé entre de bonnes mains',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Consultez, suivez et prenez soin\nde votre santé au quotidien.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services,
                  color: Colors.white.withOpacity(0.8),
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onDossierTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 18, color: Color(0xFF2563FF)),
                        const SizedBox(width: 8),
                        Text(
                          'Dossier de santé',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: const Color(0xFF2563FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'Score $score%',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RÉSUMÉ DE SANTÉ
// ============================================================
class _SummarySection extends StatelessWidget {
  final HealthSummary summary;
  const _SummarySection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          _SummaryCard(
            title: 'Consultations',
            value: summary.consultationsThisYear.toString(),
            icon: Icons.calendar_today,
            color: const Color(0xFF2563FF),
            subtitle: 'Cette année',
          ),
          _SummaryCard(
            title: 'Examens',
            value: summary.examsCompleted.toString(),
            icon: Icons.science,
            color: Colors.green,
            subtitle: 'Complétés',
          ),
          _SummaryCard(
            title: 'Médicaments',
            value: summary.activeMedications.toString(),
            icon: Icons.medication,
            color: Colors.purple,
            subtitle: 'En cours',
          ),
          _SummaryCard(
            title: 'Rendez-vous',
            value: summary.upcomingAppointments.toString(),
            icon: Icons.access_time,
            color: Colors.orange,
            subtitle: 'À venir',
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SERVICES RAPIDES (4×3)
// ============================================================
class _QuickServicesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Consulter médecin', Icons.medical_services, '/sante/patient/appointment/new'),
      ('Dossier médical', Icons.folder, '/sante/patient/record'),
      ('Résultats examens', Icons.science, '/sante/patient/exams'),
      ('Mes ordonnances', Icons.receipt, '/sante/patient/prescriptions'),
      ('Trouver hôpital', Icons.local_hospital, '/sante/patient/map/hospitals'),
      ('Trouver médicament', Icons.medication, '/sante/patient/map/pharmacies'),
      ('Pharmacies proches', Icons.local_pharmacy, '/sante/patient/map/pharmacies'),
      ('Urgences proches', Icons.emergency, '/sante/patient/map/emergencies'),
      ('Prendre RDV', Icons.calendar_today, '/sante/patient/appointment/new'),
      ('Téléconsultation', Icons.video_call, '/sante/patient/teleconsultation/new'),
      ('Assistant IA', Icons.smart_toy, '/sante/patient/ia'),
      ('Dossier partagé', Icons.share, '/sante/patient/sharing'),
    ];
    return _SectionGrid(title: '⚡ Services rapides', items: items);
  }
}

// ============================================================
// SERVICES SANTÉ (4×3)
// ============================================================
class _HealthServicesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Santé enfants', Icons.child_care, '/sante/patient/family'),
      ('Carnet vaccination', Icons.vaccines, '/sante/patient/vaccinations'),
      ('Suivi grossesses', Icons.pregnant_woman, '/sante/patient/pregnancy'),
      ('Dossier médical', Icons.folder_open, '/sante/patient/record'),
      ('Assurance santé', Icons.shield, '/sante/patient/insurance'),
      ('Assurance', Icons.security, '/sante/patient/insurance'),
      ('Plus de services', Icons.more_horiz, '/sante/patient/health'),
      ('Analyse prédictive', Icons.analytics, '/sante/patient/health'),
      ('Bien-être mental', Icons.self_improvement, '/sante/patient/wellness/stress'),
      ('Nutrition', Icons.restaurant, '/sante/patient/wellness/nutrition'),
      ('Activité physique', Icons.fitness_center, '/sante/patient/wellness/fitness'),
      ('Gestion stress', Icons.spa, '/sante/patient/wellness/stress'),
    ];
    return _SectionGrid(title: '🏥 Services santé', items: items);
  }
}

// ============================================================
// POUR VOUS (4×3)
// ============================================================
class _ArticlesGrid extends StatelessWidget {
  final List<HealthArticle> articles;
  const _ArticlesGrid({required this.articles});

  @override
  Widget build(BuildContext context) {
    // Si pas assez d'articles, on les complète avec des exemples
    final displayArticles = articles.isNotEmpty
        ? articles.take(12).toList()
        : [
            HealthArticle(id: '1', title: '5 conseils pour rester en bonne santé', subtitle: '', readTime: 3, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '2', title: 'Alimentation équilibrée : les bases', subtitle: '', readTime: 4, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '3', title: 'Gérer le stress au quotidien', subtitle: '', readTime: 3, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '4', title: 'Prévention : un geste qui sauve', subtitle: '', readTime: 2, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '5', title: 'Activité physique pour tous', subtitle: '', readTime: 5, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '6', title: 'Sommeil réparateur', subtitle: '', readTime: 4, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '7', title: 'Méditation pour débutants', subtitle: '', readTime: 3, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '8', title: 'Santé mentale au travail', subtitle: '', readTime: 6, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '9', title: 'Nutrition avancée', subtitle: '', readTime: 5, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '10', title: 'Bien-être global', subtitle: '', readTime: 4, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '11', title: 'Sport adapté', subtitle: '', readTime: 3, publishDate: DateTime.now(), tags: [], content: ''),
            HealthArticle(id: '12', title: 'Relaxation profonde', subtitle: '', readTime: 2, publishDate: DateTime.now(), tags: [], content: ''),
          ];

    return _SectionGrid(
      title: '📰 Pour vous',
      items: displayArticles.map((a) => (a.title, Icons.article, '/sante/patient/article/${a.id}')).toList(),
      showReadTime: true,
      articles: displayArticles,
    );
  }
}

// ============================================================
// GRID GÉNÉRIQUE (4 colonnes)
// ============================================================
class _SectionGrid extends StatelessWidget {
  final String title;
  final List<(String, IconData, String)> items;
  final bool showReadTime;
  final List<HealthArticle>? articles;

  const _SectionGrid({
    required this.title,
    required this.items,
    this.showReadTime = false,
    this.articles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: items.length.clamp(0, 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _GridItem(
              icon: item.$2,
              label: item.$1,
              onTap: () => context.push(item.$3),
              readTime: showReadTime && articles != null && index < articles!.length
                  ? '${articles![index].readTime} min'
                  : null,
            );
          },
        ),
      ],
    );
  }
}

// ============================================================
// ITEM DE GRILLE (4×3)
// ============================================================
class _GridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? readTime;

  const _GridItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF2563FF).withOpacity(0.15), const Color(0xFF00D2C8).withOpacity(0.15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: const Color(0xFF2563FF)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
                height: 1.2,
              ),
            ),
            if (readTime != null)
              Text(
                readTime!,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOTTOM SHEET TILE
// ============================================================
class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _BottomSheetTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 70,
      elevation: 20,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: 'Accueil', selected: currentIndex == 0, onTap: () => onTap(0)),
          _NavItem(icon: Icons.favorite_border, label: 'Santé', selected: currentIndex == 1, onTap: () => onTap(1)),
          const SizedBox(width: 30),
          _NavItem(icon: Icons.chat_bubble_outline, label: 'Messages', selected: currentIndex == 2, onTap: () => onTap(2)),
          _NavItem(icon: Icons.person_outline, label: 'Profil', selected: currentIndex == 3, onTap: () => onTap(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? const Color(0xFF2563FF) : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF2563FF) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ROLE SWITCH SHEET
// ============================================================
class _RoleSwitchSheet extends StatelessWidget {
  final ThixRole currentRole;
  const _RoleSwitchSheet({required this.currentRole});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Changer de rôle',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 16),
          for (final role in ThixRoleController.availableRoles)
            GestureDetector(
              onTap: () => context.pop(role),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(role.icon, color: role.accent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        role.label,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    if (role == currentRole)
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
