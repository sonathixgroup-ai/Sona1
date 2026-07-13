// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_routes.dart';
import '../core/thix_sante_colors.dart';

// ── STATS MODEL ──
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
    final e = await db.from('health_records').select('id').eq('patient_id', uid).limit(1000);
    final m = await db.from('pharmacy_stock').select('id').limit(1); // fallback count via prescriptions
    final p = await db.from('prescriptions').select('id').eq('patient_id', uid).neq('status','delivree');
    final r = await db.from('appointments').select('id').eq('patient_id', uid).gte('date_rdv', DateTime.now().toIso8601String());
    return DashboardStats(
      consultations: (c as List).length,
      examens: (e as List).length,
      medicaments: (p as List).length,
      rdvs: (r as List).length,
    );
  }catch(_){return const DashboardStats(consultations:0,examens:0,medicaments:0,rdvs:0);}
});

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final stats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      body: SafeArea(child: CustomScrollView(slivers:[
        _appBar(context),
        SliverToBoxAdapter(child: _hero(context)),
        SliverToBoxAdapter(child: const SizedBox(height:16)),
        SliverToBoxAdapter(child: _stats(stats)),
        const SliverToBoxAdapter(child: SizedBox(height:20)),
        SliverToBoxAdapter(child: _sectionTitle('⚡ Services rapides', ()=>context.push(AppRoutes.santePlusServices))),
        SliverToBoxAdapter(child: _rapides(context)),
        const SliverToBoxAdapter(child: SizedBox(height:20)),
        SliverToBoxAdapter(child: _sectionTitle('🏥 Services santé', ()=>context.push(AppRoutes.santePlusServices))),
        SliverToBoxAdapter(child: _sante(context)),
        const SliverToBoxAdapter(child: SizedBox(height:20)),
        SliverToBoxAdapter(child: _sectionTitle('📰 Pour vous', (){})),
        SliverToBoxAdapter(child: _pourVous(context)),
        const SliverToBoxAdapter(child: SizedBox(height:16)),
        SliverToBoxAdapter(child: _sos(context)),
        const SliverToBoxAdapter(child: SizedBox(height:100)),
      ])),
    );
  }

  Widget _appBar(BuildContext context)=>SliverAppBar(
    floating:true, pinned:false, backgroundColor: Colors.white, elevation:0, toolbarHeight:64,
    title: Row(children:[
      Container(padding:const EdgeInsets.all(7), decoration:BoxDecoration(color:ThixSanteColors.primary,borderRadius:BorderRadius.circular(10)), child:const Icon(Icons.add_rounded,color:Colors.white,size:18)),
      const SizedBox(width:10),
      const Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Text('THIX SANTE',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15,color:ThixSanteColors.ink,letterSpacing:.3)),Text('Votre santé, notre priorité',style:TextStyle(fontSize:11,color:ThixSanteColors.muted))])
    ]),
    actions:[IconButton(icon:const Icon(Icons.notifications_none_rounded,color:ThixSanteColors.ink),onPressed:()=>context.push(AppRoutes.santeAssistantIA)),Padding(padding:const EdgeInsets.only(right:12), child: GestureDetector(onTap:()=>context.push('/profile'), child:const CircleAvatar(radius:18, backgroundImage:NetworkImage('https://i.pravatar.cc/100?img=12')))))],
  );

  Widget _hero(BuildContext context)=>Container(
    margin:const EdgeInsets.symmetric(horizontal:16),
    padding:const EdgeInsets.fromLTRB(20,20,12,20),
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(24), gradient:const LinearGradient(colors:[Color(0xFF2563EB),Color(0xFF06B6D4)])),
    child:Row(children:[
      Expanded(flex:3, child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        const Text('Bonjour, vous 👋',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w600,fontSize:13)),
        const SizedBox(height:8),
        const Text('Votre santé\nentre de bonnes\nmains',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w900,height:1.1)),
        const SizedBox(height:10),
        const Text('Gérez tout depuis un seul endroit.',style:TextStyle(color:Colors.white70,fontSize:12)),
        const SizedBox(height:16),
        Row(children:[
          ElevatedButton.icon(onPressed:()=>context.push(AppRoutes.santeDossierMedical), style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:ThixSanteColors.primary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),elevation:0,padding:const EdgeInsets.symmetric(horizontal:14,vertical:10)), icon:const Icon(Icons.folder_outlined,size:18), label:const Text('Dossier',style:TextStyle(fontWeight:FontWeight.w800,fontSize:12))),
          const SizedBox(width:10),
          GestureDetector(onTap:()=>context.push(AppRoutes.santeAnalysePredictive), child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9), decoration:BoxDecoration(color:Colors.white.withOpacity(.18),borderRadius:BorderRadius.circular(12),border:Border.all(color:Colors.white30)), child:const Row(children:[Icon(Icons.favorite_rounded,color:Colors.white,size:16),SizedBox(width:6),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Score',style:TextStyle(color:Colors.white70,fontSize:9)),Text('85%',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:15))])]))),
        ])
      ])),
      Expanded(flex:2, child:Image.network('https://cdn3d.iconscout.com/3d/premium/thumb/doctor-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-care-pack-medical-icons-5183886.png',height:140,errorBuilder:(_,__,___)=>const Icon(Icons.medical_services_rounded,color:Colors.white,size:80))),
    ]),
  );

  Widget _stats(AsyncValue<DashboardStats> s)=>s.when(
    data:(d)=>SizedBox(height:84, child:ListView(padding:const EdgeInsets.symmetric(horizontal:16), scrollDirection:Axis.horizontal, children:[
      _stat('📅','${d.consultations}','Consult.','Cette année',const Color(0xFFDBEAFE)),
      _stat('🧪','${d.examens}','Examens','Complétés',const Color(0xFFD1FAE5)),
      _stat('💊','${d.medicaments}','Médicaments','En cours',const Color(0xFFEDE9FE)),
      _stat('⏰','${d.rdvs}','Rendez-vous','À venir',const Color(0xFFFFEDD5)),
    ])),
    loading:()=>const SizedBox(height:84, child:Center(child:CircularProgressIndicator(strokeWidth:2))),
    error:(_,__)=>const SizedBox(height:84),
  );

  Widget _stat(String ico,String val,String l1,String l2,Color c)=>Container(width:118, margin:const EdgeInsets.only(right:10), padding:const EdgeInsets.all(12), decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:ThixSanteColors.borderLight)), child:Row(children:[Container(width:38,height:38,decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(11)),child:Center(child:Text(ico,style:const TextStyle(fontSize:18)))),const SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(val,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18,color:ThixSanteColors.ink)),Text(l1,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600)),Text(l2,style:const TextStyle(fontSize:9,color:ThixSanteColors.muted))])]));

  Widget _sectionTitle(String t,VoidCallback onTap)=>Padding(padding:const EdgeInsets.symmetric(horizontal:16), child:Row(children:[Text(t,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14,color:ThixSanteColors.ink)),const Spacer(),InkWell(onTap:onTap, child:const Text('Voir tout >',style:TextStyle(color:ThixSanteColors.muted,fontSize:11))) ]));

  // ── SERVICES RAPIDES 20/20 CONNECTES ──
  Widget _rapides(BuildContext context){
    final items=[
      {'l':'Consulter\nmédecin','i':'🩺','c':0xFFDBEAFE,'r':AppRoutes.santeConsulterMedecin},
      {'l':'Dossier\nmédical','i':'📁','c':0xFFDBEAFE,'r':AppRoutes.santeDossierMedical},
      {'l':'Résultats\nexamens','i':'🧪','c':0xFFD1FAE5,'r':AppRoutes.santeResultatsExamens},
      {'l':'Mes\nordonnances','i':'📋','c':0xFFEDE9FE,'r':AppRoutes.santeOrdonnances},
      {'l':'Trouver\nhôpital','i':'🏥','c':0xFFCFFAFE,'r':AppRoutes.santeTrouverHopital},
      {'l':'Trouver\nmédicament','i':'💊','c':0xFFE0E7FF,'r':AppRoutes.santeTrouverMedicament},
      {'l':'Pharmacies\nproches','i':'➕','c':0xFFDCFCE7,'r':AppRoutes.santePharmaciesProches},
      {'l':'Urgences\nproches','i':'🚨','c':0xFFFEE2E2,'r':AppRoutes.santeUrgencesProches},
      {'l':'Prendre\nRDV','i':'📅','c':0xFFFFEDD5,'r':AppRoutes.santePrendreRdv},
      {'l':'Téléconsul.','i':'📹','c':0xFFEDE9FE,'r':AppRoutes.santeTeleconsultation},
      {'l':'Assistant\nIA','i':'🤖','c':0xFFDBEAFE,'r':AppRoutes.santeAssistantIA},
      {'l':'Dossier\npartagé','i':'🔗','c':0xFFF3E8FF,'r':AppRoutes.santeDossierPartage},
      {'l':'Épidémies','i':'🦠','c':0xFFFEE2E2,'r':AppRoutes.santeEpidemies},
      {'l':'Don de sang','i':'🩸','c':0xFFFEE2E2,'r':AppRoutes.santeDonSang},
      {'l':'Mon Médecin\nTraitant','i':'👨‍⚕️','c':0xFFD1FAE5,'r':AppRoutes.santeMonMedecinTraitant,'new':true},
      {'l':'Dossier\nFamille','i':'👨‍👩‍👧‍👦','c':0xFFFFEDD5,'r':AppRoutes.santeDossierFamille,'new':true},
      {'l':'Second Avis','i':'🩻','c':0xFFE0E7FF,'r':AppRoutes.santeSecondAvis,'new':true},
      {'l':'Rappels\nvaccin','i':'💉','c':0xFFDBEAFE,'r':AppRoutes.santeRappelsVaccin},
      {'l':'Certificat\nmédical','i':'📄','c':0xFFD1FAE5,'r':AppRoutes.santeCertificatMedical},
      {'l':'Assurance\nsanté','i':'🛡️','c':0xFFDBEAFE,'r':AppRoutes.santeAssurance},
    ];
    return Padding(padding:const EdgeInsets.fromLTRB(12,10,12,0), child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(), gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.88), itemCount:items.length, itemBuilder:(c,i){final it=items[i];return InkWell(onTap:()=>context.push(it['r'] as String), borderRadius:BorderRadius.circular(16), child:Stack(children:[Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:ThixSanteColors.borderLight),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.03),blurRadius:8,offset:const Offset(0,2))]), child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:44,height:44,decoration:BoxDecoration(color:Color(it['c'] as int),borderRadius:BorderRadius.circular(12)),child:Center(child:Text(it['i'] as String,style:const TextStyle(fontSize:20)))),const SizedBox(height:8),Text(it['l'] as String,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w700,height:1.15,color:ThixSanteColors.ink))])), if(it['new']==true)Positioned(top:6,right:6,child:Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:2),decoration:BoxDecoration(color:ThixSanteColors.success,borderRadius:BorderRadius.circular(6)),child:const Text('NEW',style:TextStyle(color:Colors.white,fontSize:7,fontWeight:FontWeight.w900))))]));}));
  }

  Widget _sante(BuildContext context){
    final sante=[
      {'l':'Santé\nenfants','i':'👶','r':AppRoutes.santeEnfants},
      {'l':'Carnet\nvaccination','i':'💉','r':AppRoutes.santeCarnetVaccination},
      {'l':'Suivi\ngrossesse','i':'🤰','r':AppRoutes.santeSuiviGrossesse},
      {'l':'Analyse\nprédictive','i':'📈','r':AppRoutes.santeAnalysePredictive},
      {'l':'Bien-être\nmental','i':'🧠','r':AppRoutes.santeBienEtreMental},
      {'l':'Nutrition','i':'🍏','r':AppRoutes.santeNutrition},
      {'l':'Activité\nphysique','i':'🏋️','r':AppRoutes.santeActivitePhysique},
      {'l':'Gestion\nstress','i':'🧘','r':AppRoutes.santeGestionStress},
      {'l':'Assurance','i':'☂️','r':AppRoutes.santeAssuranceSanteDetail},
      {'l':'Plus','i':'➕','r':AppRoutes.santePlusServices},
    ];
    return Padding(padding:const EdgeInsets.fromLTRB(12,10,12,0), child:GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(), gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:5,crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:.9), itemCount:sante.length, itemBuilder:(c,i){final it=sante[i];return InkWell(onTap:()=>context.push(it['r']!), borderRadius:BorderRadius.circular(16), child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:ThixSanteColors.borderLight)), child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Text(it['i']!,style:const TextStyle(fontSize:24)),const SizedBox(height:6),Text(it['l']!,textAlign:TextAlign.center,style:const TextStyle(fontSize:10,fontWeight:FontWeight.w600))])));}));
  }

  Widget _pourVous(BuildContext context)=>SizedBox(height:152, child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:16), scrollDirection:Axis.horizontal, itemCount:4, separatorBuilder:(_,__)=>const SizedBox(width:12), itemBuilder:(c,i)=>GestureDetector(onTap:()=>context.push(AppRoutes.santeAssistantIA), child:Container(width:172, decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:ThixSanteColors.borderLight),boxShadow:[BoxShadow(color:Colors.black.withOpacity(.04),blurRadius:10)]), child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[Stack(children:[ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(16)), child:Image.network('https://picsum.photos/300/150?random=$i',height:86,width:172,fit:BoxFit.cover)),Positioned(top:8,left:8,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:ThixSanteColors.primary,borderRadius:BorderRadius.circular(20)),child:Text('${3+i} min',style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700))))]),const Padding(padding:EdgeInsets.all(10), child:Text('5 conseils pour rester en bonne santé',style:TextStyle(fontSize:11,fontWeight:FontWeight.w700,height:1.25)))])))));

  Widget _sos(BuildContext context)=>Container(margin:const EdgeInsets.all(16), padding:const EdgeInsets.all(14), decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFFEF4444),Color(0xFFDC2626)]),borderRadius:BorderRadius.circular(16),boxShadow:[BoxShadow(color:const Color(0xFFEF4444).withOpacity(.3),blurRadius:12,offset:const Offset(0,6))]), child:Row(children:[Container(width:44,height:44,decoration:const BoxDecoration(color:Colors.white,shape:BoxShape.circle),child:const Center(child:Text('SOS',style:TextStyle(fontWeight:FontWeight.w900,color:Color(0xFFDC2626))))),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Urgence? Nous sommes là',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:13)),Text('Trouvez l’hôpital le plus proche',style:TextStyle(color:Colors.white70,fontSize:11))])),ElevatedButton(onPressed:()=>context.push(AppRoutes.santeUrgencesProches), style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:const Color(0xFFDC2626),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20)),elevation:0), child:const Text('Appeler',style:TextStyle(fontWeight:FontWeight.w800)))]));
}
