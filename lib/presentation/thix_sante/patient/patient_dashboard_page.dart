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
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(child: CustomScrollView(slivers:[
        SliverAppBar(floating:true, backgroundColor:Colors.white, elevation:0, toolbarHeight:64,
          leading: IconButton(icon:const Icon(Icons.menu_rounded,color:Color(0xFF0F172A)),onPressed:(){}),
          title: Row(children:[
            Container(
              width:34, height:34,
              decoration: BoxDecoration(gradient: const LinearGradient(colors:[Color(0xFF2563EB),Color(0xFF06B6D4)]),borderRadius:BorderRadius.circular(10)),
              child: const Icon(Icons.health_and_safety_rounded,color:Colors.white,size:19),
            ),
            const SizedBox(width:8),
            const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('THIX SANTE',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15,color:Color(0xFF0F172A))),
              Text('Votre sante, notre priorite',style:TextStyle(fontSize:11,color:Color(0xFF64748B))),
            ]),
          ]),
          actions:[
            Stack(children:[
              IconButton(icon:const Icon(Icons.notifications_none_rounded),onPressed:()=>_go(context,const AssistantIAPage())),
              Positioned(top:10,right:10,child:Container(width:18,height:18,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:const Center(child:Text('3',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700))))),
            ]),
            const Padding(padding:EdgeInsets.only(right:12),child:CircleAvatar(radius:18,backgroundImage:NetworkImage('https://i.pravatar.cc/100?img=12'))),
          ],
        ),
        SliverToBoxAdapter(child: _hero(context)),
        const SliverToBoxAdapter(child:SizedBox(height:16)),
        SliverToBoxAdapter(child: _stats(stats)),
        SliverToBoxAdapter(child: _sectionTitle(context, '⚡ Services rapides')),
        SliverToBoxAdapter(child: _rapides(context)),
        SliverToBoxAdapter(child: _sectionTitle(context, '🏥 Services sante')),
        SliverToBoxAdapter(child: _sante(context)),
        const SliverToBoxAdapter(child:SizedBox(height:90)),
      ])),
    );
  }

  // ---------- HERO ----------
  Widget _hero(BuildContext context)=>Container(
    margin: const EdgeInsets.symmetric(horizontal:16),
    padding: const EdgeInsets.fromLTRB(20,22,16,22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors:[Color(0xFF2563EB),Color(0xFF3B82F6),Color(0xFF06B6D4)],
      ),
      boxShadow:[BoxShadow(color: const Color(0xFF2563EB).withOpacity(.3), blurRadius:24, offset:const Offset(0,12))],
    ),
    child: Row(children:[
      Expanded(flex:3, child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        const Text('Bonjour, Patient 👋', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize:13)),
        const SizedBox(height:10),
        const Text('Votre sante\nentre de bonnes\nmains', style: TextStyle(color: Colors.white, fontSize:24, fontWeight: FontWeight.w900, height:1.1, letterSpacing:-.3)),
        const SizedBox(height:8),
        const Text('Consultez, suivez et prenez soin\nde votre sante au quotidien.', style: TextStyle(color: Colors.white70, fontSize:11.5, height:1.3)),
        const SizedBox(height:16),
        Row(children:[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: ()=>_go(context, const DossierMedicalPage()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal:14, vertical:12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children:[
                  Icon(Icons.folder_shared_rounded, color: ThixSanteColors.primary, size:15),
                  const SizedBox(width:6),
                  Text('Dossier sante', style: TextStyle(color: ThixSanteColors.primary, fontWeight: FontWeight.w800, fontSize:11.5)),
                ]),
              ),
            ),
          ),
          const SizedBox(width:8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal:12, vertical:10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(14)),
            child: const Row(mainAxisSize: MainAxisSize.min, children:[
              Icon(Icons.bar_chart_rounded, color: Colors.white, size:15),
              SizedBox(width:6),
              Text('Score 85%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize:11.5)),
            ]),
          ),
        ]),
      ])),
      Expanded(flex:2, child: Image.network(
        'https://cdn3d.iconscout.com/3d/premium/thumb/doctor-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-care-pack-medical-icons-5183886.png',
        height:105, errorBuilder:(_,__,___)=>const Icon(Icons.medical_services_rounded, color: Colors.white, size:55),
      )),
    ]),
  );

  // ---------- STATS (4 cartes) ----------
  Widget _stats(AsyncValue<DashboardStats> s)=>s.when(
    data: (d)=>Padding(
      padding: const EdgeInsets.symmetric(horizontal:16),
      child: Row(children:[
        Expanded(child: _stat(Icons.calendar_month_rounded, const Color(0xFF2563EB), '${d.consultations}', 'Consultations', 'Cette annee')),
        const SizedBox(width:8),
        Expanded(child: _stat(Icons.biotech_rounded, const Color(0xFF16A34A), '${d.examens}', 'Examens', 'Completes')),
        const SizedBox(width:8),
        Expanded(child: _stat(Icons.medication_rounded, const Color(0xFF7C3AED), '${d.medicaments}', 'Medicaments', 'En cours')),
        const SizedBox(width:8),
        Expanded(child: _stat(Icons.access_time_filled_rounded, const Color(0xFFEA580C), '${d.rdvs}', 'Rendez-vous', 'A venir')),
      ]),
    ),
    loading: ()=>const SizedBox(height:90, child: Center(child: CircularProgressIndicator(strokeWidth:2))),
    error: (_,__)=>const SizedBox(height:90),
  );

  Widget _stat(IconData icon, Color color, String value, String label, String sub)=>Container(
    padding: const EdgeInsets.symmetric(horizontal:8, vertical:12),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow:[BoxShadow(color: Colors.black.withOpacity(.04), blurRadius:10, offset:const Offset(0,5))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      Container(width:28, height:28, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size:15)),
      const SizedBox(height:8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:19, color: Color(0xFF0F172A))),
      Text(label, style: const TextStyle(fontSize:9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
      Text(sub, style: const TextStyle(fontSize:8.5, color: Color(0xFF94A3B8))),
    ]),
  );

  // ---------- TITRE DE SECTION avec "Voir tout" ----------
  Widget _sectionTitle(BuildContext context, String t)=>Padding(
    padding: const EdgeInsets.fromLTRB(18,20,18,12),
    child: Row(children:[
      Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize:15.5, color: Color(0xFF0F172A))),
      const Spacer(),
      InkWell(onTap: ()=>_todo(context), child: Row(children:[
        Text('Voir tout', style: TextStyle(color: ThixSanteColors.primary, fontSize:12, fontWeight: FontWeight.w700)),
        Icon(Icons.chevron_right_rounded, color: ThixSanteColors.primary, size:16),
      ])),
    ]),
  );

  // ---------- GRID ITEM (carre colore, petit, comme la photo) ----------
  Widget _gridItem(BuildContext context, Map<String,dynamic> it) {
    final Color color = (it['color'] as Color?) ?? ThixSanteColors.primary;
    return InkWell(
      onTap: ()=>_go(context, it['p'] as Widget),
      borderRadius: BorderRadius.circular(16),
      child: Stack(clipBehavior: Clip.none, children:[
        Column(mainAxisAlignment: MainAxisAlignment.center, children:[
          Container(
            width:56, height:56,
            decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(15)),
            child: Icon(it['icon'] as IconData, color: color, size:24),
          ),
          const SizedBox(height:6),
          Text(it['l'] as String, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize:10, fontWeight: FontWeight.w700, height:1.15, color: Color(0xFF1E293B))),
        ]),
        if (it['new']==true) Positioned(top:-4, right:2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal:5, vertical:1.5),
          decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(7)),
          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize:7, fontWeight: FontWeight.w900)),
        )),
      ]),
    );
  }

  Widget _grid(BuildContext context, List<Map<String,dynamic>> items) => Padding(
    padding: const EdgeInsets.symmetric(horizontal:14),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:4, crossAxisSpacing:2, mainAxisSpacing:16, childAspectRatio:.82,
      ),
      itemCount: items.length,
      itemBuilder: (c,i)=>_gridItem(context, items[i]),
    ),
  );

  Widget _rapides(BuildContext context) => _grid(context, [
    {'l':'Consulter\nmedecin','icon':Icons.medical_services_rounded,'p':const ConsulterMedecinPage(),'color':const Color(0xFF2563EB)},
    {'l':'Dossier\nmedical','icon':Icons.folder_rounded,'p':const DossierMedicalPage(),'color':const Color(0xFF2563EB)},
    {'l':'Resultats\nexamens','icon':Icons.biotech_rounded,'p':const ResultatsExamensPage(),'color':const Color(0xFF16A34A)},
    {'l':'Mes\nordonnances','icon':Icons.receipt_long_rounded,'p':const MesOrdonnancesPage(),'color':const Color(0xFF7C3AED)},
    {'l':'Trouver\nhopital','icon':Icons.local_hospital_rounded,'p':const TrouverHopitalPage(),'color':const Color(0xFF0D9488)},
    {'l':'Trouver\nmedicament','icon':Icons.medication_rounded,'p':const TrouverMedicamentPage(),'color':const Color(0xFF4F46E5)},
    {'l':'Pharmacies\nproches','icon':Icons.add_business_rounded,'p':const PharmaciesProchesPage(),'color':const Color(0xFF16A34A)},
    {'l':'Urgences\nproches','icon':Icons.emergency_rounded,'p':const UrgencesProchesPage(),'color':const Color(0xFFDC2626)},
    {'l':'Prendre\nRDV','icon':Icons.event_rounded,'p':const PrendreRdvPage(),'color':const Color(0xFFEA580C)},
    {'l':'Teleconsult\nation','icon':Icons.videocam_rounded,'p':const TeleconsultationPage(),'color':const Color(0xFF7C3AED)},
    {'l':'Assistant\nIA','icon':Icons.smart_toy_rounded,'p':const AssistantIAPage(),'color':const Color(0xFF0891B2)},
    {'l':'Dossier\npartage','icon':Icons.share_rounded,'p':const DossierPartagePage(),'color':const Color(0xFF6366F1)},
    {'l':'Epidemies','icon':Icons.coronavirus_rounded,'p':const EpidemiesPage(),'color':const Color(0xFFDC2626)},
    {'l':'Don de\nsang','icon':Icons.water_drop_rounded,'p':const DonSangPage(),'color':const Color(0xFFDC2626)},
    {'l':'Mon Medecin\nTraitant','icon':Icons.person_add_rounded,'p':const MonMedecinTraitantPage(),'new':true,'color':const Color(0xFF0891B2)},
    {'l':'Dossier\nFamille','icon':Icons.family_restroom_rounded,'p':const DossierFamillePage(),'new':true,'color':const Color(0xFFDB2777)},
    {'l':'Second Avis\nMedical','icon':Icons.people_alt_rounded,'p':const SecondAvisPage(),'new':true,'color':const Color(0xFFEA580C)},
    {'l':'Rappels\nvaccin','icon':Icons.vaccines_rounded,'p':const RappelsVaccinPage(),'color':const Color(0xFF2563EB)},
    {'l':'Certificat\nmedical','icon':Icons.description_rounded,'p':const CertificatMedicalPage(),'color':const Color(0xFF16A34A)},
    {'l':'Assurance\nsante','icon':Icons.shield_rounded,'p':const AssuranceSantePage(),'color':const Color(0xFF2563EB)},
  ]);

  Widget _sante(BuildContext context) => _grid(context, [
    {'l':'Sante\nenfants','icon':Icons.child_care_rounded,'p':const SanteEnfantsPage(),'color':const Color(0xFFDB2777)},
    {'l':'Carnet\nvaccination','icon':Icons.vaccines_rounded,'p':const CarnetVaccinationPage(),'color':const Color(0xFF2563EB)},
    {'l':'Suivi\ngrossesse','icon':Icons.pregnant_woman_rounded,'p':const SuiviGrossessePage(),'color':const Color(0xFFDB2777)},
    {'l':'Dossier\nmedical','icon':Icons.folder_rounded,'p':const DossierMedicalPage(),'color':const Color(0xFFEA9A00)},
    {'l':'Analyse\npredictive','icon':Icons.show_chart_rounded,'p':const AnalysePredictivePage(),'color':const Color(0xFF7C3AED)},
    {'l':'Bien-etre\nmental','icon':Icons.psychology_rounded,'p':const BienEtreMentalPage(),'color':const Color(0xFF14B8A6)},
    {'l':'Nutrition','icon':Icons.apple_rounded,'p':const NutritionPage(),'color':const Color(0xFF16A34A)},
    {'l':'Activite\nphysique','icon':Icons.fitness_center_rounded,'p':const ActivitePhysiquePage(),'color':const Color(0xFF2563EB)},
    {'l':'Gestion\nstress','icon':Icons.self_improvement_rounded,'p':const GestionStressPage(),'color':const Color(0xFFDB2777)},
    {'l':'Assurance','icon':Icons.umbrella_rounded,'p':const AssuranceSantePage(),'color':const Color(0xFF2563EB)},
    {'l':'Plus de\nservices','icon':Icons.apps_rounded,'p':PlusServicesPage(),'color':const Color(0xFF475569)},
  ]);
}
