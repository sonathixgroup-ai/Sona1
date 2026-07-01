import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
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
                      SliverToBoxAdapter(child: _hero()),
                      SliverToBoxAdapter(child: _summarySection()),
                      SliverToBoxAdapter(child: _quickGrid()),
                      SliverToBoxAdapter(child: _healthGrid()),
                      SliverToBoxAdapter(child: _articlesGrid()),
                      SliverToBoxAdapter(child: const EmergencyButton()),
                      const SliverToBoxAdapter(child: SizedBox(height: 90)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // =========================================================
  // TOP BAR MODERNE GLASS
  // =========================================================
  Widget _topBar() {
    final user = AuthController.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _glassIcon(Icons.menu, onTap: () => _openRoleSwitchSheet(context)),

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
              (user?.displayName ?? "U").substring(0, 1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // =========================================================
  // HERO PREMIUM
  // =========================================================
  Widget _hero() {
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
            Text("Bonjour $name 👋",
                style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(
              "Votre santé, nouvelle génération",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================
  Widget _summarySection() {
    if (_summary == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _miniCard("Consult", _summary!.consultationsThisYear, Icons.favorite),
          _miniCard("Exam", _summary!.examsCompleted, Icons.science),
          _miniCard("RDV", _summary!.upcomingAppointments, Icons.calendar_month),
          _miniCard("Med", _summary!.activeMedications, Icons.medication),
        ],
      ),
    );
  }

  Widget _miniCard(String label, int value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: _glass(),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF2563FF)),
            const SizedBox(height: 6),
            Text("$value",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // QUICK GRID
  // =========================================================
  Widget _quickGrid() {
    final items = [
      ("Médecin", Icons.medical_services),
      ("RDV", Icons.calendar_today),
      ("Dossier", Icons.folder),
      ("Urgence", Icons.emergency),
      ("Pharmacie", Icons.local_pharmacy),
      ("IA", Icons.smart_toy),
      ("Examens", Icons.science),
      ("Téléconsult", Icons.video_call),
    ];

    return _grid("⚡ Services rapides", items);
  }

  Widget _healthGrid() {
    final items = [
      ("Enfants", Icons.child_care),
      ("Vaccins", Icons.vaccines),
      ("Nutrition", Icons.restaurant),
      ("Sport", Icons.fitness_center),
      ("Stress", Icons.spa),
      ("Assurance", Icons.shield),
      ("Analyse", Icons.analytics),
      ("Bien-être", Icons.self_improvement),
    ];

    return _grid("🏥 Santé", items);
  }

  Widget _grid(String title, List<(String, IconData)> items) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              return Container(
                decoration: _card(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(items[i].$2, color: const Color(0xFF2563FF)),
                    const SizedBox(height: 6),
                    Text(items[i].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // =========================================================
  // ARTICLES
  // =========================================================
  Widget _articlesGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("📰 Pour vous",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ..._articles.take(4).map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: _glass(),
                child: Text(a.title),
              ))
        ],
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
  // ACTION SHEET (FIXED)
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
            _sheetItem(Icons.calendar_today, "RDV", Colors.blue,
                () => context.push('/sante/patient/appointment/new')),
            _sheetItem(Icons.chat, "IA", Colors.green,
                () => context.push('/sante/patient/ia')),
            _sheetItem(Icons.camera_alt, "Scanner", Colors.purple,
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
  // ROLE SWITCH (FIXED)
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
  // STYLE
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

  BoxDecoration _card() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      );

  Widget _glassIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _glass(),
        child: Icon(icon),
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
// BOTTOM NAVIGATION (AJOUTÉ)
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
