// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports des pages (chemins inchangés)
import 'screens/mon_medecin_traitant_page.dart';
import 'screens/dossier_famille_page.dart';
import 'screens/second_avis_page.dart';
import 'screens/dossier_medical_page.dart';
import 'screens/resultats_examens_page.dart';
import 'screens/mes_ordonnances_page.dart';
import 'screens/consulter_medecin_page.dart';
import 'screens/trouver_hopital_page.dart';
import 'screens/trouver_medicament_page.dart';
import 'screens/pharmacies_proches_page.dart';
import 'screens/urgences_proches_page.dart';
import 'screens/prendre_rdv_page.dart';
import 'screens/teleconsultation_page.dart';
import 'screens/assistant_ia_page.dart';
import 'screens/dossier_partage_page.dart';
import 'screens/epidemies_page.dart';
import 'screens/don_sang_page.dart';
import 'screens/rappels_vaccin_page.dart';
import 'screens/certificat_medical_page.dart';
import 'screens/assurance_sante_page.dart';
import 'screens/sante_enfants_page.dart';
import 'screens/carnet_vaccination_page.dart';
import 'screens/suivi_grossesse_page.dart';
import 'screens/analyse_predictive_page.dart';
import 'screens/bien_etre_mental_page.dart';
import 'screens/nutrition_page.dart';
import 'screens/activite_physique_page.dart';
import 'screens/gestion_stress_page.dart';

class _C {
  static const bg = Color(0xFFF6F8FB);
  static const white = Color(0xFFFFFFFF);
  static const navy = Color(0xFF0B1D3A);
  static const navy2 = Color(0xFF132E55);
  static const sky = Color(0xFF0EA5E9);
  static const skyDark = Color(0xFF0284C7);
  static const teal = Color(0xFF14B8A6);
  static const emerald = Color(0xFF10B981);
  static const violet = Color(0xFF8B5CF6);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const border = Color(0x0F000000);
  static const borderStrong = Color(0x14000000);
  static const textMuted = Color(0x99000000);
  static const textFaint = Color(0x66000000);
  static const shadow = Color(0x0A000000);
  static const shadowStrong = Color(0x14000000);
}

// ---------------- Données réelles (inchangé) ----------------
class DashboardStats {
  final int consultations, examens, medicaments, rdvs;
  const DashboardStats({this.consultations = 0, this.examens = 0, this.medicaments = 0, this.rdvs = 0});
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser?.id;
  if (uid == null) return const DashboardStats();
  try {
    final c = await db.from('health_links').select('id').eq('patient_id', uid);
    final e = await db.from('health_records').select('id').eq('patient_id', uid);
    final p = await db.from('prescriptions').select('id').eq('patient_id', uid).neq('status', 'delivree');
    final r = await db.from('appointments').select('id').eq('patient_id', uid).gte('date_rdv', DateTime.now().toIso8601String());
    return DashboardStats(
      consultations: (c as List).length,
      examens: (e as List).length,
      medicaments: (p as List).length,
      rdvs: (r as List).length,
    );
  } catch (_) {
    return const DashboardStats();
  }
});

class PatientProfile {
  final String name;
  final String? avatarUrl;
  const PatientProfile({required this.name, this.avatarUrl});
}

final patientProfileProvider = FutureProvider<PatientProfile>((ref) async {
  final db = Supabase.instance.client;
  final user = db.auth.currentUser;
  if (user == null) return const PatientProfile(name: 'Patient');
  try {
    final res = await db.from('profiles').select('full_name, avatar_url').eq('id', user.id).maybeSingle();
    final name = (res?['full_name'] as String?)?.trim();
    final avatar = res?['avatar_url'] as String?;
    if (name != null && name.isNotEmpty) return PatientProfile(name: name, avatarUrl: avatar);
  } catch (_) {}
  final metaName = user.userMetadata?['full_name'] as String?;
  return PatientProfile(name: (metaName != null && metaName.isNotEmpty) ? metaName : 'Patient');
});

