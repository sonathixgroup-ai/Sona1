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
import 'screens/don_sang_page.dart';          // ✅ corrigé
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

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});
  void _go(BuildContext c, Widget page)=>Navigator.push(c, MaterialPageRoute(builder:(_)=>page));
  void _todo(BuildContext c)=>ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('Bientot disponible')));

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final stats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(child: CustomScrollView(slivers:[
        SliverAppBar(floating:true, backgroundColor:Colors.white, elevation:0, toolbarHeight:64,
          leading: IconButton(icon:const Icon(Icons.menu_rounded,color:Color(0xFF0F172A)),onPressed:(){}),
          title: Row(children:[Container(padding:const EdgeInsets.all(7), decoration:BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF2563EB),Color(0xFF06B6D4)]),borderRadius:BorderRadius.circular(10), boxShadow:[BoxShadow(color:ThixSanteColors.primary.withOpacity(.35),blurRadius:10,offset:const Offset(0,3))]), child:const Icon(Icons.add_rounded,color:Colors.white,size:18)),const SizedBox(width:8),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('THIX SANTE',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15,color:Color(0xFF0F172A))),Text('Votre sante, notre priorite',style:TextStyle(fontSize:11,color:Color(0xFF64748B)))])]),
          actions:[Stack(children:[IconButton(icon:const Icon(Icons.notifications_none_rounded),onPressed:()=>_go(context,const AssistantIAPage())),Positioned(top:10,right:10,child:Container(width:18,height:18,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:const Center(child:Text('3',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)))))]),const Padding(padding:EdgeInsets.only(right:12),child:CircleAvatar(radius:18,backgroundImage:NetworkImage('https://i.pravatar.cc/100?img=12')))],
        ),
        SliverToBoxAdapter(child: _hero(context)),
        const SliverToBoxAdapter(child:SizedBox(height:14)),
        SliverToBoxAdapter(child: _stats(stats)),
        SliverToBoxAdapter(child: _categoryCard(
          title: 'Services rapides',
          child: _rapides(context),
        )),
        SliverToBoxAdapter(child: _categoryCard(
          title: 'Services sante',
          child: _sante(context),
        )),
        const SliverToBoxAdapter(child:SizedBox(height:90)),
      ])),
    );
  }

  // ---------- HERO ----------
  Widget _hero(BuildContext context)=>Container(
    margin: const EdgeInsets.symmetric(horizontal:16),
    padding: const EdgeInsets.fromLTRB(22,24,14,24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors:[Color(0xFF2563EB),Color(0xFF3B82F6),Color(0xFF06B6D4)],
      ),
      boxShadow:[BoxShadow(color: const Color(0xFF2563EB).withOpacity(.35), blurRadius:28, offset:const Offset(0,14))],
    ),
    child: Stack(clipBehavior: Clip.none, children:[
      // halos lumineux décoratifs
      Positioned(top:-30, right:-20, child: Container(width:110,height:110, decoration: BoxDecoration(shape:BoxShape.circle, color: Colors.white.withOpacity(.10)))),
      Positioned(bottom:-40, right:40, child: Container(width:80,height:80, decoration: BoxDecoration(shape:BoxShape.circle, color: Colors.white.withOpacity(.08)))),
      Row(children:[
        Expanded(flex:3, child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('Bonjour, Patient 👋', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize:13)),
          const SizedBox(height:10),
          const Text('Votre sante\nentre de bonnes\nmains', style: TextStyle(color: Colors.white, fontSize:30, fontWeight: FontWeight.w900, height:1.08, letterSpacing:-.5)),
          const SizedBox(height:18),
          Row(children:[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: ()=>_go(context, const DossierMedicalPage()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal:18, vertical:13),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow:[BoxShadow(color: Colors.black.withOpacity(.12), blurRadius:12, offset:const Offset(0,6))]),
                  child: Row(mainAxisSize: MainAxisSize.min, children:[
                    Icon(Icons.folder_shared_rounded, color: ThixSanteColors.primary, size:16),
                    const SizedBox(width:8),
                    Text('Mon Dossier Sante', style: TextStyle(color: ThixSanteColors.primary, fontWeight: FontWeight.w800, fontSize:13)),
                  ]),
                ),
              ),
            ),
          ]),
        ])),
        Expanded(flex:2, child: Image.network(
          'https://cdn3d.iconscout.com/3d/premium/thumb/doctor-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-care-pack-medical-icons-5183886.png',
          height:120, errorBuilder:(_,__,___)=>const Icon(Icons.medical_services_rounded, color: Colors.white, size:60),
        )),
      ]),
    ]),
  );

  // ---------- STATS ----------
  Widget _stats(AsyncValue<DashboardStats> s)=>s.when(
    data: (d)=>Padding(
      padding: const EdgeInsets.symmetric(horizontal:16),
      child: Row(children:[
        Expanded(child: _stat(Icons.monitor_heart_rounded, const Color(0xFF2563EB), '${d.consultations}', 'Consultations')),
        const SizedBox(width:10),
        Expanded(child: _stat(Icons.biotech_rounded, const Color(0xFF16A34A), '${d.examens}', 'Examens')),
        const SizedBox(width:10),
        Expanded(child: _stat(Icons.medication_rounded, const Color(0xFF7C3AED), '${d.medicaments}', 'Medicaments')),
      ]),
    ),
    loading: ()=>const SizedBox(height:84, child: Center(child: CircularProgressIndicator(strokeWidth:2))),
    error: (_,__)=>const SizedBox(height:84),
  );

  Widget _stat(IconData icon, Color color, String value, String label)=>Container(
    padding: const EdgeInsets.symmetric(horizontal:12, vertical:14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(18),
      boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius:14, offset:const Offset(0,6))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Row(children:[
        Container(width:30, height:30, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size:16)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize:22, color: const Color(0xFF0F172A))),
      ]),
      const SizedBox(height:8),
      Text(label, style: const TextStyle(fontSize:11, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
    ]),
  );

  // ---------- CADRE PAR CATEGORIE ----------
  Widget _categoryCard({required String title, required Widget child}) => Container(
    margin: const EdgeInsets.fromLTRB(16,20,16,0),
    padding: const EdgeInsets.fromLTRB(14,16,14,14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE7ECF5)),
      boxShadow:[BoxShadow(color: Colors.black.withOpacity(.03), blurRadius:16, offset:const Offset(0,8))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Row(children:[
        Container(width:4, height:16, decoration: BoxDecoration(color: ThixSanteColors.primary, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width:8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:15, color: Color(0xFF0F172A))),
      ]),
      const SizedBox(height:12),
      child,
    ]),
  );

  // ---------- GRID ITEM ----------
  Widget _gridItem(BuildContext context, Map<String,dynamic> it) {
    final Color color = (it['color'] as Color?) ?? ThixSanteColors.primary;
    return InkWell(
      onTap: ()=>_go(context, it['p'] as Widget),
      borderRadius: BorderRadius.circular(16),
      child: Stack(children:[
        Container(
          padding: const EdgeInsets.symmetric(vertical:10, horizontal:4),
          decoration: BoxDecoration(
            color: color.withOpacity(.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(.12)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
            Container(width:36, height:36,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11),
                boxShadow:[BoxShadow(color: color.withOpacity(.18), blurRadius:8, offset:const Offset(0,3))]),
              child: Icon(it['icon'] as IconData, color: color, size:17)),
            const SizedBox(height:7),
            Text(it['l'] as String, textAlign: TextAlign.center,
              style: const TextStyle(fontSize:10.5, fontWeight: FontWeight.w700, height:1.15, color: Color(0xFF1E293B))),
          ]),
        ),
        if (it['new']==true) Positioned(top:4, right:4, child: Container(
          padding: const EdgeInsets.symmetric(horizontal:5, vertical:2),
          decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(6)),
          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize:7, fontWeight: FontWeight.w900)),
        )),
      ]),
    );
  }

  Widget _grid(BuildContext context, List<Map<String,dynamic>> items) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount:4, crossAxisSpacing:8, mainAxisSpacing:8, childAspectRatio:.86,
    ),
    itemCount: items.length,
    itemBuilder: (c,i)=>_gridItem(context, items[i]),
  );

  Widget _rapides(BuildContext context) => _grid(context, [
    {'l':'Consulter\nmedecin','icon':Icons.medical_services_rounded,'p':const ConsulterMedecinPage(),'color':const Color(0xFF2563EB)},
    {'l':'Dossier\nmedical','icon':Icons.folder_rounded,'p':const DossierMedicalPage(),'color':const Color(0xFF7C3AED)},
    {'l':'Resultats\nexamens','icon':Icons.biotech_rounded,'p':const ResultatsExamensPage(),'color':const Color(0xFF16A34A)},
    {'l':'Mes\nordonnances','icon':Icons.receipt_long_rounded,'p':const MesOrdonnancesPage(),'color':const Color(0xFF9333EA)},
    {'l':'Trouver\nhopital','icon':Icons.local_hospital_rounded,'p':const TrouverHopitalPage(),'color':const Color(0xFFDC2626)},
    {'l':'Trouver\nmedicament','icon':Icons.medication_rounded,'p':const TrouverMedicamentPage(),'color':const Color(0xFF0D9488)},
    {'l':'Pharmacies\nproches','icon':Icons.add_business_rounded,'p':const PharmaciesProchesPage(),'color':const Color(0xFF16A34A)},
    {'l':'Urgences\nproches','icon':Icons.emergency_rounded,'p':const UrgencesProchesPage(),'color':const Color(0xFFEA580C)},
    {'l':'Prendre\nRDV','icon':Icons.event_rounded,'p':const PrendreRdvPage(),'color':const Color(0xFF0891B2)},
    {'l':'Teleconsult\nation','icon':Icons.videocam_rounded,'p':const TeleconsultationPage(),'color':const Color(0xFF2563EB)},
    {'l':'Assistant\nIA','icon':Icons.smart_toy_rounded,'p':const AssistantIAPage(),'color':const Color(0xFF6366F1)},
    {'l':'Dossier\npartage','icon':Icons.link_rounded,'p':const DossierPartagePage(),'color':const Color(0xFF7C3AED)},
    {'l':'Epidemies','icon':Icons.coronavirus_rounded,'p':const EpidemiesPage(),'color':const Color(0xFFEA580C)},
    {'l':'Don de sang','icon':Icons.water_drop_rounded,'p':const DonSangPage(),'color':const Color(0xFFDC2626)},
    {'l':'Mon Medecin\nTraitant','icon':Icons.medical_services_rounded,'p':const MonMedecinTraitantPage(),'new':true,'color':const Color(0xFFDB2777)},
    {'l':'Dossier\nFamille','icon':Icons.family_restroom_rounded,'p':const DossierFamillePage(),'new':true,'color':const Color(0xFFDB2777)},
    {'l':'Second Avis\nMedical','icon':Icons.medical_information_rounded,'p':const SecondAvisPage(),'new':true,'color':const Color(0xFFEA580C)},
    {'l':'Rappels\nvaccin','icon':Icons.vaccines_rounded,'p':const RappelsVaccinPage(),'color':const Color(0xFF0D9488)},
    {'l':'Certificat\nmedical','icon':Icons.description_rounded,'p':const CertificatMedicalPage(),'color':const Color(0xFF475569)},
    {'l':'Assurance\nsante','icon':Icons.shield_rounded,'p':const AssuranceSantePage(),'color':const Color(0xFF4F46E5)},
  ]);

  Widget _sante(BuildContext context) => _grid(context, [
    {'l':'Sante\nenfants','icon':Icons.child_care_rounded,'p':const SanteEnfantsPage(),'color':const Color(0xFFDB2777)},
    {'l':'Carnet\nvaccination','icon':Icons.vaccines_rounded,'p':const CarnetVaccinationPage(),'color':const Color(0xFF0D9488)},
    {'l':'Suivi\ngrossesse','icon':Icons.pregnant_woman_rounded,'p':const SuiviGrossessePage(),'color':const Color(0xFFDB2777)},
    {'l':'Dossier\nmedical','icon':Icons.folder_rounded,'p':const DossierMedicalPage(),'color':const Color(0xFF7C3AED)},
    {'l':'Analyse\npredictive','icon':Icons.show_chart_rounded,'p':const AnalysePredictivePage(),'color':const Color(0xFF2563EB)},
    {'l':'Bien-etre\nmental','icon':Icons.psychology_rounded,'p':const BienEtreMentalPage(),'color':const Color(0xFF6366F1)},
    {'l':'Nutrition','icon':Icons.apple_rounded,'p':const NutritionPage(),'color':const Color(0xFF16A34A)},
    {'l':'Activite\nphysique','icon':Icons.fitness_center_rounded,'p':const ActivitePhysiquePage(),'color':const Color(0xFFEA580C)},
    {'l':'Gestion\nstress','icon':Icons.self_improvement_rounded,'p':const GestionStressPage(),'color':const Color(0xFF0891B2)},
    {'l':'Assurance','icon':Icons.shield_rounded,'p':const AssuranceSantePage(),'color':const Color(0xFF4F46E5)},
    {'l':'Plus de\nservices','icon':Icons.grid_view_rounded,'p':PlusServicesPage(),'color':const Color(0xFF475569)},
  ]);
}
