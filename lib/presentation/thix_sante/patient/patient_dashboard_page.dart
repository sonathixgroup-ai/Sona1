// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/thix_sante_colors.dart';

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
import 'package:thix_id/presentation/thix_sante/patient/screens/plus_services_page.dart';

// ---------- LOGIC INCHANGÉE ----------
class DashboardStats {
  final int consultations, examens, medicaments, rdvs;
  const DashboardStats({this.consultations=0,this.examens=0,this.medicaments=0,this.rdvs=0});
}

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

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});
  void _go(BuildContext c, Widget page)=>Navigator.push(c, MaterialPageRoute(builder:(_)=>page));

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final stats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(context),
            SliverToBoxAdapter(child: _hero(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _statsSection(stats)),
            SliverToBoxAdapter(child: _sectionHeader('Services rapides', onVoirTout: () {})),
            SliverToBoxAdapter(child: _rapides(context)),
            SliverToBoxAdapter(child: _sectionHeader('Services santé', icon: Icons.local_hospital_rounded, onVoirTout: () {})),
            SliverToBoxAdapter(child: _sante(context)),
            SliverToBoxAdapter(child: _pourVous()),
            SliverToBoxAdapter(child: _sosBanner(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
      // Bottom nav type maquette - tu peux l'enlever si tu as déjà un Shell
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------- APPBAR ----------
  Widget _appBar(BuildContext context) => SliverAppBar(
    floating: true,
    pinned: false,
    backgroundColor: const Color(0xFFF8F9FF),
    elevation: 0,
    toolbarHeight: 70,
    leadingWidth: 64,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: _iconBox(Icons.menu_rounded, (){}),
    ),
    title: Row(children:[
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF06B6D4)]),
          borderRadius: BorderRadius.circular(10),
          boxShadow:[BoxShadow(color: const Color(0xFF2563EB).withOpacity(.25), blurRadius: 8, offset: const Offset(0,3))]
        ),
        child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 9),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('THIX SANTÉ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A), letterSpacing:.2)),
        Text('Votre santé, notre priorité', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ])
    ]),
    actions: [
      _iconBox(Icons.notifications_none_rounded, ()=>_go(context, const AssistantIAPage()), badge: '3'),
      const SizedBox(width: 8),
      const Padding(
        padding: EdgeInsets.only(right: 16),
        child: CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12')),
      )
    ],
  );

  Widget _iconBox(IconData icon, VoidCallback onTap, {String? badge}) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10)]),
        child: IconButton(icon: Icon(icon, color: const Color(0xFF1E293B), size: 22), onPressed: onTap),
      ),
      if(badge!=null) Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.all(5), decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))
    ],
  );

  // ---------- HERO COMME MAQUETTE ----------
  Widget _hero(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 210,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3B82FF), Color(0xFF2FAEFE), Color(0xFF17D6D6)]),
      boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(.25), blurRadius: 20, offset: const Offset(0,10))],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(children: [
      Positioned(right: -10, bottom: 0, child: Image.network(
        'https://cdn3d.iconscout.com/3d/premium/thumb/doctor-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-care-pack-medical-icons-5183886.png',
        height: 185, width: 185, fit: BoxFit.contain,
        errorBuilder: (_,__,___)=> const SizedBox(),
      )),
      // glow
      Positioned(right: 40, top: 20, child: Container(width: 90, height: 90, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), shape: BoxShape.circle))),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 140, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bonjour, Alex 👋', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          const Text('Votre santé\nentre de bonnes\nmains', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 6),
          const Text('Consultez, suivez et prenez soin\nde votre santé au quotidien.', style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3, fontWeight: FontWeight.w400)),
          const Spacer(),
          Row(children: [
            _heroBtn(context, icon: Icons.folder_special_rounded, label: 'Dossier de santé', onTap: ()=>_go(context, const DossierMedicalPage())),
            const SizedBox(width: 10),
            _heroScore(),
          ])
        ]),
      )
    ]),
  );

  Widget _heroBtn(BuildContext c, {required IconData icon, required String label, required VoidCallback onTap}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 8)]),
      child: Row(children:[
        Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)), child: Icon(icon, size: 14, color: const Color(0xFF2563EB))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF1E40AF))),
      ]),
    ),
  );

  Widget _heroScore() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.22), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(.35))),
    child: Row(children:[
      Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7)), child: const Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF0EA5E9))),
      const SizedBox(width: 7),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Score de santé', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
        Text('85%', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900, height: 1)),
      ])
    ]),
  );

  // ---------- STATS 4 CARDS ----------
  Widget _statsSection(AsyncValue<DashboardStats> s) => s.when(
    data: (d) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children:[
        Expanded(child: _statCard('12', 'Consultations', 'Cette année', 'https://cdn3d.iconscout.com/3d/premium/thumb/calendar-3d-icon-download-in-png-blend-fbx-gltf-file-formats--date-schedule-month-pack-user-interface-icons-5183002.png')),
        Expanded(child: _statCard('${d.examens}', 'Examens', 'Complétés', 'https://cdn3d.iconscout.com/3d/premium/thumb/flask-3d-icon-download-in-png-blend-fbx-gltf-file-formats--lab-science-chemistry-pack-medical-icons-4703185.png')),
        Expanded(child: _statCard('${d.medicaments}', 'Médicaments', 'En cours', 'https://cdn3d.iconscout.com/3d/premium/thumb/pill-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medicine-drug-medical-pack-icons-5183907.png')),
        Expanded(child: _statCard('${d.rdvs}', 'Rendez-vous', 'À venir', 'https://cdn3d.iconscout.com/3d/premium/thumb/clock-3d-icon-download-in-png-blend-fbx-gltf-file-formats--time-timer-deadline-pack-business-icons-5183011.png')),
      ]),
    ),
    loading: ()=> const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
    error: (_,__)=> const SizedBox(),
  );

  Widget _statCard(String val, String title, String sub, String imgUrl) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.fromLTRB(10,10,10,10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0,6))]),
    child: Row(children:[
      Image.network(imgUrl, width: 32, height: 32, errorBuilder: (_,__,___)=> const Icon(Icons.category_rounded, size: 28)),
      const SizedBox(width: 6),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A), height: 1)),
        Text(title, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFF334155))),
        Text(sub, maxLines: 1, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
      ]))
    ]),
  );

  // ---------- TITRES ----------
  Widget _sectionHeader(String t, {IconData icon = Icons.bolt_rounded, VoidCallback? onVoirTout}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
    child: Row(children:[
      Icon(icon, size: 16, color: const Color(0xFFF59E0B)),
      const SizedBox(width: 6),
      Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Color(0xFF0F172A))),
      const Spacer(),
      if(onVoirTout!=null) InkWell(onTap: onVoirTout, child: Row(children: const [Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)), Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF64748B))])),
    ]),
  );

  // ---------- GRID CARD STYLE MAQUETTE ----------
  Widget _serviceCard(BuildContext context, Map<String,dynamic> it){
    // Icône 3D via network si dispo sinon fallback emoji style
    final String? img = it['img'] as String?;
    final IconData icon = it['icon'] as IconData;
    final Color c = it['color'] as Color;
    return InkWell(
      onTap: ()=>_go(context, it['p'] as Widget),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0,4))]),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          if(img!=null) Image.network(img, width: 38, height: 38, errorBuilder: (_,__,___)=> _iconBadge(icon, c))
          else _iconBadge(icon, c),
          const SizedBox(height: 8),
          Text(it['l'] as String, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), height: 1.15)),
        ]),
      ),
    );
  }

  Widget _iconBadge(IconData icon, Color c) => Container(width: 42, height: 42, decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: c, size: 22));

  Widget _grid(BuildContext context, List<Map<String,dynamic>> items) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15),
      itemCount: items.length,
      itemBuilder: (c,i)=>_serviceCard(context, items[i]),
    ),
  );

  // --- Données adaptées à ton code existant + images 3D ---
  Widget _rapides(BuildContext context) => _grid(context, [
    {'l':'Consulter\nmédecin','icon':Icons.medical_services_rounded,'color':const Color(0xFF2563EB),'p':const ConsulterMedecinPage(),'img':'https://cdn3d.iconscout.com/3d/premium/thumb/doctor-bag-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-pack-medical-icons-5183890.png'},
    {'l':'Dossier\nmédical','icon':Icons.folder_rounded,'color':const Color(0xFF3B82F6),'p':const DossierMedicalPage(),'img':'https://cdn3d.iconscout.com/3d/premium/thumb/folder-3d-icon-download-in-png-blend-fbx-gltf-file-formats--file-document-storage-pack-miscellaneous-icons-5183008.png'},
    {'l':'Résultats\nexamens','icon':Icons.biotech_rounded,'color':const Color(0xFF10B981),'p':const ResultatsExamensPage()},
    {'l':'Mes\nordonnances','icon':Icons.receipt_long_rounded,'color':const Color(0xFF7C3AED),'p':const MesOrdonnancesPage()},
    {'l':'Trouver\nhôpital','icon':Icons.local_hospital_rounded,'color':const Color(0xFF0EA5E9),'p':const TrouverHopitalPage()},
    {'l':'Trouver\nmédicament','icon':Icons.medication_rounded,'color':const Color(0xFF8B5CF6),'p':const TrouverMedicamentPage()},
    {'l':'Pharmacies\nproches','icon':Icons.local_pharmacy_rounded,'color':const Color(0xFF22C55E),'p':const PharmaciesProchesPage()},
    {'l':'Urgences\nproches','icon':Icons.emergency_rounded,'color':const Color(0xFFEF4444),'p':const UrgencesProchesPage()},
    {'l':'Prendre\nRDV','icon':Icons.event_rounded,'color':const Color(0xFFF59E0B),'p':const PrendreRdvPage()},
    {'l':'Téléconsultation','icon':Icons.videocam_rounded,'color':const Color(0xFF6366F1),'p':const TeleconsultationPage()},
    {'l':'Assistant\nIA','icon':Icons.smart_toy_rounded,'color':const Color(0xFF0EA5E9),'p':const AssistantIAPage()},
    {'l':'Dossier\npartagé','icon':Icons.share_rounded,'color':const Color(0xFFA855F7),'p':const DossierPartagePage()},
    {'l':'Épidémies','icon':Icons.coronavirus_rounded,'color':const Color(0xFFEF4444),'p':const EpidemiesPage()},
    {'l':'Don de sang','icon':Icons.water_drop_rounded,'color':const Color(0xFFDC2626),'p':const DonSangPage()},
    {'l':'Rappels\nvaccin','icon':Icons.vaccines_rounded,'color':const Color(0xFF06B6D4),'p':const RappelsVaccinPage()},
    {'l':'Certificat\nmédical','icon':Icons.description_rounded,'color':const Color(0xFF64748B),'p':const CertificatMedicalPage()},
    {'l':'Assurance\nsanté','icon':Icons.shield_rounded,'color':const Color(0xFF2563EB),'p':const AssuranceSantePage()},
    {'l':'Second Avis','icon':Icons.people_alt_rounded,'color':const Color(0xFFEA580C),'p':const SecondAvisPage()},
  ]);

  Widget _sante(BuildContext context) => _grid(context, [
    {'l':'Santé\nenfants','icon':Icons.child_care_rounded,'color':const Color(0xFFF59E0B),'p':const SanteEnfantsPage()},
    {'l':'Carnet\nvaccination','icon':Icons.vaccines_rounded,'color':const Color(0xFF0EA5E9),'p':const CarnetVaccinationPage()},
    {'l':'Suivi\ngrossesses','icon':Icons.pregnant_woman_rounded,'color':const Color(0xFFEC4899),'p':const SuiviGrossessePage()},
    {'l':'Dossier\nmédical','icon':Icons.folder_rounded,'color':const Color(0xFFF59E0B),'p':const DossierMedicalPage()},
    {'l':'Analyse\nprédictive','icon':Icons.show_chart_rounded,'color':const Color(0xFF8B5CF6),'p':const AnalysePredictivePage()},
    {'l':'Bien-être\nmental','icon':Icons.psychology_rounded,'color':const Color(0xFF10B981),'p':const BienEtreMentalPage()},
    {'l':'Nutrition','icon':Icons.apple_rounded,'color':const Color(0xFF22C55E),'p':const NutritionPage()},
    {'l':'Activité\nphysique','icon':Icons.fitness_center_rounded,'color':const Color(0xFF3B82F6),'p':const ActivitePhysiquePage()},
    {'l':'Gestion\nstress','icon':Icons.self_improvement_rounded,'color':const Color(0xFFEC4899),'p':const GestionStressPage()},
    {'l':'Assurance','icon':Icons.shield_rounded,'color':const Color(0xFF2563EB),'p':const AssuranceSantePage()},
    {'l':'Plus de\nservices','icon':Icons.grid_view_rounded,'color':const Color(0xFF475569),'p':PlusServicesPage()},
  ]);

  Widget _pourVous() => Column(children:[
    _sectionHeader('Pour vous', icon: Icons.article_rounded, onVoirTout: (){}),
    SizedBox(height: 140, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children:[
      _articleCard('5 conseils pour rester\nen bonne santé','3 min','https://images.unsplash.com/photo-1512621776952-a57141f2eefd?w=400'),
      _articleCard('Gérer le stress au\nquotidien','4 min','https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400'),
      _articleCard('Activité physique\npour tous','5 min','https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
    ])),
  ]);

  Widget _articleCard(String title, String time, String img) => Container(width: 180, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10)]), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Stack(children:[Image.network(img, height: 85, width: double.infinity, fit: BoxFit.cover), Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF0EA5E9), borderRadius: BorderRadius.circular(20)), child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))]),
    Padding(padding: const EdgeInsets.all(10), child: Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2, color: Color(0xFF1E293B)))),
  ]));

  Widget _sosBanner(BuildContext c) => Container(margin: const EdgeInsets.fromLTRB(16,20,16,0), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFFFF5A5A), Color(0xFFEF4444)]), borderRadius: BorderRadius.circular(18)), child: Row(children:[
    Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Center(child: Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444))))),
    const SizedBox(width: 12),
    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('En cas d\'urgence, nous sommes là pour vous', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5)), Text('Accédez rapidement aux services d\'urgence près de vous', style: TextStyle(color: Colors.white, fontSize: 10)) ])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Row(children:[Icon(Icons.call_rounded, size: 14, color: Color(0xFFEF4444)), SizedBox(width: 4), Text('Appeler\nles urgences', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEF4444), height: 1.1))]))
  ]));

  Widget _bottomNav() => Container(
    margin: const EdgeInsets.fromLTRB(16,0,16,16),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 20)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[
      _navItem(Icons.home_rounded, 'Accueil', true),
      _navItem(Icons.favorite_rounded, 'Santé', false),
      Container(width: 54, height: 54, decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF06B6D4)]), shape: BoxShape.circle, boxShadow:[BoxShadow(color: const Color(0xFF2563EB).withOpacity(.35), blurRadius: 12)]), child: const Icon(Icons.add_rounded, color: Colors.white, size: 28)),
      _navItem(Icons.chat_bubble_rounded, 'Messages', false),
      _navItem(Icons.person_rounded, 'Profil', false),
    ]),
  );

  Widget _navItem(IconData i, String l, bool active) => Column(mainAxisSize: MainAxisSize.min, children:[Icon(i, color: active? const Color(0xFF2563EB): const Color(0xFF94A3B8), size: 22), const SizedBox(height: 3), Text(l, style: TextStyle(fontSize: 10, fontWeight: active? FontWeight.w700: FontWeight.w500, color: active? const Color(0xFF2563EB): const Color(0xFF94A3B8)))]);
}