class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  ServiceItem(this.title, this.icon, this.color, this.page);
}

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({super.key});
  @override
  ConsumerState<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  final PageController _heroCtrl = PageController();
  int _heroIndex = 0;
  Timer? _timer;
  bool _aiPulse = false;
  Timer? _pulseTimer;

  late final List<ServiceItem> _dossierServices = [
    ServiceItem('Ordonnances', Icons.receipt_long_rounded, _C.violet, const MesOrdonnancesPage()),
    ServiceItem('Résultats', Icons.biotech_rounded, _C.sky, const ResultatsExamensPage()),
    ServiceItem('Vaccination', Icons.vaccines_rounded, _C.emerald, const CarnetVaccinationPage()),
    ServiceItem('Assurance', Icons.shield_rounded, _C.navy, const AssuranceSantePage()),
    ServiceItem('Dossier Médical', Icons.folder_shared_rounded, _C.skyDark, const DossierMedicalPage()),
    ServiceItem('Dossier Partagé', Icons.share_rounded, _C.teal, const DossierPartagePage()),
    ServiceItem('Certificat Médical', Icons.verified_rounded, _C.amber, const CertificatMedicalPage()),
  ];

  late final List<ServiceItem> _careServices = [
    ServiceItem('Médicaments', Icons.medication_rounded, _C.violet, const TrouverMedicamentPage()),
    ServiceItem('Second Avis', Icons.people_alt_rounded, _C.sky, const SecondAvisPage()),
    ServiceItem('Don de sang', Icons.bloodtype_rounded, _C.red, const DonSangPage()),
    ServiceItem('Consulter', Icons.medical_services_rounded, _C.skyDark, const ConsulterMedecinPage()),
    ServiceItem('Mon Médecin', Icons.person_rounded, const Color(0xFF475569), const MonMedecinTraitantPage()),
    ServiceItem('Épidémies', Icons.coronavirus_rounded, _C.red, const EpidemiesPage()),
  ];

  late final List<ServiceItem> _familyServices = [
    ServiceItem('Famille', Icons.family_restroom_rounded, _C.violet, const DossierFamillePage()),
    ServiceItem('Grossesse', Icons.pregnant_woman_rounded, const Color(0xFFEC4899), const SuiviGrossessePage()),
    ServiceItem('Santé Enfants', Icons.child_care_rounded, _C.sky, const SanteEnfantsPage()),
    ServiceItem('Rappels Vaccin', Icons.notifications_active_rounded, _C.amber, const RappelsVaccinPage()),
  ];

  late final List<ServiceItem> _wellbeingServices = [
    ServiceItem('Nutrition', Icons.restaurant_rounded, _C.amber, const NutritionPage()),
    ServiceItem('Activité Physique', Icons.directions_run_rounded, _C.emerald, const ActivitePhysiquePage()),
    ServiceItem('Santé Mentale', Icons.psychology_rounded, _C.violet, const BienEtreMentalPage()),
    ServiceItem('Gestion Stress', Icons.self_improvement_rounded, _C.teal, const GestionStressPage()),
    ServiceItem('Prédictions IA', Icons.query_stats_rounded, const Color(0xFF6366F1), const AnalysePredictivePage()),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_heroCtrl.hasClients) return;
      _heroIndex = (_heroIndex + 1) % 4;
      _heroCtrl.animateToPage(_heroIndex, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
    });
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => _aiPulse = !_aiPulse);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseTimer?.cancel();
    _heroCtrl.dispose();
    super.dispose();
  }

  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final profile = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 440,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -1.1),
                  radius: 1.2,
                  colors: [Color(0xFFEAF2FF), Color(0x00EEF4FF)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _C.sky,
              backgroundColor: _C.white,
              onRefresh: () async {
                ref.invalidate(dashboardStatsProvider);
                ref.invalidate(patientProfileProvider);
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                slivers: [
                  SliverToBoxAdapter(child: _header(profile)),
                  SliverToBoxAdapter(child: _scoreRow(stats)),
                  SliverToBoxAdapter(child: const SizedBox(height: 18)),
                  SliverToBoxAdapter(child: _aiCard()),
                  SliverToBoxAdapter(child: const SizedBox(height: 18)),
                  SliverToBoxAdapter(child: _quickActionsGrid()),
                  SliverToBoxAdapter(child: const SizedBox(height: 22)),
                  SliverToBoxAdapter(child: _todayTimeline(stats)),
                  SliverToBoxAdapter(child: const SizedBox(height: 26)),
                  SliverToBoxAdapter(child: _sectionHeader('Mon dossier')),
                  SliverToBoxAdapter(child: _horizontalServiceRow(_dossierServices)),
                  SliverToBoxAdapter(child: const SizedBox(height: 26)),
                  SliverToBoxAdapter(child: _sectionHeader('Trouver des soins')),
                  SliverToBoxAdapter(child: _careCards()),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  SliverToBoxAdapter(child: _horizontalServiceRow(_careServices)),
                  SliverToBoxAdapter(child: const SizedBox(height: 26)),
                  SliverToBoxAdapter(child: _sectionHeader('Famille')),
                  SliverToBoxAdapter(child: _horizontalServiceRow(_familyServices)),
                  SliverToBoxAdapter(child: const SizedBox(height: 26)),
                  SliverToBoxAdapter(child: _sectionHeader('Bien-être')),
                  SliverToBoxAdapter(child: _horizontalServiceRow(_wellbeingServices)),
                  SliverToBoxAdapter(child: const SizedBox(height: 26)),
                  SliverToBoxAdapter(child: _trustBar()),
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _header(AsyncValue<PatientProfile> profileAsync) {
    final name = profileAsync.valueOrNull?.name ?? '...';
    final avatarUrl = profileAsync.valueOrNull?.avatarUrl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                height: 46, width: 46,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [_C.emerald, Color(0xFF059669)]),
                  boxShadow: [BoxShadow(color: _C.emerald.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipOval(
                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? Image.network(avatarUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _C.white, child: const Icon(Icons.person_rounded, color: _C.navy, size: 22)))
                      : Container(color: _C.white, child: const Icon(Icons.person_rounded, color: _C.navy, size: 22)),
                ),
              ),
              Positioned(
                bottom: 1, right: 1,
                child: Container(height: 12, width: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: _C.emerald, border: Border.all(color: Colors.white, width: 2), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)])),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bonjour $name', style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing: -0.4), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              const Row(children: [
                Icon(Icons.verified_rounded, size: 12, color: _C.sky),
                SizedBox(width: 4),
                Text('THIX SANTÉ • Dossier sécurisé', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _C.textFaint)),
              ]),
            ]),
          ),
          InkWell(
            onTap: () => _go(const UrgencesProchesPage()),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 38, padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFFFE5E5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFEE2E2)), boxShadow: [BoxShadow(color: _C.red.withOpacity(0.12), blurRadius: 10)]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFDC2626)),
                SizedBox(width: 5),
                Text('SOS', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFFDC2626), letterSpacing: 0.5)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 38, width: 38,
              decoration: BoxDecoration(color: _C.white, shape: BoxShape.circle, border: Border.all(color: _C.borderStrong), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4))]),
              child: const Icon(Icons.notifications_none_rounded, size: 20, color: _C.navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(AsyncValue<DashboardStats> statsAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: statsAsync.when(
        loading: () => Container(height: 86, decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.border)), child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _C.sky))),
        error: (_, __) => const SizedBox.shrink(),
        data: (d) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.border), boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 18, offset: Offset(0, 8))]),
          child: Row(children: [
            _countBadge('Consults.', d.consultations, _C.sky, Icons.medical_services_rounded),
            _countBadge('Examens', d.examens, _C.emerald, Icons.biotech_rounded),
            _countBadge('Ordonn.', d.medicaments, _C.violet, Icons.medication_rounded),
            _countBadge('RDV', d.rdvs, _C.amber, Icons.event_rounded, showDivider: false),
          ]),
        ),
      ),
    );
  }

  Widget _countBadge(String label, int count, Color color, IconData icon, {bool showDivider = true}) {
    return Expanded(
      child: Row(children: [
        Expanded(child: Column(children: [
          Container(height: 42, width: 42, decoration: BoxDecoration(color: color.withOpacity(0.09), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.18)), boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 10)]), child: Icon(icon, size: 18, color: color)),
          const SizedBox(height: 8),
          Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing: -0.3)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _C.textFaint, letterSpacing: 0.2)),
        ])),
        if (showDivider) Container(height: 36, width: 1, color: _C.border),
      ]),
    );
  }

  Widget _aiCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: _C.white, border: Border.all(color: const Color(0x3328B3F0)), boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 28, offset: Offset(0, 12))]),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(height: 38, width: 38, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [_C.sky, _C.teal], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: _C.sky.withOpacity(0.3), blurRadius: 12)]), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20)),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Assistant IA THIX', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing: -0.2)),
              SizedBox(height: 2),
              Text('Analyse vos résultats • Répond en 2s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _C.textFaint)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD1FAE5))), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: _C.emerald, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _C.emerald, blurRadius: 6)])), const SizedBox(width: 6), const Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857)))])),
          ]),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => _go(const AssistantIAPage()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.borderStrong)),
              child: const Row(children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _C.textFaint),
                SizedBox(width: 12),
                Expanded(child: Text('Discuter avec l\'IA... Poser une question santé', style: TextStyle(fontSize: 13, color: _C.textFaint, fontWeight: FontWeight.w500))),
                Icon(Icons.arrow_forward_rounded, size: 16, color: _C.navy),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _quickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 56,
          child: InkWell(
            onTap: () => _go(const TeleconsultationPage()),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 192,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [_C.sky, _C.skyDark], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: _C.sky.withOpacity(0.32), blurRadius: 22, offset: const Offset(0, 12))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(height: 38, width: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.22))), child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 20)),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 5), Text('3 en ligne', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.w700))])),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Téléconsultation', style: TextStyle(color: Colors.white, fontSize: 18.5, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text('Médecins disponibles <5min', style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 11.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10)]), child: const Text('Consulter maintenant', style: TextStyle(color: _C.navy, fontSize: 12.5, fontWeight: FontWeight.w900))),
                ]),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 44,
          child: Column(children: [
            InkWell(
              onTap: () => _go(const PrendreRdvPage()),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 90,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: _C.navy, boxShadow: [BoxShadow(color: _C.navy.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8))]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('RENDEZ-VOUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.55), letterSpacing: 0.7)), Container(height: 24, width: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.calendar_month_rounded, size: 13, color: Colors.white))]),
                  const Text('Prendre RDV', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _go(const UrgencesProchesPage()),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 90,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), 
                  color: _C.white, 
                  border: Border.all(color: const Color(0xFFFECACA), width: 1.2), 
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 6))]
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [Container(height: 24, width: 24, decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, size: 14, color: _C.red)), const SizedBox(width: 6), const Text('URGENCE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: _C.red, letterSpacing: 0.6))]),
                  const Text('SAMU • Hôpitaux proches', style: TextStyle(color: _C.navy, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _todayTimeline(AsyncValue<DashboardStats> statsAsync) {
    final rdvs = statsAsync.valueOrNull?.rdvs ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _C.border), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('À venir', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing: -0.3)),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(20)), child: Text(rdvs > 0 ? '$rdvs RDV' : 'Aucun', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _C.textFaint))),
          ]),
          const SizedBox(height: 14),
          if (rdvs > 0)
            InkWell(
              onTap: () => _go(const PrendreRdvPage()),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDBEAFE))),
                child: Row(children: [
                  Container(height: 36, width: 36, decoration: BoxDecoration(color: _C.sky.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.event_available_rounded, size: 18, color: _C.sky)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(rdvs == 1 ? '1 rendez-vous à venir' : '$rdvs rendez-vous à venir', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.navy))),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _C.textFaint),
                ]),
              ),
            )
          else
            InkWell(
              onTap: () => _go(const PrendreRdvPage()),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: _C.bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _C.border)),
                child: Row(children: [
                  Container(height: 36, width: 36, decoration: BoxDecoration(color: _C.textFaint.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.event_note_rounded, size: 18, color: _C.textFaint)),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Aucun rendez-vous prévu', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.textMuted))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _C.navy, borderRadius: BorderRadius.circular(20)), child: const Text('Planifier', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(children: [
          Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing: -0.3)),
          const SizedBox(width: 8),
          Container(height: 4, width: 4, decoration: const BoxDecoration(color: _C.borderStrong, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Expanded(child: Divider(height: 1, color: _C.border)),
        ]),
      );

  Widget _horizontalServiceRow(List<ServiceItem> items) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            onTap: () => _go(it.page),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: _C.border), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(height: 40, width: 40, decoration: BoxDecoration(color: it.color.withOpacity(0.10), borderRadius: BorderRadius.circular(13), border: Border.all(color: it.color.withOpacity(0.18)), boxShadow: [BoxShadow(color: it.color.withOpacity(0.12), blurRadius: 8)]), child: Icon(it.icon, color: it.color, size: 19)),
                const SizedBox(height: 8),
                Text(it.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.8, fontWeight: FontWeight.w700, color: _C.navy, height: 1.15, letterSpacing: -0.1)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _careCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        InkWell(
          onTap: () => _go(const PharmaciesProchesPage()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _C.border), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 14, offset: Offset(0, 6))]),
            child: Row(children: [
              Container(height: 56, width: 56, decoration: BoxDecoration(color: const Color(0xFFEEF4FF), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFDBEAFE))), child: const Icon(Icons.local_pharmacy_rounded, color: _C.emerald, size: 26)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pharmacies à proximité', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: _C.navy, letterSpacing: -0.2)),
                SizedBox(height: 3),
                Row(children: [Icon(Icons.circle, size: 8, color: _C.emerald), SizedBox(width: 4), Text('Ouvertes maintenant • Livraison 20min', style: TextStyle(fontSize: 11, color: _C.textFaint, fontWeight: FontWeight.w600))]),
              ])),
              Container(height: 28, width: 28, decoration: BoxDecoration(color: _C.bg, shape: BoxShape.circle, border: Border.all(color: _C.border)), child: const Icon(Icons.chevron_right_rounded, color: _C.navy, size: 18)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => _go(const TrouverHopitalPage()),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _C.navy, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: _C.navy.withOpacity(0.22), blurRadius: 18, offset: const Offset(0, 8))]),
            child: Row(children: [
              Container(height: 56, width: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 26)),
              const SizedBox(width: 14),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hôpitaux & Urgences', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2)),
                SizedBox(height: 3),
                Text('Localisez un établissement • SAMU 15', style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600)),
              ])),
              Container(height: 28, width: 28, decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle), child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _trustBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: _C.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _C.border), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10)]),
        child: const Wrap(spacing: 14, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _TrustChip(icon: Icons.shield_rounded, label: 'Chiffré bout-à-bout'),
          _TrustChip(icon: Icons.verified_user_rounded, label: 'HDS • ISO 27001'),
          _TrustChip(icon: Icons.lock_rounded, label: 'Hébergé Tanzanie'),
        ]),
      ),
    );
  }

  Widget _bottomNav() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: _C.white.withOpacity(0.96), borderRadius: BorderRadius.circular(28), border: Border.all(color: _C.borderStrong), boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 28, offset: Offset(0, 12))]),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _navBtn(Icons.home_rounded, 'Accueil', true, () {}),
          _navBtn(Icons.folder_shared_rounded, 'Dossier', false, () => _go(const DossierMedicalPage())),
          _aiFab(),
          _navBtn(Icons.local_hospital_rounded, 'Soins', false, () => _go(const TrouverHopitalPage())),
          _navBtn(Icons.family_restroom_rounded, 'Famille', false, () => _go(const DossierFamillePage())),
        ]),
      ),
    );
  }

  Widget _aiFab() {
    return GestureDetector(
      onTap: () => _go(const AssistantIAPage()),
      child: AnimatedScale(
        scale: _aiPulse ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
        child: Container(
          height: 54, width: 54,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [_C.sky, _C.teal], begin: Alignment.topLeft, end: Alignment.bottomRight), boxShadow: [BoxShadow(color: _C.sky.withOpacity(0.38), blurRadius: 18, offset: const Offset(0, 7))], border: Border.all(color: Colors.white, width: 2)),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: active ? _C.navy.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 21, color: active ? _C.navy : _C.textFaint),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? _C.navy : _C.textFaint, letterSpacing: 0.1)),
        ]),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: _C.textFaint),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _C.textFaint, letterSpacing: 0.2)),
    ]);
  }
}
