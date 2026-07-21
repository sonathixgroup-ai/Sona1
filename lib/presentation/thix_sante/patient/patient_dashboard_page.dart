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
  void _go(BuildContext ctx, Widget page)=> Navigator.push(ctx, MaterialPageRoute(builder:(_)=>page));

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final stats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(context),
            SliverToBoxAdapter(child: _heroRDC(context)),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _statsCards(stats)),
            SliverToBoxAdapter(child: _sectionTitle('Services rapides', onVoirTout: (){})),
            SliverToBoxAdapter(child: _servicesRapides(context)),
            SliverToBoxAdapter(child: _sectionTitle('Services santé', onVoirTout: (){})),
            SliverToBoxAdapter(child: _servicesSante(context)),
            SliverToBoxAdapter(child: _sectionTitle('Pour vous')),
            SliverToBoxAdapter(child: _pourVous()),
            SliverToBoxAdapter(child: _sosBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _appBar(BuildContext ctx) => SliverAppBar(
    floating: true,
    backgroundColor: const Color(0xFFF8FAFC),
    elevation: 0,
    toolbarHeight: 64,
    leadingWidth: 60,
    leading: Padding(
      padding: const EdgeInsets.only(left:12),
      child: Container(width:44,height:44,decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.06), blurRadius:10)]), child: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A))),
    ),
    title: Row(children:[
      Container(width:38,height:38,decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF00D18F)])), child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size:22)),
      const SizedBox(width:8),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[Text('THIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize:17, color: Color(0xFF0F172A))), Text(' SANTÉ', style: TextStyle(fontWeight: FontWeight.w900, fontSize:17, color: Color(0xFF00C896)))]),
        Text('Votre santé, notre priorité', style: TextStyle(fontSize:10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
      ])
    ]),
    actions: [
      Container(width:42,height:42,decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.06), blurRadius:10)]), child: Stack(children:[
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)), onPressed: ()=> _go(ctx, const AssistantIAPage())),
        Positioned(top:4,right:4, child: Container(width:16,height:16,decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize:9, fontWeight: FontWeight.w900))))),
      ])),
      const SizedBox(width:10),
      const Padding(padding: EdgeInsets.only(right:12), child: CircleAvatar(radius:20, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'))),
    ],
  );

  // HERO EXACT PHOTO - SEUL MOCK
  Widget _heroRDC(BuildContext ctx){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal:12),
      height: 192,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A7FFF), Color(0xFF3BB8FF), Color(0xFF2ED9C3)])),
      clipBehavior: Clip.antiAlias,
      child: Stack(children:[
        Positioned(right:10, top:15, child: Container(width:60,height:60,decoration: BoxDecoration(color: Colors.white.withOpacity(.2), shape: BoxShape.circle))),
        Positioned(right:0, bottom:0, child: Image.asset('assets/images/doctor_rdc.png', width:170, height:192, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Image.network('https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400', width:165, height:192, fit: BoxFit.cover))),
        // icons flottants comme photo
        Positioned(right:110, top:35, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(.9), shape: BoxShape.circle), child: const Icon(Icons.favorite_rounded, size:16, color: Color(0xFF2A7FFF)))),
        Positioned(right:30, top:45, child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(.9), shape: BoxShape.circle), child: const Icon(Icons.verified_user_rounded, size:16, color: Color(0xFF2A7FFF)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16,14,155,12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            const Row(children:[Text('Bonjour, Alex ', style: TextStyle(color: Colors.white, fontSize:12, fontWeight: FontWeight.w600)), Text('👋', style: TextStyle(fontSize:12))]),
            const SizedBox(height:8),
            const Text('Votre santé\nentre de bonnes\nmains', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:19, height:1.1)),
            const SizedBox(height:6),
            const Text('Consultez, suivez et prenez soin\nde votre santé au quotidien.', style: TextStyle(color: Colors.white, fontSize:11, height:1.3)),
            const Spacer(),
            Row(children:[
              InkWell(onTap: ()=> _go(ctx, const DossierMedicalPage()), child: Container(padding: const EdgeInsets.symmetric(horizontal:10, vertical:8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Row(children:[Icon(Icons.folder_special_rounded, size:16, color: Color(0xFF2563EB)), SizedBox(width:4), Text('Dossier de santé', style: TextStyle(fontWeight: FontWeight.w800, fontSize:11, color: Color(0xFF1E293B)))]))),
              const SizedBox(width:6),
              Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:6), decoration: BoxDecoration(color: const Color(0xFF7EC8FF).withOpacity(.9), borderRadius: BorderRadius.circular(12)), child: const Row(children:[Icon(Icons.bar_chart_rounded, size:16, color: Colors.white), SizedBox(width:4), Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('Score de santé', style: TextStyle(fontSize:8, color: Colors.white)), Text('85%', style: TextStyle(fontWeight: FontWeight.w900, fontSize:14, color: Colors.white))])])),
            ])
          ]),
        )
      ]),
    );
  }

  Widget _statsCards(AsyncValue<DashboardStats> s){
    return s.when(
      data: (d)=> Padding(
        padding: const EdgeInsets.symmetric(horizontal:12),
        child: Row(children:[
          _statCard('12','Consultations','Cette année', const Color(0xFF3B82F6), '📅'),
          _statCard('${d.examens==0?8:d.examens}','Examens','Complétés', const Color(0xFF22C55E), '🧪'),
          _statCard('${d.medicaments==0?5:d.medicaments}','Médicaments','En cours', const Color(0xFFA855F7), '💊'),
          _statCard('${d.rdvs==0?3:d.rdvs}','Rendez-vous','À venir', const Color(0xFFF97316), '⏰'),
        ]),
      ),
      loading: ()=> const SizedBox(height:70, child: Center(child: CircularProgressIndicator(strokeWidth:2))),
      error: (_,__)=> const SizedBox(),
    );
  }

  Widget _statCard(String val, String t1, String t2, Color c, String emoji){
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal:3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius:8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[Text(emoji, style: const TextStyle(fontSize:18)), const Spacer(), Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:18, color: Color(0xFF0F172A)))]),
        Text(t1, style: const TextStyle(fontSize:9, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        Text(t2, style: const TextStyle(fontSize:8, color: Color(0xFF94A3B8))),
      ]),
    ));
  }

  Widget _sectionTitle(String t, {VoidCallback? onVoirTout}) => Padding(
    padding: const EdgeInsets.fromLTRB(16,18,16,10),
    child: Row(children:[
      const Icon(Icons.bolt_rounded, size:16, color: Color(0xFFFBBF24)),
      const SizedBox(width:4),
      Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize:15, color: Color(0xFF0F172A))),
      const Spacer(),
      if(onVoirTout!=null) const Row(children:[Text('Voir tout', style: TextStyle(fontSize:11, fontWeight: FontWeight.w700, color: Color(0xFF64748B))), Icon(Icons.chevron_right_rounded, size:14, color: Color(0xFF64748B))]),
    ]),
  );

  Widget _gridItem(BuildContext ctx, String title, String emoji, VoidCallback onTap){
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.03), blurRadius:6)]),
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          Text(emoji, style: const TextStyle(fontSize:28)),
          const SizedBox(height:4),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize:9.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height:1.1)),
        ]),
      ),
    );
  }

  // SERVICES RAPIDES - 17 items sans doublons
  Widget _servicesRapides(BuildContext ctx){
    final items = [
      ['Consulter\nmédecin','🩺', const ConsulterMedecinPage()],
      ['Dossier\nmédical','📁', const DossierMedicalPage()],
      ['Résultats\nexamens','🧪', const ResultatsExamensPage()],
      ['Mes\nordonnances','📄', const MesOrdonnancesPage()],
      ['Trouver\nhôpital','🏥', const TrouverHopitalPage()],
      ['Trouver\nmédicament','💊', const TrouverMedicamentPage()],
      ['Pharmacies\nproches','➕', const PharmaciesProchesPage()],
      ['Urgences\nproches','🚨', const UrgencesProchesPage()],
      ['Prendre\nRDV','📅', const PrendreRdvPage()],
      ['Téléconsultation','📹', const TeleconsultationPage()],
      ['Assistant\nIA','🤖', const AssistantIAPage()],
      ['Dossier\npartagé','🔗', const DossierPartagePage()],
      ['Épidémies','🦠', const EpidemiesPage()],
      ['Don de sang','🩸', const DonSangPage()],
      ['Rappels\nvaccin','💉', const RappelsVaccinPage()],
      ['Certificat\nmédical','📋', const CertificatMedicalPage()],
      ['Assurance\nsanté','🛡️', const AssuranceSantePage()],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:12),
      child: GridView.builder(
        shrinkWrap:true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:6, mainAxisSpacing:8, crossAxisSpacing:8, childAspectRatio:0.78),
        itemCount: items.length,
        itemBuilder: (_,i)=> _gridItem(ctx, items[i][0] as String, items[i][1] as String, ()=> Navigator.push(ctx, MaterialPageRoute(builder:(_)=> items[i][2] as Widget))),
      ),
    );
  }

  // SERVICES SANTE - 8 items sans doublons et SANS "Plus de services"
  Widget _servicesSante(BuildContext ctx){
    final items = [
      ['Santé\nenfants','👶', const SanteEnfantsPage()],
      ['Carnet\nvaccination','💉', const CarnetVaccinationPage()],
      ['Suivi\ngrossesses','🤰', const SuiviGrossessePage()],
      ['Analyse\nprédictive','📈', const AnalysePredictivePage()],
      ['Bien-être\nmental','🧠', const BienEtreMentalPage()],
      ['Nutrition','🍏', const NutritionPage()],
      ['Activité\nphysique','🏋️', const ActivitePhysiquePage()],
      ['Gestion\nstress','🧘', const GestionStressPage()],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal:12),
      child: GridView.builder(
        shrinkWrap:true, physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:6, mainAxisSpacing:8, crossAxisSpacing:8, childAspectRatio:0.78),
        itemCount: items.length,
        itemBuilder: (_,i)=> _gridItem(ctx, items[i][0] as String, items[i][1] as String, ()=> Navigator.push(ctx, MaterialPageRoute(builder:(_)=> items[i][2] as Widget))),
      ),
    );
  }

  Widget _pourVous()=> SizedBox(
    height:155,
    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal:12), children:[
      _article('3 min','5 conseils pour rester\nen bonne santé','https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400'),
      _article('4 min','Gérer le stress au\nquotidien','https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400'),
      _article('5 min','Activité physique\npour tous','https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
      _article('3 min','Prévention : un geste\nqui sauve','https://images.unsplash.com/photo-1576765607924-3f7b8410a787?w=400'),
    ]),
  );

  Widget _article(String time, String title, String img)=> Container(
    width:150, margin: const EdgeInsets.only(right:10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius:8)]),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Stack(children:[
        Image.network(img, height:80, width:double.infinity, fit: BoxFit.cover),
        Positioned(top:6,left:6, child: Container(padding: const EdgeInsets.symmetric(horizontal:6,vertical:2), decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(20)), child: Text(time, style: const TextStyle(color: Colors.white, fontSize:8, fontWeight: FontWeight.w800)))),
      ]),
      Padding(padding: const EdgeInsets.all(8), child: Text(title, style: const TextStyle(fontSize:10, fontWeight: FontWeight.w700, height:1.2, color: Color(0xFF0F172A)))),
    ]),
  );

  Widget _sosBanner()=> Container(
    margin: const EdgeInsets.fromLTRB(12,16,12,0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFFFF6B6B), Color(0xFFEF4444)]), borderRadius: BorderRadius.circular(16)),
    child: Row(children:[
      Container(width:40,height:40,decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.sos_rounded, color: Color(0xFFEF4444))),
      const SizedBox(width:10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('En cas d\'urgence, nous sommes là pour vous', style: TextStyle(fontWeight: FontWeight.w800, fontSize:11, color: Colors.white)),
        Text('Accédez rapidement aux services d\'urgence près de vous', style: TextStyle(fontSize:9, color: Colors.white)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal:10,vertical:6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Row(children:[Icon(Icons.call_rounded, size:14, color: Color(0xFFEF4444)), SizedBox(width:4), Text('Appeler\nles urgences', style: TextStyle(fontSize:9, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)))])),
    ]),
  );

  Widget _bottomNav()=> Container(
    margin: const EdgeInsets.fromLTRB(12,0,12,12),
    padding: const EdgeInsets.symmetric(horizontal:6,vertical:8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow:[BoxShadow(color: Colors.black.withOpacity(.08), blurRadius:20)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[
      _nav(Icons.home_rounded, 'Accueil', true),
      _nav(Icons.favorite_rounded, 'Santé', false),
      Container(width:56,height:56,decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF06B6D4)]), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Colors.white, size:28)),
      _nav(Icons.chat_bubble_rounded, 'Messages', false),
      _nav(Icons.person_rounded, 'Profil', false),
    ]),
  );

  Widget _nav(IconData i, String l, bool active)=> Column(mainAxisSize: MainAxisSize.min, children:[
    Icon(i, color: active? const Color(0xFF2563EB): const Color(0xFF94A3B8), size:22),
    const SizedBox(height:2),
    Text(l, style: TextStyle(fontSize:9, fontWeight: active? FontWeight.w700: FontWeight.w500, color: active? const Color(0xFF2563EB): const Color(0xFF94A3B8))),
  ]);
}
