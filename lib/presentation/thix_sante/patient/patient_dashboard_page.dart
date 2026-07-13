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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(child: CustomScrollView(slivers:[
        SliverAppBar(floating:true, backgroundColor:Colors.white, elevation:0, toolbarHeight:64,
          leading: IconButton(icon:const Icon(Icons.menu_rounded,color:Color(0xFF0F172A)),onPressed:(){}),
          title: Row(children:[Container(padding:const EdgeInsets.all(7), decoration:BoxDecoration(color:ThixSanteColors.primary,borderRadius:BorderRadius.circular(10)), child:const Icon(Icons.add_rounded,color:Colors.white,size:18)),const SizedBox(width:8),const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('THIX SANTE',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15,color:Color(0xFF0F172A))),Text('Votre sante, notre priorite',style:TextStyle(fontSize:11,color:Color(0xFF64748B)))])]),
          actions:[Stack(children:[IconButton(icon:const Icon(Icons.notifications_none_rounded),onPressed:()=>_go(context,const AssistantIAPage())),Positioned(top:10,right:10,child:Container(width:18,height:18,decoration:const BoxDecoration(color:Colors.red,shape:BoxShape.circle),child:const Center(child:Text('3',style:TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)))))]),const Padding(padding:EdgeInsets.only(right:12),child:CircleAvatar(radius:18,backgroundImage:NetworkImage('https://i.pravatar.cc/100?img=12')))],
        ),
        SliverToBoxAdapter(child: _hero(context)),
        const SliverToBoxAdapter(child:SizedBox(height:16)),
        SliverToBoxAdapter(child: _stats(stats)),
        SliverToBoxAdapter(child: _section('Services rapides', (){})),
        SliverToBoxAdapter(child: _rapides(context)),
        SliverToBoxAdapter(child: _section('Services sante', (){})),
        SliverToBoxAdapter(child: _sante(context)),
        const SliverToBoxAdapter(child:SizedBox(height:100)),
      ])),
    );
  }

  Widget _hero(BuildContext context)=>Container(margin:const EdgeInsets.symmetric(horizontal:16),padding:const EdgeInsets.fromLTRB(20,20,12,20),decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),gradient:const LinearGradient(colors:[Color(0xFF2563EB),Color(0xFF06B6D4)])),child:Row(children:[Expanded(flex:3,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Bonjour, vous',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),const SizedBox(height:8),const Text('Votre sante\nentre de bonnes\nmains',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w900,height:1.1)),const SizedBox(height:10),const Text('Gerez tout depuis un seul endroit.',style:TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(height:16),Row(children:[ElevatedButton(onPressed:()=>_go(context,const DossierMedicalPage()),style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:ThixSanteColors.primary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),elevation:0),child:const Text('Dossier',style:TextStyle(fontWeight:FontWeight.w800,fontSize:12))),const SizedBox(width:10),Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),decoration:BoxDecoration(color:Colors.white.withOpacity(.18),borderRadius:BorderRadius.circular(12)),child:const Text('Score 85%',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)))])])),Expanded(flex:2,child:Image.network('https://cdn3d.iconscout.com/3d/premium/thumb/doctor-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-care-pack-medical-icons-5183886.png',height:130,errorBuilder:(_,__,___)=>const Icon(Icons.medical_services_rounded,color:Colors.white,size:70)))]));
  Widget _stats(AsyncValue<DashboardStats> s)=>s.when(data:(d)=>SizedBox(height:84,child:ListView(padding:const EdgeInsets.symmetric(horizontal:16),scrollDirection:Axis.horizontal,children:[_stat('${d.consultations}','Consult.','Cette annee'),_stat('${d.examens}','Examens','Completes'),_stat('${d.medicaments}','Medicaments','En cours'),_stat('${d.rdvs}','Rendez-vous','A venir'),])),loading:()=>const SizedBox(height:84,child:Center(child:CircularProgressIndicator(strokeWidth:2))),error:(_,__)=>const SizedBox(height:84));
  Widget _stat(String v,String l1,String l2)=>Container(width:118,margin:const EdgeInsets.only(right:10),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE2E8F0))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(v,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)),Text(l1,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600)),Text(l2,style:const TextStyle(fontSize:9,color:Color(0xFF64748B)))]));
  Widget _section(String t,VoidCallback a)=>Padding(padding:const EdgeInsets.fromLTRB(16,20,16,10),child:Row(children:[Text(t,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),const Spacer(),InkWell(onTap:a,child:const Text('Voir tout >',style:TextStyle(color:Color(0xFF64748B),fontSize:11)))]));
  Widget _rapides(BuildContext context){
    final items = <Map<String, dynamic>>[
  {'l':'Consulter\nmedecin','icon':Icons.medical_services_rounded,'p':const ConsulterMedecinPage()},
  {'l':'Dossier\nmedical','icon':Icons.folder_rounded,'p':const DossierMedicalPage()},
  {'l':'Resultats\nexamens','icon':Icons.biotech_rounded,'p':const ResultatsExamensPage()},
  {'l':'Mes\nordonnances','icon':Icons.receipt_long_rounded,'p':const MesOrdonnancesPage()},
  {'l':'Trouver\nhopital','icon':Icons.local_hospital_rounded,'p':const TrouverHopitalPage()},
  {'l':'Trouver\nmedicament','icon':Icons.medication_rounded,'p':const TrouverMedicamentPage()},
  {'l':'Pharmacies\nproches','icon':Icons.add_business_rounded,'p':const PharmaciesProchesPage()},
  {'l':'Urgences\nproches','icon':Icons.emergency_rounded,'p':const UrgencesProchesPage()},
  {'l':'Prendre\nRDV','icon':Icons.event_rounded,'p':const PrendreRdvPage()},
  {'l':'Teleconsult\nation','icon':Icons.videocam_rounded,'p':const TeleconsultationPage()},
  {'l':'Assistant\nIA','icon':Icons.smart_toy_rounded,'p':const AssistantIAPage()},
  {'l':'Dossier\npartage','icon':Icons.link_rounded,'p':const DossierPartagePage()},
  {'l':'Epidemies','icon':Icons.coronavirus_rounded,'p':const EpidemiesPage()},
  {'l':'Don de sang','icon':Icons.water_drop_rounded,'p':const DonSangPage()},
  {'l':'Mon Medecin\nTraitant','icon':Icons.medical_services_rounded,'p':const MonMedecinTraitantPage(),'new':true},
  {'l':'Dossier\nFamille','icon':Icons.family_restroom_rounded,'p':const DossierFamillePage(),'new':true},
  {'l':'Second Avis\nMedical','icon':Icons.medical_information_rounded,'p':const SecondAvisPage(),'new':true},
  {'l':'Rappels\nvaccin','icon':Icons.vaccines_rounded,'p':const RappelsVaccinPage()},
  {'l':'Certificat\nmedical','icon':Icons.description_rounded,'p':const CertificatMedicalPage()},
  {'l':'Assurance\nsante','icon':Icons.shield_rounded,'p':const AssuranceSantePage()},
];
    return Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.82),itemCount:items.length,itemBuilder:(c,i){final it=items[i];return InkWell(onTap:()=>_go(context,it['p'] as Widget),borderRadius:BorderRadius.circular(16),child:Stack(children:[Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE2E8F0))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:44,height:44,decoration:BoxDecoration(color:const Color(0xFFEFF6FF),borderRadius:BorderRadius.circular(12)),child:Icon(it['icon'] as IconData,color:ThixSanteColors.primary,size:22)),const SizedBox(height:8),Text(it['l'] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:10.5,fontWeight:FontWeight.w700,height:1.15))])),if(it['new']==true)Positioned(top:6,right:6,child:Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration:BoxDecoration(color:const Color(0xFF16A34A),borderRadius:BorderRadius.circular(6)),child:const Text('NEW',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w900))))]));}));
  }
  Widget _sante(BuildContext context){
  final sante = <Map<String,dynamic>>[
    {'l':'Sante\nenfants','icon':Icons.child_care_rounded,'p':const SanteEnfantsPage()},
    {'l':'Carnet\nvaccination','icon':Icons.vaccines_rounded,'p':const CarnetVaccinationPage()},
    {'l':'Suivi\ngrossesse','icon':Icons.pregnant_woman_rounded,'p':const SuiviGrossessePage()},
    {'l':'Dossier\nmedical','icon':Icons.folder_rounded,'p':const DossierMedicalPage()},
    {'l':'Analyse\npredictive','icon':Icons.show_chart_rounded,'p':const AnalysePredictivePage()},
    {'l':'Bien-etre\nmental','icon':Icons.psychology_rounded,'p':const BienEtreMentalPage()},
    {'l':'Nutrition','icon':Icons.apple_rounded,'p':const NutritionPage()},
    {'l':'Activite\nphysique','icon':Icons.fitness_center_rounded,'p':const ActivitePhysiquePage()},
    {'l':'Gestion\nstress','icon':Icons.self_improvement_rounded,'p':const GestionStressPage()},
    {'l':'Assurance','icon':Icons.shield_rounded,'p':const AssuranceSantePage()},
    {'l':'Plus de\nservices','icon':Icons.grid_view_rounded,'p': PlusServicesPage()},
  ];
    return Padding(padding:const EdgeInsets.symmetric(horizontal:12),child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.85),itemCount:sante.length,itemBuilder:(c,i){final it=sante[i];return InkWell(onTap:()=>_go(context,it['p'] as Widget),borderRadius:BorderRadius.circular(16),child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFE2E8F0))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(it['icon'] as IconData,color:ThixSanteColors.primary,size:26),const SizedBox(height:6),Text(it['l'] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600))])));}));
  }
}
