import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/grossesse_provider.dart';
import '../services/grossesse_advice_service.dart';
import '../models/grossesse_model.dart';

// Inlined pour éviter l'erreur import
class CountdownWidget extends StatefulWidget {
  final DateTime dpa; const CountdownWidget({super.key, required this.dpa});
  @override State<CountdownWidget> createState()=> _CountdownWidgetState();
}
class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer; Duration _remaining=Duration.zero;
  @override void initState(){ super.initState(); _remaining=widget.dpa.difference(DateTime.now()); _timer=Timer.periodic(const Duration(seconds:1), (_){ if(mounted) setState(()=> _remaining=widget.dpa.difference(DateTime.now())); }); }
  @override void dispose(){ _timer.cancel(); super.dispose(); }
  @override Widget build(BuildContext context){
    if(_remaining.isNegative) return const Text('Bébé est là!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900));
    final months=_remaining.inDays~/30; final weeks=(_remaining.inDays%30)~/7; final days=(_remaining.inDays%30)%7;
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Text('$months mois $weeks semaines $days jours ${ _remaining.inHours%24}h ${ _remaining.inMinutes%60}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:13)));
  }
}

class SuiviGrossessePage extends ConsumerStatefulWidget {
  final String? patientId; const SuiviGrossessePage({super.key, this.patientId});
  @override ConsumerState<SuiviGrossessePage> createState()=> _SuiviGrossessePageState();
}

class _SuiviGrossessePageState extends ConsumerState<SuiviGrossessePage> with SingleTickerProviderStateMixin {
  late TabController _tab; Timer? _cTimer; int _cSec=0; DateTime? _lastC;
  String? get pid=> widget.patientId; bool get isDoctor=> pid!=null;

  @override void initState(){ _tab=TabController(length:6, vsync:this); super.initState(); }
  @override void dispose(){ _tab.dispose(); _cTimer?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context){
    final profileAsync = ref.watch(grossesseProfileProvider(pid));
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(backgroundColor: Colors.white, elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> Navigator.pop(context)), title: Text(isDoctor? 'Suivi Patiente':'Mon Suivi', style: const TextStyle(fontWeight: FontWeight.w800)), actions: [
        IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: ()=> _exportPdf()),
        PopupMenuButton<String>(itemBuilder: (context)=> [const PopupMenuItem(value:'share', child: Text('Partager')), const PopupMenuItem(value:'lang', child: Text('FR/EN/AR'))]),
      ]),
      body: profileAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,_ )=> Center(child: Text('Erreur $e')),
        data: (profile){
          if(profile==null) return _createProfile();
          final advice = GrossesseAdviceService.getWeekAdvice(profile.sa);
          final info = GrossesseAdviceService.getBabyInfo(profile.sa);
          return Column(children: [
            _riskAlerts(profile),
            _dashboard(profile, info),
            TabBar(controller:_tab, isScrollable:true, labelColor: ThixSanteColors.primary, tabs: const [Tab(text:'Bébé'), Tab(text:'Maman'), Tab(text:'RDV & Docs'), Tab(text:'Journal'), Tab(text:'Prépa'), Tab(text:'Urgences')]),
            Expanded(child: TabBarView(controller:_tab, children: [_tabBebe(profile, advice, info), _tabMaman(), _tabDocs(), _tabJournal(), _tabPrepa(profile), _tabUrgences(profile)])),
          ]);
        },
      ),
    );
  }

  Widget _riskAlerts(PregnancyProfile profile){
    final vitals = ref.watch(vitalsProvider(pid)).value?? [];
    final kicks = ref.watch(kicksProvider(pid)).value?? [];
    final contractions = ref.watch(contractionsProvider(pid)).value?? [];
    final risks = ref.read(grossesseServiceProvider).calculateRisks(sa: profile.sa, vitals: vitals, kicks: kicks, contractions: contractions);
    if(risks.isEmpty) {
      return Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size:18), SizedBox(width:6), Text("Tout va bien - N oubliez pas vitamines", style: TextStyle(fontSize:11, fontWeight: FontWeight.w600))]));
    }
    return Column(children: risks.map((r)=> Container(width: double.infinity, margin: const EdgeInsets.symmetric(horizontal:8, vertical:2), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))), child: Text(r, style: const TextStyle(fontSize:11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))))).toList());
  }

  Widget _dashboard(PregnancyProfile p, BabyWeekInfo info){
    final isLabor = p.sa>=37;
    return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: isLabor? [Colors.red, const Color(0xFFB91C1C)] : [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.trimester(), style: const TextStyle(color: Colors.white70, fontSize:11, fontWeight: FontWeight.bold)), Text('${p.sa} SA + ${p.daysRemain}j', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
      const SizedBox(height:8),
      Row(children: [Container(width:60, height:60, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/baby/week_${p.sa}.png', errorBuilder: (c,e,s)=> Center(child: Text(info.fruit, style: const TextStyle(fontSize:28)))))), const SizedBox(width:10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bébé taille ${info.fruit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize:13)), Text('${info.size} • ${info.weight}', style: const TextStyle(color: Colors.white, fontSize:11))]))]),
      const SizedBox(height:10), CountdownWidget(dpa: p.dpa),
      const SizedBox(height:8), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p.progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight:6)),
    ]));
  }

  Widget _tabBebe(PregnancyProfile p, WeekAdvice advice, BabyWeekInfo info){
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(advice.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:16)), const SizedBox(height:8),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
       ...advice.babyDevelopment.map((e)=> Padding(padding: const EdgeInsets.only(bottom:4), child: Text('• $e', style: const TextStyle(fontSize:12)))),
        const Divider(),
        Row(children: [Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('✔ À privilégier', style: TextStyle(fontWeight: FontWeight.bold, fontSize:11, color: Color(0xFF166534))),...advice.nutrition.map((e)=> Text(e, style: const TextStyle(fontSize:11)))]))), const SizedBox(width:8), Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('❌ À éviter', style: TextStyle(fontWeight: FontWeight.bold, fontSize:11, color: Color(0xFF991B1B))),...advice.avoid.map((e)=> Text(e, style: const TextStyle(fontSize:11)))])))]),
      ])),
      const SizedBox(height:12), _kickCounter(),
    ]);
  }

  Widget _kickCounter(){
    final kicksAsync = ref.watch(kicksProvider(pid));
    return kicksAsync.when(data: (List<PregnancyKick> list){
      final today = list.where((k)=> k.createdAt.day==DateTime.now().day).length;
      return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Coups aujourd hui', style: TextStyle(fontWeight: FontWeight.bold)), Text('$today / 10', style: const TextStyle(fontWeight: FontWeight.w900, color: ThixSanteColors.primary))]),
        const SizedBox(height:8), LinearProgressIndicator(value: (today/10).clamp(0,1).toDouble(), minHeight:8, borderRadius: BorderRadius.circular(8)),
        if(!isDoctor) Padding(padding: const EdgeInsets.only(top:8), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { await ref.read(grossesseServiceProvider).addKick(pid); ref.invalidate(kicksProvider(pid)); }, icon: const Icon(Icons.touch_app), label: const Text('Enregistrer un coup')))),
      ]));
    }, loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur'));
  }

  Widget _tabMaman(){
    final vitals = ref.watch(vitalsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('📈 Courbes réelles', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height:8),
      Container(height:160, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: vitals.when(data: (List<PregnancyVital> list){
        final poids = list.where((v)=> v.type=='poids').toList().reversed.take(7).toList().reversed.toList();
        if(poids.isEmpty) return const Center(child: Text('Pas encore de donnees', style: TextStyle(fontSize:11, color: Colors.grey)));
        final spots = <FlSpot>[]; for(int i=0;i<poids.length;i++){ spots.add(FlSpot(i.toDouble(), double.tryParse(poids[i].value)??0)); }
        return LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, isCurved:true, color: ThixSanteColors.primary, barWidth:3, dotData: const FlDotData(show:true))], titlesData: const FlTitlesData(show:true)));
      }, loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur'))),
      const SizedBox(height:12),
      Wrap(spacing:6, children: [_vitalChip('Poids','poids'), _vitalChip('TA','tension'), _vitalChip('Glycémie','glycemie')]),
      const SizedBox(height:12),
      vitals.when(data: (List<PregnancyVital> list)=> Column(children: list.take(10).map((v)=> ListTile(dense:true, title: Text('${v.type}: ${v.value}'), subtitle: Text(v.createdAt.toString().substring(0,16)))).toList()), loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')),
    ]);
  }

  Widget _tabDocs(){
    final records = ref.watch(grossesseRecordsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      if(isDoctor) ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Ajouter consultation'), onPressed: ()=> _addConsultation()),
      OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text('Ajouter PDF echo/analyse'), onPressed: ()=> _pickDoc()),
      const SizedBox(height:12),
      records.when(data: (list)=> Column(children: list.map((r)=> Card(child: ListTile(title: Text(r.title, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700)), subtitle: Text(r.description??'', style: const TextStyle(fontSize:10))))).toList()),
