// presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';
import 'package:thix_id/presentation/thix_sante/shared/services/health_services.dart';
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

  // Liste des services avec leurs icônes, routes et couleurs
  static const List<_Service> _services = [
    _Service('Consulter médecin', Icons.medical_services, '/sante/patient/appointment/new'),
    _Service('Dossier médical', Icons.folder, '/sante/patient/record'),
    _Service('Résultats examens', Icons.science, '/sante/patient/exams'),
    _Service('Mes ordonnances', Icons.receipt, '/sante/patient/prescriptions'),
    _Service('Trouver hôpital', Icons.local_hospital, '/sante/patient/map/hospitals'),
    _Service('Trouver médicament', Icons.medication, '/sante/patient/map/pharmacies'),
    _Service('Pharmacies proches', Icons.storefront, '/sante/patient/map/pharmacies'),
    _Service('Urgences proches', Icons.emergency, '/sante/patient/map/emergencies'),
    _Service('Prendre RDV', Icons.calendar_today, '/sante/patient/appointment/new'),
    _Service('Téléconsultation', Icons.video_call, '/sante/patient/teleconsultation/new'),
    _Service('Assistant IA', Icons.smart_toy, '/sante/patient/ia'),
    _Service('Dossier partagé', Icons.share, '/sante/patient/sharing'),
    _Service('Santé enfants', Icons.child_care, '/sante/patient/family'),
    _Service('Carnet vaccination', Icons.vaccines, '/sante/patient/vaccinations'),
    _Service('Suivi grossesses', Icons.pregnant_woman, '/sante/patient/pregnancy'),
    _Service('Assurance santé', Icons.shield, '/sante/patient/insurance'),
    _Service('Analyse prédictive', Icons.analytics, '/sante/patient/health-score'),
    _Service('Bien-être mental', Icons.spa, '/sante/patient/wellness/stress'),
    _Service('Nutrition', Icons.restaurant, '/sante/patient/wellness/nutrition'),
    _Service('Activité physique', Icons.fitness_center, '/sante/patient/wellness/fitness'),
    _Service('Gestion stress', Icons.self_improvement, '/sante/patient/wellness/stress'),
    _Service('Plus de services', Icons.more_horiz, '/sante/patient/health'),
  ];

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

      if (!mounted) return;

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
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),

        floatingActionButton: _fab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        bottomNavigationBar: _BottomNav(
          currentIndex: 0,
          onTap: (index) {
            if (index == 1) context.go('/sante/patient/health');
            if (index == 2) context.go('/sante/patient/messages');
            if (index == 3) context.go('/sante/patient/profile');
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
                      SliverToBoxAdapter(child: _topBar()),
                      SliverToBoxAdapter(child: _heroSection()),
                      SliverToBoxAdapter(child: _healthScoreCard()),
                      SliverToBoxAdapter(child: _servicesGrid()),
                      SliverToBoxAdapter(child: _articlesSection()),
                      SliverToBoxAdapter(child: _emergencySection()),
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // =========================================================
  // TOP BAR : THIX SANTÉ
  // =========================================================
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIX SANTÉ',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
              Text(
                'Votre santé, notre priorité',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Stack(
            children: [
              _glassIcon(Icons.notifications_none,
                  onTap: () => context.push('/sante/patient/notifications')),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: _badge(_unreadNotifications),
                )
            ],
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              (AuthController.instance.currentUser?.displayName ?? "U")
                  .substring(0, 1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  // HERO : Bonjour, Alex 🎉
  // =========================================================
  Widget _heroSection() {
    final user = AuthController.instance.currentUser;
    final name = user?.displayName ?? "Utilisateur";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563FF), Color(0xFF00D2C8)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bonjour, $name 🎉",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Votre santé entre de bonnes mains",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Consultez, suivez et prenez soin de votre santé au quotidien.",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DOSSIER DE SANTÉ + SCORE
  // =========================================================
  Widget _healthScoreCard() {
    final score = _summary?.healthScore ?? 85;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety, size: 40, color: Color(0xFF2563FF)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dossier de santé',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Score de santé',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563FF), Color(0xFF00D2C8)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                '$score%',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SERVICES RAPIDES (GRILLE 4 COLONNES)
  // =========================================================
  Widget _servicesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services rapides',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (_, index) {
              final service = _services[index];
              // Couleur cyclique
              final color = _getColorForIndex(index);
              return _serviceTile(service, color);
            },
          ),
        ],
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue, Colors.green, Colors.orange, Colors.pink,
      Colors.purple, Colors.cyan, Colors.red, Colors.teal,
      Colors.indigo, Colors.lime, Colors.amber, Colors.brown,
      Colors.blueGrey, Colors.deepOrange, Colors.pinkAccent,
      Colors.lightBlue, Colors.lightGreen, Colors.yellow,
      Colors.deepPurple, Colors.orangeAccent, Colors.greenAccent,
      Colors.blue.shade300,
    ];
    return colors[index % colors.length];
  }

  Widget _serviceTile(_Service service, Color color) {
    return GestureDetector(
      onTap: () => context.push(service.route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(service.icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              service.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // POUR VOUS (ARTICLES)
  // =========================================================
  Widget _articlesSection() {
    if (_articles.isEmpty) return const SizedBox.shrink();

    // Prendre les 4 premiers articles pour la maquette
    final displayed = _articles.take(4).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pour vous',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...displayed.map((article) {
            return GestureDetector(
              onTap: () => context.push('/sante/patient/article/${article.id}', extra: article),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Text(
                        '${article.readTime}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        article.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================
  // SECTION URGENCE (SOS)
  // =========================================================
  Widget _emergencySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sos, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  'SOS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'En cas d’urgence, nous sommes là pour vous',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Appeler le 15
                  const url = 'tel:15';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Impossible de passer l\'appel.')),
                    );
                  }
                },
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text('Appeler les urgences'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // FAB
  // =========================================================
  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2563FF), Color(0xFF00D2C8)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: () => _showQuickActions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // =========================================================
  // ACTION SHEET
  // =========================================================
  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetItem(Icons.calendar_today, "Prendre RDV", Colors.blue,
                () => context.push('/sante/patient/appointment/new')),
            _sheetItem(Icons.chat, "Assistant IA", Colors.green,
                () => context.push('/sante/patient/ia')),
            _sheetItem(Icons.camera_alt, "Scanner ordonnance", Colors.purple,
                () => context.push('/sante/patient/scan')),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // =========================================================
  // ROLE SWITCH
  // =========================================================
  Future<void> _openRoleSwitchSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ThixRole>(
      context: context,
      builder: (_) => const _RoleSwitchSheet(currentRole: ThixRole.patient),
    );

    if (selected == null) return;

    try {
      ThixRoleController.instance.selectRole(selected, manual: true);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'thix_role': selected.name}),
      );

      if (!context.mounted) return;

      if (selected == ThixRole.patient) context.go('/sante/patient/dashboard');
      if (selected == ThixRole.doctor) context.go('/sante/doctor/dashboard');
      if (selected == ThixRole.pharmacy) context.go('/sante/pharmacy/dashboard');
    } catch (e) {
      debugPrint("Role switch error: $e");
    }
  }

  // =========================================================
  // STYLE HELPERS
  // =========================================================
  BoxDecoration _glass() => BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      );

  Widget _glassIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _glass(),
        child: Icon(icon, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _badge(int v) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      child: Text(
        "$v",
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}

// =========================================================
// MODELE SERVICE
// =========================================================
class _Service {
  final String label;
  final IconData icon;
  final String route;

  const _Service(this.label, this.icon, this.route);
}

// =========================================================
// BOTTOM NAVIGATION
// =========================================================
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF2563FF),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Santé'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}

// =========================================================
// ROLE SHEET
// =========================================================
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
          const Text(
            "Changer de rôle",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          for (final role in ThixRoleController.availableRoles)
            ListTile(
              leading: Icon(role.icon, color: role.accent),
              title: Text(role.label),
              trailing: role == currentRole
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => context.pop(role),
            )
        ],
      ),
    );
  }
}
