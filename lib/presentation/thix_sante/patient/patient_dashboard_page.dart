// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'dart:async';
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

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({super.key});
  @override
  ConsumerState<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  final PageController _heroCtrl = PageController();
  int _heroIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if(!_heroCtrl.hasClients) return;
      _heroIndex = (_heroIndex + 1) % 4;
      _heroCtrl.animateToPage(_heroIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }
  @override
  void dispose() { _timer?.cancel(); _heroCtrl.dispose(); super.dispose(); }

  void _go(Widget page)=>Navigator.push(context, MaterialPageRoute(builder:(_)=>page));

  @override
  Widget build(BuildContext context){
    final stats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(),
            SliverToBoxAdapter(child: _heroCarousel()),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverToBoxAdapter(child: _quickAccess()),
            SliverToBoxAdapter(child: _resumeHeader()),
            SliverToBoxAdapter(child: _resumeCards(stats)),
            SliverToBoxAdapter(child: _sectionTitle('Services santé', onVoirTout: ()=> _go(PlusServicesPage()))),
            SliverToBoxAdapter(child: _servicesSante()),
            SliverToBoxAdapter(child: _sectionTitle('Services rapides', onVoirTout: ()=> _go(PlusServicesPage()))),
            SliverToBoxAdapter(child: _servicesRapides()),
            SliverToBoxAdapter(child: _sectionTitle('Autres services', icon: Icons.grid_view_rounded)),
            SliverToBoxAdapter(child: _autresServices()),
            SliverToBoxAdapter(child: _assuranceBanners()),
            SliverToBoxAdapter(child: _sectionTitle('Pour vous', icon: Icons.favorite_rounded)),
            SliverToBoxAdapter(child: _pourVous()),
            SliverToBoxAdapter(child: _sosBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------- APPBAR EXACT MAQUETTE ----------
  Widget _appBar() => SliverAppBar(
    floating: true,
    backgroundColor: const Color(0xFFF8FAFC),
    elevation: 0,
    toolbarHeight: 64,
    leadingWidth: 60,
    leading: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10)]),
        child: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A)),
      ),
    ),
    title: Row(children:[
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF00D18F)]),
        ),
        child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 8),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[Text('THIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A))), Text(' SANTÉ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF00C896)))]),
        Text('Votre santé, notre priorité.', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
      ])
    ]),
    actions: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 10)]),
        child: Stack(children:[
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)), onPressed: ()=> _go(const AssistantIAPage())),
          Positioned(top: 6, right: 6, child: Container(width: 16, height: 16, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle), child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))))),
        ]),
      ),
      const SizedBox(width: 10),
      const Padding(padding: EdgeInsets.only(right: 12), child: CircleAvatar(radius: 20, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'))),
    ],
  );

  // ---------- HERO 4 BANNERS AUTO SCROLL ----------
  Widget _heroCarousel(){
    final banners = [
      {'t1':'Votre santé','t2':'entre de bonnes\nmains','sub':'Consultez, suivez et prenez soin\nde votre santé au quotidien.','btn':'Dossier de santé','img':'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=500'},
      {'t1':'Téléconsultation','t2':'24h/24 et 7j/7','sub':'Parlez à un médecin sans vous déplacer.','btn':'Consulter','img':'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500'},
      {'t1':'Pharmacie','t2':'à proximité','sub':'Trouvez vos médicaments en temps réel.','btn':'Trouver','img':'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=500'},
      {'t1':'Urgences','t2':'toujours là','sub':'Localisez l\'hôpital le plus proche en 1 clic.','btn':'Urgences','img':'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=500'},
    ];
    return Column(children:[
      SizedBox(
        height: 192,
        child: PageView.builder(
          controller: _heroCtrl,
          onPageChanged: (i)=> setState(()=> _heroIndex=i),
          itemCount: 4,
          itemBuilder: (_, i){
            final b = banners[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF0EA5E9), Color(0xFF06B6D4)]),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children:[
                Positioned(right: 80, top: 18, child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle))),
                Positioned(right: -2, bottom: 0, child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(b['img']!, width: 165, height: 192, fit: BoxFit.cover, errorBuilder: (_,__,___)=> const SizedBox(width: 165)))),
                Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF2563EB), Colors.transparent])))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16,14,150,12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    const Row(children:[Text('Bonjour, Michel ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)), Text('👋', style: TextStyle(fontSize: 12))]),
                    const SizedBox(height: 8),
                    Text('${b['t1']}\n${b['t2']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 19, height: 1.1)),
                    const SizedBox(height: 6),
                    Text(b['sub']!, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
                    const Spacer(),
                    InkWell(
                      onTap: ()=> _go(const DossierMedicalPage()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(mainAxisSize: MainAxisSize.min, children:[
                          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.folder_special_rounded, size: 14, color: Color(0xFF2563EB))),
                          const SizedBox(width: 6),
                          Text(b['btn']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF1E293B))),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF64748B)),
                        ]),
                      ),
                    )
                  ]),
                )
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i)=> AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _heroIndex==i? 22:7, height: 7,
        decoration: BoxDecoration(color: _heroIndex==i? const Color(0xFF22C55E) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
      ))),
    ]);
  }

  // ---------- QUICK ACCESS 6 ICONS ----------
  Widget _quickAccess(){
    final items = [
      {'l':'Rendez-vous','icon':Icons.calendar_month_rounded,'c':const Color(0xFF2563EB),'bg':const Color(0xFFEFF6FF),'p':const PrendreRdvPage()},
      {'l':'Consultation','icon':Icons.medical_services_rounded,'c':const Color(0xFF16A34A),'bg':const Color(0xFFEFFEF2),'p':const ConsulterMedecinPage()},
      {'l':'Examens','icon':Icons.biotech_rounded,'c':const Color(0xFF7C3AED),'bg':const Color(0xFFF5F3FF),'p':const ResultatsExamensPage()},
      {'l':'Ordonnances','icon':Icons.medication_rounded,'c':const Color(0xFF2563EB),'bg':const Color(0xFFEFF6FF),'p':const MesOrdonnancesPage()},
      {'l':'Urgences','icon':Icons.favorite_rounded,'c':const Color(0xFFEF4444),'bg':const Color(0xFFFEF2F2),'p':const UrgencesProchesPage()},
      {'l':'Plus','icon':Icons.more_horiz_rounded,'c':const Color(0xFF64748B),'bg':const Color(0xFFF1F5F9),'p':PlusServicesPage()},
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: items.map((it){
        return InkWell(
          onTap: ()=> _go(it['p'] as Widget),
          child: Column(children:[
            Container(width: 48, height: 48, decoration: BoxDecoration(color: it['bg'] as Color, borderRadius: BorderRadius.circular(14)), child: Icon(it['icon'] as IconData, color: it['c'] as Color, size: 26)),
            const SizedBox(height: 5),
            Text(it['l'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
          ]),
        );
      }).toList()),
    );
  }

  Widget _resumeHeader()=> Padding(
    padding: const EdgeInsets.fromLTRB(16,18,16,10),
    child: Row(children:[
      Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFF22C55E))),
      const SizedBox(width: 6),
      const Text('Résumé de santé', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
      const Spacer(),
      InkWell(onTap: (){}, child: const Row(children:[Text('Voir tout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))), Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB))])),
    ]),
  );

  Widget _resumeCards(AsyncValue<DashboardStats> s){
    return s.when(
      data: (d)=> Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children:[
          _resumeCard('Consultations','12','Cette année',Icons.calendar_month_rounded,const Color(0xFF2563EB),const Color(0xFFEFF6FF)),
          _resumeCard('Examens','${d.examens}','Complétés',Icons.biotech_rounded,const Color(0xFF16A34A),const Color(0xFFF0FDF4)),
          _resumeCard('Médicaments','${d.medicaments==0?3:d.medicaments}','En cours',Icons.medication_rounded,const Color(0xFF7C3AED),const Color(0xFFF5F3FF)),
          _resumeCard('Rendez-vous','${d.rdvs==0?2:d.rdvs}','À venir',Icons.event_rounded,const Color(0xFFF97316),const Color(0xFFFFF7ED)),
        ]),
      ),
      loading: ()=> const SizedBox(height: 70, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_,__)=> const SizedBox(),
    );
  }

  Widget _resumeCard(String title, String val, String sub, IconData icon, Color c, Color bg){
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3.5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(title, maxLines: 1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children:[
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF0F172A))),
          const Spacer(),
          Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: c)),
        ]),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ]),
    ));
  }

  Widget _sectionTitle(String t, {IconData icon = Icons.bolt_rounded, VoidCallback? onVoirTout}) => Padding(
    padding: const EdgeInsets.fromLTRB(16,18,16,10),
    child: Row(children:[
      Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
      const Spacer(),
      if(onVoirTout!=null) InkWell(onTap: onVoirTout, child: const Row(children:[Text('Voir tout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB))), Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB))])),
    ]),
  );

  Widget _sCard({required String title, required String sub, required IconData icon, required Color c, required Color bg, required VoidCallback onTap, String? emoji}){
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 10)]),
        child: Row(children:[
          Container(width: 44, height: 44, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)), child: emoji!=null? Center(child: Text(emoji, style: const TextStyle(fontSize: 22))) : Icon(icon, color: c, size: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.2), maxLines: 2),
          ])),
          Container(width: 22, height: 22, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF334155))),
        ]),
      ),
    );
  }

  Widget _servicesSante()=> Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children:[
      Row(children:[
        Expanded(child: _sCard(title:'Santé des enfants', sub:'Suivez la santé de vos enfants', icon: Icons.child_care_rounded, c: const Color(0xFF60A5FA), bg: const Color(0xFFEFF6FF), emoji: '👶', onTap: ()=> _go(const SanteEnfantsPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Carnet de vaccination', sub:'Consultez et gérez les vaccins', icon: Icons.vaccines_rounded, c: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE), onTap: ()=> _go(const CarnetVaccinationPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Suivi grossesses', sub:'Suivez votre grossesse pas à pas', icon: Icons.pregnant_woman_rounded, c: const Color(0xFFEC4899), bg: const Color(0xFFFDF2F8), emoji: '🤰', onTap: ()=> _go(const SuiviGrossessePage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Assurance santé', sub:'Protégez votre santé et celle de vos proches', icon: Icons.shield_rounded, c: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE), onTap: ()=> _go(const AssuranceSantePage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Assurance', sub:'Découvrez nos solutions d\'assurance adaptées', icon: Icons.umbrella_rounded, c: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7), onTap: ()=> _go(const AssuranceSantePage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Plus de services', sub:'Découvrez tous nos services', icon: Icons.grid_view_rounded, c: const Color(0xFF2563EB), bg: const Color(0xFFEFF6FF), onTap: ()=> _go(PlusServicesPage()))),
      ]),
    ]),
  );

  Widget _servicesRapides()=> Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children:[
      Row(children:[
        Expanded(child: _sCard(title:'Consulter un médecin', sub:'Parlez à un professionnel', icon: Icons.medical_services_rounded, c: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE), onTap: ()=> _go(const ConsulterMedecinPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Dossier médical', sub:'Accédez à votre dossier de santé', icon: Icons.folder_special_rounded, c: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7), onTap: ()=> _go(const DossierMedicalPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Résultats d\'examens', sub:'Consultez vos analyses', icon: Icons.biotech_rounded, c: const Color(0xFF7C3AED), bg: const Color(0xFFEDE9FE), onTap: ()=> _go(const ResultatsExamensPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Mes ordonnances', sub:'Gérez et renouvelez vos ordonnances', icon: Icons.receipt_long_rounded, c: const Color(0xFFF97316), bg: const Color(0xFFFFEDD5), onTap: ()=> _go(const MesOrdonnancesPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Trouver un hôpital', sub:'Trouvez l\'hôpital le plus proche', icon: Icons.local_hospital_rounded, c: const Color(0xFFEF4444), bg: const Color(0xFFFEF2F2), onTap: ()=> _go(const TrouverHopitalPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Trouver un médicament', sub:'Vérifiez la disponibilité des médicaments', icon: Icons.medication_rounded, c: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7), onTap: ()=> _go(const TrouverMedicamentPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Pharmacies proches', sub:'Trouvez la pharmacie la plus proche', icon: Icons.local_pharmacy_rounded, c: const Color(0xFF16A34A), bg: const Color(0xFFDCFCE7), onTap: ()=> _go(const PharmaciesProchesPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Urgences proches', sub:'Services d\'urgence disponibles 24/7', icon: Icons.emergency_rounded, c: const Color(0xFFEF4444), bg: const Color(0xFFFEF2F2), onTap: ()=> _go(const UrgencesProchesPage()))),
      ]),
    ]),
  );

  // --- AUTRES SERVICES (tout le reste de ton code) ---
  Widget _autresServices()=> Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(children:[
      Row(children:[
        Expanded(child: _sCard(title:'Téléconsultation', sub:'Consultez à distance', icon: Icons.videocam_rounded, c: const Color(0xFF6366F1), bg: const Color(0xFFE0E7FF), onTap: ()=> _go(const TeleconsultationPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Assistant IA', sub:'Aide intelligente 24/7', icon: Icons.smart_toy_rounded, c: const Color(0xFF0EA5E9), bg: const Color(0xFFE0F2FE), onTap: ()=> _go(const AssistantIAPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Second avis', sub:'Avis médical expert', icon: Icons.people_alt_rounded, c: const Color(0xFFEA580C), bg: const Color(0xFFFFEDD5), onTap: ()=> _go(const SecondAvisPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Mon médecin', sub:'Médecin traitant', icon: Icons.person_rounded, c: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE), onTap: ()=> _go(const MonMedecinTraitantPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Dossier famille', sub:'Gérez votre famille', icon: Icons.family_restroom_rounded, c: const Color(0xFFEC4899), bg: const Color(0xFFFDF2F8), onTap: ()=> _go(const DossierFamillePage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Carnet vaccination', sub:'Vaccins & rappels', icon: Icons.vaccines_rounded, c: const Color(0xFF06B6D4), bg: const Color(0xFFCFFAFE), onTap: ()=> _go(const RappelsVaccinPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Nutrition', sub:'Conseils alimentaires', icon: Icons.restaurant_rounded, c: const Color(0xFF22C55E), bg: const Color(0xFFDCFCE7), onTap: ()=> _go(const NutritionPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Bien-être mental', sub:'Santé mentale', icon: Icons.psychology_rounded, c: const Color(0xFF8B5CF6), bg: const Color(0xFFEDE9FE), onTap: ()=> _go(const BienEtreMentalPage()))),
      ]),
      const SizedBox(height: 8),
      Row(children:[
        Expanded(child: _sCard(title:'Don de sang', sub:'Sauvez des vies', icon: Icons.water_drop_rounded, c: const Color(0xFFDC2626), bg: const Color(0xFFFEF2F2), onTap: ()=> _go(const DonSangPage()))),
        const SizedBox(width: 8),
        Expanded(child: _sCard(title:'Analyse prédictive', sub:'Prédictions santé', icon: Icons.show_chart_rounded, c: const Color(0xFF7C3AED), bg: const Color(0xFFF5F3FF), onTap: ()=> _go(const AnalysePredictivePage()))),
      ]),
    ]),
  );

  Widget _assuranceBanners()=> Padding(
    padding: const EdgeInsets.fromLTRB(12,16,12,0),
    child: Row(children:[
      Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(16)), child: Row(children:[
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 8),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('Assurance santé', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text('Bénéficiez d\'une couverture complète adaptée à vos besoins.', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))])),
        const Icon(Icons.arrow_forward_rounded, size: 14),
      ]))),
      const SizedBox(width: 8),
      Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16)), child: Row(children:[
        Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.umbrella_rounded, color: Colors.white, size: 20)),
        const SizedBox(width: 8),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('Assurance', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text('Protégez-vous et vos proches avec nos solutions.', style: TextStyle(fontSize: 9, color: Color(0xFF64748B)))])),
        const Icon(Icons.arrow_forward_rounded, size: 14),
      ]))),
    ]),
  );

  Widget _pourVous()=> SizedBox(
    height: 165,
    child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children:[
      _article('Conseil santé','5 conseils pour rester\nen bonne santé','3 min de lecture','https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400'),
      _article('Nutrition','Alimentation équilibrée :\nles bases','4 min de lecture','https://images.unsplash.com/photo-1512621776952-a57141f2eefd?w=400'),
      _article('Bien-être','Gérer le stress au\nquotidien','3 min de lecture','https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400'),
      _article('Prévention','Prévention : un geste\nqui sauve','2 min de lecture','https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400'),
    ]),
  );

  Widget _article(String tag, String title, String time, String img)=> Container(
    width: 155, margin: const EdgeInsets.only(right: 10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)]),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Stack(children:[
        Image.network(img, height: 88, width: double.infinity, fit: BoxFit.cover),
        Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(20)), child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)))),
      ]),
      Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.2, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Row(children:[Text(time, style: const TextStyle(fontSize: 8, color: Color(0xFF94A3B8))), const Spacer(), Container(width: 16, height: 16, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_rounded, size: 10))]),
      ])),
    ]),
  );

  Widget _sosBanner()=> Container(
    margin: const EdgeInsets.fromLTRB(12,16,12,0),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFFFF1F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFECDD3))),
    child: Row(children:[
      Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFECDD3))), child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFEF4444))),
      const SizedBox(width: 10),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Besoin d\'aide immédiate?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A))),
        Text('Contactez les urgences en un clic.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ])),
      ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.call_rounded, size: 14), label: const Text('Appeler 15', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    ]),
  );

  Widget _bottomNav()=> Container(
    margin: const EdgeInsets.fromLTRB(12,0,12,12),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 20)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[
      _nav(Icons.home_rounded, 'Accueil', true),
      _nav(Icons.favorite_rounded, 'Santé', false),
      Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF06B6D4)]), shape: BoxShape.circle, boxShadow:[BoxShadow(color: const Color(0xFF2563EB).withOpacity(.35), blurRadius: 12)]), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(Icons.add_rounded, color: Colors.white, size: 22), Text('Nouveau', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700))])),
      _nav(Icons.chat_bubble_rounded, 'Messages', false),
      _nav(Icons.person_rounded, 'Profil', false),
    ]),
  );

  Widget _nav(IconData i, String l, bool active)=> Column(mainAxisSize: MainAxisSize.min, children:[
    Icon(i, color: active? const Color(0xFF2563EB): const Color(0xFF94A3B8), size: 22),
    const SizedBox(height: 2),
    Text(l, style: TextStyle(fontSize: 9, fontWeight: active? FontWeight.w700: FontWeight.w500, color: active? const Color(0xFF2563EB): const Color(0xFF94A3B8))),
  ]);
}
