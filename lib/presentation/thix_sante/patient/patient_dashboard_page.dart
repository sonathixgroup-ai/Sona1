// lib/presentation/thix_sante/patient/screens/patient_dashboard.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- PROVIDERS UNIQUEMENT (pas de services directs) ---
import '../providers/patient_dashboard_provider.dart';
import '../models/health_record_model.dart';

// --- SCREENS ---
import 'screens/consulter_medecin_page.dart';
import 'screens/dossier_famille_page.dart';
import 'screens/dossier_medical_page.dart';
import 'screens/mes_ordonnances_page.dart';
import 'screens/mon_medecin_traitant_page.dart';
import 'screens/resultats_examens_page.dart';
import 'screens/second_avis_page.dart';
import 'screens/prendre_rdv_page.dart';
import 'screens/trouver_hopital_page.dart';
import 'screens/pharmacies_proches_page.dart';
import 'screens/trouver_medicament_page.dart';
import 'screens/urgences_proches_page.dart';
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

// --- LOGIQUE INCHANGÉE ---
class DashboardStats {
  final int consultations, examens, medicaments, rdvs;
  const DashboardStats({this.consultations=0,this.examens=0,this.medicaments=0,this.rdvs=0});
}

final patientProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if(uid==null) return {'full_name': 'Patient'};
  try { return await Supabase.instance.client.from('profiles').select('full_name').eq('uid', uid).single(); } 
  catch(_){ return {'full_name': 'Patient'}; }
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser?.id;
  if(uid==null) return const DashboardStats();
  try{
    final c = await db.from('health_links').select('id').eq('patient_id', uid);
    final e = await db.from('health_records').select('id').eq('patient_id', uid);
    final p = await db.from('prescriptions').select('id').eq('patient_id', uid).neq('status','delivree');
    final r = await db.from('appointments').select('id').eq('patient_id', uid).gte('date_rdv', DateTime.now().toIso8601String());
    return DashboardStats(consultations:(c as List).length, examens:(e as List).length, medicaments:(p as List).length, rdvs:(r as List).length);
  }catch(_){return const DashboardStats();}
});

