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

  bool _loading = true;
  HealthSummary? _summary;
  List<HealthArticle> _articles = [];
  int _alerts = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final user = AuthController.instance.currentUser;
    if (user == null) return;

    final patientId = user.id;

    final summary = await _healthService.fetchHealthSummary(patientId);
    final articles = await _healthService.fetchHealthArticles(limit: 8);
    final alerts = await _healthService.fetchHealthAlerts(patientId);

    setState(() {
      _summary = summary;
      _articles = articles;
      _alerts = alerts.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: _fab(),
      bottomNavigationBar: _nav(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _topBar(),
                  const SizedBox(height: 16),
                  _hero(),
                  const SizedBox(height: 16),
                  _stats(),
                  const SizedBox(height: 16),
                  _gridTitle("⚡ Services rapides"),
                  _grid(),
                  const SizedBox(height: 16),
                  _gridTitle("🧠 Pour vous"),
                  _articlesGrid(),
                  const SizedBox(height: 20),
                  const EmergencyButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  // ================= TOP BAR =================
  Widget _topBar() {
    final user = AuthController.instance.currentUser;
    return Row(
      children: [
        _glassIcon(Icons.menu),
        const Spacer(),
        Stack(
          children: [
            _glassIcon(Icons.notifications),
            if (_alerts > 0)
              Positioned(
                right: 2,
                top: 2,
                child: _badge(_alerts),
              )
          ],
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.blue.shade100,
          child: Text(user?.displayName?.substring(0, 1) ?? "U"),
        )
      ],
    );
  }

  // ================= HERO =================
  Widget _hero() {
    final name = AuthController.instance.currentUser?.displayName ?? "Utilisateur";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563FF), Color(0xFF00D2C8)],
        ),
        borderRadius: BorderRadius.circular(25),
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
            "Votre santé nouvelle génération",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATS =================
  Widget _stats() {
    if (_summary == null) return const SizedBox();

    return Row(
      children: [
        _stat("Consult", _summary!.consultationsThisYear.toString(), Icons.favorite),
        _stat("Examens", _summary!.examsCompleted.toString(), Icons.science),
        _stat("RDV", _summary!.upcomingAppointments.toString(), Icons.calendar_month),
        _stat("Med", _summary!.activeMedications.toString(), Icons.medication),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(10),
        decoration: _glass(),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ================= GRID =================
  Widget _grid() {
    final items = [
      ("Médecin", Icons.medical_services),
      ("Dossier", Icons.folder),
      ("RDV", Icons.calendar_today),
      ("Pharmacie", Icons.local_pharmacy),
      ("Urgence", Icons.emergency),
      ("IA Santé", Icons.smart_toy),
      ("Téléconsult", Icons.video_call),
      ("Examens", Icons.science),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (c, i) {
        return Container(
          decoration: _card(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(items[i].$2, color: Colors.blue),
              const SizedBox(height: 6),
              Text(items[i].$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
            ],
          ),
        );
      },
    );
  }

  // ================= ARTICLES =================
  Widget _articlesGrid() {
    return Column(
      children: _articles.take(4).map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: _glass(),
          child: Row(
            children: [
              const Icon(Icons.article, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text(a.title)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ================= NAV =================
  Widget _nav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          Icon(Icons.home),
          Icon(Icons.favorite),
          SizedBox(width: 40),
          Icon(Icons.chat),
          Icon(Icons.person),
        ],
      ),
    );
  }

  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563FF), Color(0xFF00D2C8)]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
      ),
      child: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  // ================= STYLE =================
  BoxDecoration _glass() => BoxDecoration(
        color: Colors.white.withOpacity(0.7),
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

  Widget _glassIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: _glass(),
      child: Icon(icon),
    );
  }

  Widget _badge(int v) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text("$v", style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _gridTitle(String t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
