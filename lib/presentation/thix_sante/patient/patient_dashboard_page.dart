// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/thix_sante_colors.dart';

// --- IMPORTS DES PAGES ---
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
import 'screens/plus_services_page.dart';

// --- LOGIQUE (INCHANGÉE) ---
class DashboardStats {
  final int consultations, examens, medicaments, rdvs;
  const DashboardStats({this.consultations=0,this.examens=0,this.medicaments=0,this.rdvs=0});
}

final patientProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if(uid==null) return {'full_name': 'Patient'};
  try {
    return await Supabase.instance.client.from('profiles').select('full_name').eq('uid', uid).single();
  } catch(_){ return {'full_name': 'Patient'}; }
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

// --- UI PREMIUM ---
class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});
  void _go(BuildContext c, Widget page)=>Navigator.push(c, MaterialPageRoute(builder:(_)=>page));

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final stats = ref.watch(dashboardStatsProvider);
    final profile = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(context),
            SliverToBoxAdapter(child: _hero(context, profile)),
            SliverToBoxAdapter(child: _statsSection(stats)),
            SliverToBoxAdapter(child: _sectionHeader('Services rapides', Icons.bolt_rounded)),
            SliverToBoxAdapter(child: _grid(context, _getRapidesItems(context), spacing: 8)),
            SliverToBoxAdapter(child: _sectionHeader('Parcours Santé', Icons.local_hospital_rounded)),
            SliverToBoxAdapter(child: _grid(context, _getSanteItems(context), spacing: 8)),
            SliverToBoxAdapter(child: _sosBanner(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _appBar(BuildContext context) => SliverAppBar(
    floating: true, pinned: false, backgroundColor: const Color(0xFFF8FAFC), elevation: 0,
    title: Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.health_and_safety, color: Colors.white, size: 20)),
      const SizedBox(width: 10),
      const Text('THIX SANTÉ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)))
    ]),
  );

  // --- HERO AVEC 6 ITEMS SCROLLING ---
  Widget _hero(BuildContext context, AsyncValue<Map<String, dynamic>> profile) => SizedBox(
    height: 160,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 6,
      separatorBuilder: (_,__) => const SizedBox(width: 12),
      itemBuilder: (context, index) => Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)]), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          profile.when(data: (p) => Text('Bonjour, ${p['full_name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), loading: ()=>const Text('...'), error: (_,__)=>const Text('Bonjour')),
          const SizedBox(height: 8),
          Text(index == 0 ? 'Votre santé est notre priorité' : 'Astuce santé #${index + 1}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    ),
  );

  Widget _statsSection(AsyncValue<DashboardStats> s) => s.when(
    data: (d) => Padding(padding: const EdgeInsets.all(16), child: Row(children:[
      _statCard(Icons.monitor_heart, '${d.consultations}', 'Consults'),
      _statCard(Icons.biotech, '${d.examens}', 'Examens'),
      _statCard(Icons.medication, '${d.medicaments}', 'Médocs'),
      _statCard(Icons.calendar_month, '${d.rdvs}', 'RDV'),
    ])),
    loading: ()=> const SizedBox(), error: (_,__)=>const SizedBox(),
  );

  Widget _statCard(IconData i, String v, String l) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
    child: Column(children: [Icon(i, size: 18, color: const Color(0xFF2563EB)), Text(v, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)), Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey))]),
  ));

  Widget _sectionHeader(String t, IconData icon) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
    child: Row(children:[Icon(icon, size: 16, color: Colors.orange), const SizedBox(width: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14))]),
  );

  // --- GRILLE COMPACTE ---
  Widget _grid(BuildContext c, List<Map<String,dynamic>> items, {double spacing = 8}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: spacing, mainAxisSpacing: spacing, childAspectRatio: 0.85),
      itemCount: items.length,
      itemBuilder: (_, i) => InkWell(
        onTap: ()=>_go(c, items[i]['p']),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)), child: Icon(items[i]['i'], color: const Color(0xFF2563EB), size: 22)),
          const SizedBox(height: 4),
          Text(items[i]['l'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600))
        ])
      )
    ),
  );

  // --- LISTES D'ITEMS ---
  List<Map<String,dynamic>> _getRapidesItems(BuildContext c) => [
    {'l':'Médecin','i':Icons.medical_services,'p':const ConsulterMedecinPage()},
    {'l':'Dossier','i':Icons.folder,'p':const DossierMedicalPage()},
    {'l':'Famille','i':Icons.family_restroom,'p':const DossierFamillePage()},
    {'l':'Ordonn.','i':Icons.receipt_long,'p':const MesOrdonnancesPage()},
    {'l':'RDV','i':Icons.calendar_month,'p':const PrendreRdvPage()},
    {'l':'Pharmacie','i':Icons.local_pharmacy,'p':const PharmaciesProchesPage()},
    {'l':'Médicaments','i':Icons.medication,'p':const TrouverMedicamentPage()},
    {'l':'Urgences','i':Icons.emergency,'p':const UrgencesProchesPage()},
  ];

  List<Map<String,dynamic>> _getSanteItems(BuildContext c) => [
    {'l':'Enfants','i':Icons.child_care,'p':const SanteEnfantsPage()},
    {'l':'Vaccins','i':Icons.vaccines,'p':const CarnetVaccinationPage()},
    {'l':'Grossesse','i':Icons.pregnant_woman,'p':const SuiviGrossessePage()},
    {'l':'Mental','i':Icons.psychology,'p':const BienEtreMentalPage()},
  ];

  Widget _sosBanner(BuildContext c) => Container(
    margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(16)),
    child: Row(children:[
      const Icon(Icons.emergency, color: Colors.white, size: 28),
      const SizedBox(width: 12),
      const Expanded(child: Text('Urgence médicale ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
      IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: ()=>_go(c, const UrgencesProchesPage()))
    ])
  );

  Widget _bottomNav() => Container(
    margin: const EdgeInsets.all(16), padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      IconButton(icon: const Icon(Icons.home_filled, color: Color(0xFF2563EB)), onPressed: (){}),
      IconButton(icon: const Icon(Icons.favorite_outline), onPressed: (){}),
      const Icon(Icons.add_circle, color: Color(0xFF2563EB), size: 32),
      IconButton(icon: const Icon(Icons.chat_bubble_outline), onPressed: (){}),
      IconButton(icon: const Icon(Icons.person_outline), onPressed: (){}),
    ]),
  );
}