// --- UI COMPACTE & DYNAMIQUE ---
class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({super.key});
  @override
  ConsumerState<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Hero Auto-scroll toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage > 5) nextPage = 0;
        _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final profile = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _appBar(),
          SliverToBoxAdapter(child: _hero(profile)),
          SliverToBoxAdapter(child: _statsSection(stats)),
          SliverToBoxAdapter(child: _sectionHeader('Services rapides', Icons.bolt_rounded)),
          SliverToBoxAdapter(child: _grid(_getRapidesItems(), spacing: 6)),
          SliverToBoxAdapter(child: _sectionHeader('Parcours Santé', Icons.local_hospital_rounded)),
          SliverToBoxAdapter(child: _grid(_getSanteItems(), spacing: 6)),
          SliverToBoxAdapter(child: _sosBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _appBar() => SliverAppBar(
    floating: true, backgroundColor: const Color(0xFFF8FAFC), elevation: 0,
    title: const Row(children: [
      Icon(Icons.health_and_safety, color: Color(0xFF2563EB)),
      SizedBox(width: 8),
      Text('THIX SANTÉ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)))
    ]),
  );

  Widget _hero(AsyncValue<Map<String, dynamic>> profile) => SizedBox(
    height: 140,
    child: PageView.builder(
      controller: _pageController,
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)]), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          profile.when(data: (p) => Text('Bonjour, ${p['full_name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), loading: ()=>const Text('...'), error: (_,__)=>const Text('Bonjour, Patient')),
          const SizedBox(height: 8),
          Text(index == 0 ? 'Votre santé est notre priorité' : 'Conseil santé #$index', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    ),
  );

  Widget _statsSection(AsyncValue<DashboardStats> s) => s.when(
    data: (d) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children:[
      _statCard(Icons.monitor_heart, '${d.consultations}', 'Consults'),
      _statCard(Icons.biotech, '${d.examens}', 'Examens'),
      _statCard(Icons.medication, '${d.medicaments}', 'Médocs'),
      _statCard(Icons.calendar_month, '${d.rdvs}', 'RDV'),
    ])),
    loading: ()=> const SizedBox(), error: (_,__)=>const SizedBox(),
  );

  Widget _statCard(IconData i, String v, String l) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)),
    child: Column(children: [Icon(i, size: 16, color: const Color(0xFF2563EB)), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)), Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey))]),
  ));

  Widget _sectionHeader(String t, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
    child: Row(children:[Icon(icon, size: 16, color: Colors.orange), const SizedBox(width: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13))]),
  );

  Widget _grid(List<Map<String,dynamic>> items, {required double spacing}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: spacing, mainAxisSpacing: spacing, childAspectRatio: 0.9),
      itemCount: items.length,
      itemBuilder: (_, i) => InkWell(
        onTap: ()=>_go(items[i]['p']),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade100)), child: Icon(items[i]['i'], color: const Color(0xFF2563EB), size: 18)),
          const SizedBox(height: 4),
          Text(items[i]['l'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600))
        ])
      )
    ),
  );

  // SUPPRESSION TOTALE DES "const" DEVANT LES PAGES !
  List<Map<String,dynamic>> _getRapidesItems() => [
    {'l':'Médecin','i':Icons.medical_services,'p': ConsulterMedecinPage()},
    {'l':'Dossier','i':Icons.folder,'p': DossierMedicalPage()},
    {'l':'Famille','i':Icons.family_restroom,'p': DossierFamillePage()},
    {'l':'Ordonn.','i':Icons.receipt_long,'p': MesOrdonnancesPage()},
    {'l':'RDV','i':Icons.calendar_month,'p': PrendreRdvPage()},
    {'l':'Pharmacie','i':Icons.local_pharmacy,'p': PharmaciesProchesPage()},
    {'l':'Médicaments','i':Icons.medication,'p': TrouverMedicamentPage()},
    {'l':'Urgences','i':Icons.emergency,'p': UrgencesProchesPage()},
    {'l':'Téléconsult.','i':Icons.videocam,'p': TeleconsultationPage()},
    {'l':'Assistant IA','i':Icons.smart_toy,'p': AssistantIAPage()},
    {'l':'Dossier part.','i':Icons.share,'p': DossierPartagePage()},
    {'l':'Épidémies','i':Icons.coronavirus,'p': EpidemiesPage()},
    {'l':'Don sang','i':Icons.water_drop,'p': DonSangPage()},
    {'l':'Vaccins','i':Icons.vaccines,'p': RappelsVaccinPage()},
    {'l':'Certificat','i':Icons.description,'p': CertificatMedicalPage()},
    {'l':'Assurance','i':Icons.shield,'p': AssuranceSantePage()},
  ];

  // SUPPRESSION TOTALE DES "const" DEVANT LES PAGES !
  List<Map<String,dynamic>> _getSanteItems() => [
    {'l':'Enfants','i':Icons.child_care,'p': SanteEnfantsPage()},
    {'l':'Vaccins','i':Icons.vaccines,'p': CarnetVaccinationPage()},
    {'l':'Grossesse','i':Icons.pregnant_woman,'p': SuiviGrossessePage()},
    {'l':'Analyse','i':Icons.show_chart,'p': AnalysePredictivePage()},
    {'l':'Mental','i':Icons.psychology,'p': BienEtreMentalPage()},
    {'l':'Nutrition','i':Icons.apple,'p': NutritionPage()},
    {'l':'Physique','i':Icons.fitness_center,'p': ActivitePhysiquePage()},
    {'l':'Stress','i':Icons.self_improvement,'p': GestionStressPage()},
  ];

  // SUPPRESSION DU "const" DEVANT UrgencesProchesPage !
  Widget _sosBanner() => Container(
    margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12)),
    child: Row(children:[
      const Icon(Icons.emergency, color: Colors.white, size: 24),
      const SizedBox(width: 8),
      const Expanded(child: Text('Urgence médicale ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
      IconButton(icon: const Icon(Icons.call, color: Colors.white, size: 18), onPressed: ()=>_go(UrgencesProchesPage()))
    ])
  );

  Widget _bottomNav() => Container(
    margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      IconButton(icon: const Icon(Icons.home_filled, color: Color(0xFF2563EB)), onPressed: (){}),
      IconButton(icon: const Icon(Icons.favorite_outline), onPressed: (){}),
      const Icon(Icons.add_circle, color: Color(0xFF2563EB), size: 28),
      IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: (){}),
      IconButton(icon: const Icon(Icons.person_outline), onPressed: (){}),
    ]),
  );
}
