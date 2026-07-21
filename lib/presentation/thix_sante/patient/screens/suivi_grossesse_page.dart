import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/thix_sante_colors.dart';
import '../providers/grossesse_provider.dart';
import '../services/grossesse_advice_service.dart';
import '../models/grossesse_model.dart';

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
    final m=_remaining.inDays~/30; final w=(_remaining.inDays%30)~/7; final d=(_remaining.inDays%30)%7;
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)), child: Text('$m mois $w sem $d j - ${ _remaining.inHours%24}h ${ _remaining.inMinutes%60}m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:13)));
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
      appBar: AppBar(backgroundColor: Colors.white, elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: ()=> Navigator.pop(context)), title: Text(isDoctor? 'Suivi Patiente':'Mon Suivi', style: const TextStyle(fontWeight: FontWeight.w800)), actions: [IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _exportPdf)]),
      body: profileAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,_ )=> Center(child: Text('Erreur $e')),
        data: (profile){
          if(profile==null) return _createProfileWizard(); // <-- PORTE 1 : INSERTION DETAILS
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

  // ============== PORTE 1 : WIZARD ULTRA COMPLET ==============
  Widget _createProfileWizard(){
    int step=0;
    final ddrCtrl=TextEditingController(), concepCtrl=TextEditingController(), echoCtrl=TextEditingController();
    final ageCtrl=TextEditingController(text:'25'), poidsCtrl=TextEditingController(text:'60'), tailleCtrl=TextEditingController(text:'165'), parityCtrl=TextEditingController(text:'0'), gestiteCtrl=TextEditingController(text:'1');
    PregnancyType type=PregnancyType.singleton; BloodGroup bg=BloodGroup.O; Rhesus rh=Rhesus.pos;
    bool tabac=false, alcool=false, diabete=false, hta=false; final antecedents=<String>{};

    return StatefulBuilder(builder: (context, setLocal){
      DateTime? parse(String s)=> s.isEmpty? null : DateTime.tryParse(s);
      DateTime calcDPA(){
        if(echoCtrl.text.isNotEmpty) return DateTime.parse(echoCtrl.text).add(const Duration(days:266));
        if(concepCtrl.text.isNotEmpty) return DateTime.parse(concepCtrl.text).add(const Duration(days:266));
        if(ddrCtrl.text.isEmpty) return DateTime.now().add(const Duration(days:280));
        final ddr=DateTime.parse(ddrCtrl.text);
        return ddr.add(Duration(days: type==PregnancyType.jumeaux?259: type==PregnancyType.triple?245:280));
      }
      double calcBMI(){ try{ final p=double.parse(poidsCtrl.text); final t=double.parse(tailleCtrl.text)/100; return p/(t*t);}catch(_){ return 0; } }

      return SafeArea(child: Stepper(
        currentStep: step, onStepContinue: () async {
          if(step==0 && ddrCtrl.text.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DDR obligatoire - base du systeme'))); return; }
          if(step<3){ setLocal(()=> step++); }
          else {
            final dpa=calcDPA();
            await ref.read(grossesseServiceProvider).createFullProfile(
              pid: pid, ddr: DateTime.parse(ddrCtrl.text), conception: parse(concepCtrl.text), echo: parse(echoCtrl.text),
              type: type, age: int.parse(ageCtrl.text), parity: int.parse(parityCtrl.text), gravida: int.parse(gestiteCtrl.text),
              poids: double.parse(poidsCtrl.text), taille: double.parse(tailleCtrl.text),
              bloodGroup: bg, rhesus: rh, antecedents: antecedents.toList(), tabac: tabac, alcool: alcool, diabete: diabete, hta: hta,
            );
            ref.invalidate(grossesseProfileProvider(pid));
          }
        },
        onStepCancel: ()=> setLocal(()=> step= step>0? step-1:0),
        steps: [
          Step(title: const Text('DATATION - Base systeme', style: TextStyle(fontWeight: FontWeight.w900)), content: Column(children: [
            const Text('Le DPA calcule ici va driver SA, trimestre, alertes, courbes.', style: TextStyle(fontSize:10, color: Colors.grey)),
            const SizedBox(height:12),
            TextFormField(controller: ddrCtrl, readOnly:true, decoration: const InputDecoration(labelText: 'DDR* Date dernieres regles', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), onTap: () async { final d=await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days:320)), lastDate: DateTime.now(), initialDate: DateTime.now().subtract(const Duration(days:60))); if(d!=null) setLocal(()=> ddrCtrl.text=d.toIso8601String().substring(0,10)); }),
            const SizedBox(height:8),
            TextFormField(controller: concepCtrl, readOnly:true, decoration: const InputDecoration(labelText: 'Date conception (si connue)', border: OutlineInputBorder()), onTap: () async { final d=await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days:300)), lastDate: DateTime.now(), initialDate: DateTime.now().subtract(const Duration(days:50))); if(d!=null) setLocal(()=> concepCtrl.text=d.toIso8601String().substring(0,10)); }),
            const SizedBox(height:8),
            TextFormField(controller: echoCtrl, readOnly:true, decoration: const InputDecoration(labelText: 'Echo datation T1 (plus precise)', border: OutlineInputBorder()), onTap: () async { final d=await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days:200)), lastDate: DateTime.now(), initialDate: DateTime.now().subtract(const Duration(days:40))); if(d!=null) setLocal(()=> echoCtrl.text=d.toIso8601String().substring(0,10)); }),
            const SizedBox(height:8),
            DropdownButtonFormField<PregnancyType>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Type'), items: PregnancyType.values.map((e)=> DropdownMenuItem(value:e, child: Text(e.name))).toList(), onChanged: (v)=> setLocal(()=> type=v!)),
            if(ddrCtrl.text.isNotEmpty) Container(margin: const EdgeInsets.only(top:8), width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)), child: Text('DPA: ${calcDPA().day}/${calcDPA().month}/${calcDPA().year} • J-${calcDPA().difference(DateTime.now()).inDays} • IMC: ${calcBMI().toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12))),
          ])),
          Step(title: const Text('PROFIL MEDICAL'), content: Column(children: [
            Row(children: [Expanded(child: TextFormField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age*', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextFormField(controller: tailleCtrl, decoration: const InputDecoration(labelText: 'Taille cm*', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextFormField(controller: poidsCtrl, decoration: const InputDecoration(labelText: 'Poids avant*', border: OutlineInputBorder())))]),
            const SizedBox(height:8),
            Row(children: [Expanded(child: DropdownButtonFormField<BloodGroup>(value: bg, decoration: const InputDecoration(labelText: 'Groupe', border: OutlineInputBorder()), items: BloodGroup.values.map((e)=> DropdownMenuItem(value:e, child: Text(e.name))).toList(), onChanged: (v)=> setLocal(()=> bg=v!))), const SizedBox(width:8), Expanded(child: DropdownButtonFormField<Rhesus>(value: rh, decoration: const InputDecoration(labelText: 'Rhésus', border: OutlineInputBorder()), items: Rhesus.values.map((e)=> DropdownMenuItem(value:e, child: Text(e.name))).toList(), onChanged: (v)=> setLocal(()=> rh=v!)))]),
            const SizedBox(height:8),
            Row(children: [Expanded(child: TextFormField(controller: gestiteCtrl, decoration: const InputDecoration(labelText: 'Gestité', border: OutlineInputBorder()))), const SizedBox(width:8), Expanded(child: TextFormField(controller: parityCtrl, decoration: const InputDecoration(labelText: 'Parité', border: OutlineInputBorder())))]),
          ])),
          Step(title: const Text('RISQUES'), content: Column(children: [
            Wrap(spacing:6, children: ['Pré-éclampsie','Diabète gestationnel','Césarienne','Fausse couche','Prématurité','HTA'].map((e)=> FilterChip(label: Text(e, style: const TextStyle(fontSize:10)), selected: antecedents.contains(e), onSelected: (v)=> setLocal(()=> v? antecedents.add(e) : antecedents.remove(e)))).toList()),
            CheckboxListTile(value: tabac, dense:true, title: const Text('Tabac', style: TextStyle(fontSize:12)), onChanged: (v)=> setLocal(()=> tabac=v!)),
            CheckboxListTile(value: alcool, dense:true, title: const Text('Alcool', style: TextStyle(fontSize:12)), onChanged: (v)=> setLocal(()=> alcool=v!)),
            CheckboxListTile(value: diabete, dense:true, title: const Text('Diabète', style: TextStyle(fontSize:12)), onChanged: (v)=> setLocal(()=> diabete=v!)),
            CheckboxListTile(value: hta, dense:true, title: const Text('HTA', style: TextStyle(fontSize:12)), onChanged: (v)=> setLocal(()=> hta=v!)),
          ])),
          Step(title: const Text('CONFIRMATION'), content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DPA: ${calcDPA().toString().substring(0,10)} • SA à ce jour: ${(DateTime.now().difference(DateTime.parse(ddrCtrl.text)).inDays/7).floor())} SA', style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)),
            Text('IMC: ${calcBMI().toStringAsFixed(1)} • Groupe: ${bg.name} ${rh.name} • ${type.name}', style: const TextStyle(fontSize:12)),
            const SizedBox(height:8), const Text('Apres validation, le system va: créer courbes, lancer suivi coups à 28SA, timer contractions à 37SA, checklist valise.', style: TextStyle(fontSize:10, color: Colors.grey)),
          ])),
        ],
      ));
    });
  }

  // ============== DASHBOARD + TABS REELS ==============
  Widget _riskAlerts(PregnancyProfile profile){
    final vitals = ref.watch(vitalsProvider(pid)).value?? [];
    final kicks = ref.watch(kicksProvider(pid)).value?? [];
    final contractions = ref.watch(contractionsProvider(pid)).value?? [];
    final risks = ref.read(grossesseServiceProvider).calculateRisks(sa: profile.sa, vitals: vitals, kicks: kicks, contractions: contractions);
    if(risks.isEmpty) return Container(margin: const EdgeInsets.all(8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size:18), SizedBox(width:6), Text("Tout va bien", style: TextStyle(fontSize:11, fontWeight: FontWeight.w600))]));
    return Column(children: risks.map((r)=> Container(width: double.infinity, margin: const EdgeInsets.symmetric(horizontal:8, vertical:2), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Color(0xFFFCA5A5))), child: Text(r, style: const TextStyle(fontSize:11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))))).toList());
  }
  Widget _dashboard(PregnancyProfile p, BabyWeekInfo info){
    final isLabor = p.sa>=37;
    return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: LinearGradient(colors: isLabor? [Colors.red, Color(0xFFB91C1C)] : [Color(0xFFEC4899), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.trimester(), style: const TextStyle(color: Colors.white70, fontSize:11, fontWeight: FontWeight.bold)), Text('${p.sa} SA + ${p.daysRemain}j', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
      const SizedBox(height:8), Row(children: [Container(width:60, height:60, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: Center(child: Text(info.fruit, style: const TextStyle(fontSize:28)))), const SizedBox(width:10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bébé ${info.fruit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text('${info.size} • ${info.weight}', style: const TextStyle(color: Colors.white, fontSize:11))]))]),
      const SizedBox(height:10), CountdownWidget(dpa: p.dpa), const SizedBox(height:8), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p.progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight:6)),
    ]));
  }
  Widget _tabBebe(PregnancyProfile p, WeekAdvice advice, BabyWeekInfo info)=> ListView(padding: const EdgeInsets.all(16), children: [Text(advice.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize:16)), const SizedBox(height:8), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...advice.babyDevelopment.map((e)=> Text('• $e', style: const TextStyle(fontSize:12))), const Divider(), Text('Taille: ${info.size} • Poids: ${info.weight}', style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold))])), const SizedBox(height:12), _kickCounter()]);
  Widget _kickCounter(){ final kicksAsync = ref.watch(kicksProvider(pid)); return kicksAsync.when(data: (List<PregnancyKick> list){ final today = list.where((k)=> k.createdAt.day==DateTime.now().day).length; return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Coups aujourd hui', style: TextStyle(fontWeight: FontWeight.bold)), Text('$today / 10', style: const TextStyle(fontWeight: FontWeight.w900, color: ThixSanteColors.primary))]), const SizedBox(height:8), LinearProgressIndicator(value: (today/10).clamp(0,1).toDouble(), minHeight:8, borderRadius: BorderRadius.circular(8)), if(!isDoctor) Padding(padding: const EdgeInsets.only(top:8), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { await ref.read(grossesseServiceProvider).addKick(pid); ref.invalidate(kicksProvider(pid)); }, icon: const Icon(Icons.touch_app), label: const Text('Enregistrer un coup')))) ])); }, loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')); }
  Widget _tabMaman(){ final vitals = ref.watch(vitalsProvider(pid)); return ListView(padding: const EdgeInsets.all(16), children: [const Text('📈 Courbes réelles', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height:8), Container(height:160, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: vitals.when(data: (List<PregnancyVital> list){ final poids = list.where((v)=> v.type=='poids').toList().reversed.take(7).toList().reversed.toList(); if(poids.isEmpty) return const Center(child: Text('Pas de donnees', style: TextStyle(fontSize:11))); final spots = <FlSpot>[]; for(int i=0;i<poids.length;i++){ spots.add(FlSpot(i.toDouble(), double.tryParse(poids[i].value)??0)); } return LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, isCurved:true, color: ThixSanteColors.primary, barWidth:3, dotData: const FlDotData(show:true))], titlesData: const FlTitlesData(show:true))); }, loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur'))), const SizedBox(height:12), Wrap(spacing:6, children: [_vitalChip('Poids','poids'), _vitalChip('TA','tension'), _vitalChip('Glycémie','glycemie')]), const SizedBox(height:12), vitals.when(data: (List<PregnancyVital> list)=> Column(children: list.take(10).map((v)=> ListTile(dense:true, title: Text('${v.type}: ${v.value}'), subtitle: Text(v.createdAt.toString().substring(0,16)))).toList()), loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur'))]); }
  Widget _tabDocs(){ final records = ref.watch(grossesseRecordsProvider(pid)); return ListView(padding: const EdgeInsets.all(16), children: [if(isDoctor) ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Ajouter consultation'), onPressed: _addConsultation), OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text('Ajouter PDF'), onPressed: _pickDoc), const SizedBox(height:12), records.when(data: (list)=> Column(children: list.map((r)=> Card(child: ListTile(title: Text(r.title, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700)), subtitle: Text(r.description??'', style: const TextStyle(fontSize:10))))).toList()), loading: ()=> const CircularProgressIndicator(), error: (e,_ )=> Text('Erreur $e'))]); }
  Widget _tabJournal(){ final journals = ref.watch(journalProvider(pid)); return Stack(children: [journals.when(data: (List<PregnancyJournal> list)=> ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_,i){ final j=list[i]; return Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if(j.photoUrl!=null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(j.photoUrl!, height:120, width: double.infinity, fit: BoxFit.cover)), Text(j.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize:12)), Text(j.content, style: const TextStyle(fontSize:11))])); }), loading: ()=> const Center(child: CircularProgressIndicator()), error: (_,__ )=> const Text('Erreur')), if(!isDoctor) Positioned(bottom:16, right:16, child: FloatingActionButton(onPressed: _addJournalPhoto, child: const Icon(Icons.add_a_photo))) ]); }
  Widget _tabPrepa(PregnancyProfile p){ final checks = ref.watch(checklistProvider(pid)); final contractions = ref.watch(contractionsProvider(pid)); return ListView(padding: const EdgeInsets.all(16), children: [const Text('⏱️ Contractions', style: TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height:8), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [Text('$_cSec s', style: const TextStyle(fontSize:28, fontWeight: FontWeight.w900)), ElevatedButton(onPressed: isDoctor? null : _toggleContraction, style: ElevatedButton.styleFrom(backgroundColor: _cTimer==null? Colors.green : Colors.red), child: Text(_cTimer==null? 'START':'STOP', style: const TextStyle(color: Colors.white))), contractions.when(data: (List<PregnancyContraction> list){ if(list.isEmpty) return const Text('Aucune', style: TextStyle(fontSize:11)); final avgDur = list.map((e)=> e.durationSec).reduce((a,b)=> a+b)/list.length; return Column(children: [Text('Moy: ${avgDur.toStringAsFixed(0)}s', style: const TextStyle(fontSize:11, fontWeight: FontWeight.bold)),...list.take(5).map((c)=> ListTile(dense:true, title: Text('${c.durationSec}s')))]); }, loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')) ])), const SizedBox(height:12), const Text('🎒 Valise', style: TextStyle(fontWeight: FontWeight.w900)), checks.when(data: (List<PregnancyChecklist> list)=> Column(children: list.map((c)=> CheckboxListTile(value: c.done, title: Text(c.item, style: const TextStyle(fontSize:12)), onChanged: (v) async { await ref.read(grossesseServiceProvider).toggleChecklist(c.id, v!); ref.invalidate(checklistProvider(pid)); })).toList()), loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')) ]); }
  Widget _tabUrgences(PregnancyProfile p)=> ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)), child: const Text('🚨 Saignements, liquide, fievre >38.5, TA >140, 0 mouvement 12h, contractions <37 SA', style: TextStyle(fontSize:11, color: Color(0xFFB91C1C)))), ListTile(leading: const Icon(Icons.local_hospital, color: Colors.red), title: Text('DPA ${p.dpa.day}/${p.dpa.month}'), subtitle: const Text('15 / 112'))]);
  Widget _vitalChip(String label, String type)=> ActionChip(label: Text(label, style: const TextStyle(fontSize:11)), onPressed: ()=> _addVital(type));
  void _addVital(String type) async { final c= TextEditingController(); showDialog(context: context, builder: (_)=> AlertDialog(title: Text('Ajouter $type'), content: TextField(controller: c), actions: [TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addVital(pid, type, c.text); ref.invalidate(vitalsProvider(pid)); if(mounted) Navigator.pop(context); }, child: const Text('OK'))])); }
  void _addJournalPhoto() async { final picker=ImagePicker(); final file=await picker.pickImage(source: ImageSource.gallery); if(file==null) return; final bytes=await file.readAsBytes(); final photoUrl=Supabase.instance.client.storage.from('pregnancy_photos').getPublicUrl('journal/${DateTime.now().millisecondsSinceEpoch}.jpg'); await Supabase.instance.client.storage.from('pregnancy_photos').uploadBinary('journal/${DateTime.now().millisecondsSinceEpoch}.jpg', bytes); await ref.read(grossesseServiceProvider).addJournal(pid, 'Ventre S${ref.read(grossesseProfileProvider(pid)).value?.sa??''}', 'Photo ventre', photoUrl: photoUrl); ref.invalidate(journalProvider(pid)); }
  void _pickDoc() async { final res=await FilePicker.platform.pickFiles(withData:true); if(res==null) return; final f=res.files.first; await Supabase.instance.client.storage.from('pregnancy_docs').uploadBinary('${pid??Supabase.instance.client.auth.currentUser!.id}/${f.name}', f.bytes!); if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.name} uploade'))); }
  void _addConsultation() async { final t= TextEditingController(); final d= TextEditingController(); showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Consultation'), content: Column(mainAxisSize: MainAxisSize.min, children:[TextField(controller: t, decoration: const InputDecoration(labelText: 'Titre')), TextField(controller: d, decoration: const InputDecoration(labelText: 'Notes'))]), actions:[TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addConsultation(pid, t.text, d.text); ref.invalidate(grossesseRecordsProvider(pid)); if(mounted) Navigator.pop(context); }, child: const Text('OK'))])); }
  void _toggleContraction() async { if(_cTimer==null){ _cSec=0; _cTimer=Timer.periodic(const Duration(seconds:1), (_){ if(mounted) setState(()=> _cSec++); }); } else { _cTimer?.cancel(); _cTimer=null; final inter=_lastC==null? 0 : DateTime.now().difference(_lastC!).inSeconds; final sec=_cSec; setState(()=> _cSec=0); _lastC=DateTime.now(); await ref.read(grossesseServiceProvider).addContraction(pid, sec, inter); ref.invalidate(contractionsProvider(pid)); } }
  Future<void> _exportPdf() async { final profile=ref.read(grossesseProfileProvider(pid)).value; if(profile==null) return; final vitals=ref.read(vitalsProvider(pid)).value?? []; final doc=pw.Document(); doc.addPage(pw.Page(build: (c)=> pw.Column(children: [pw.Text('Suivi Grossesse DPA ${profile.dpa}'),...vitals.map((v)=> pw.Text('${v.type}: ${v.value}'))]))); await Printing.layoutPdf(onLayout: (f)=> doc.save()); }
}
