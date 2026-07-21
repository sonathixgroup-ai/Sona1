import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/thix_sante_colors.dart';
import '../../patient/providers/grossesse_provider.dart';
import '../../patient/models/grossesse_model.dart';

class SuiviGrossessePage extends ConsumerStatefulWidget {
  final String? patientId; // null = femme, rempli = médecin lié
  const SuiviGrossessePage({super.key, this.patientId});
  @override ConsumerState<SuiviGrossessePage> createState()=> _SuiviGrossessePageState();
}

class _SuiviGrossessePageState extends ConsumerState<SuiviGrossessePage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Timer? _timer; int _sec=0; DateTime? _lastContraction;
  String? get pid => widget.patientId;
  bool get isDoctor => pid!=null;

  @override void initState(){ _tab = TabController(length: 6, vsync: this); super.initState();}
  @override void dispose(){ _tab.dispose(); _timer?.cancel(); super.dispose();}

  @override Widget build(BuildContext context){
    final profileAsync = ref.watch(grossesseProfileProvider(pid));
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(backgroundColor: Colors.white, elevation:0, leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: ()=> Navigator.pop(context)), title: Text(isDoctor? 'Suivi Grossesse - Patiente' : 'Suivi Grossesse', style: const TextStyle(color: ThixSanteColors.ink, fontWeight: FontWeight.w800, fontSize:14))),
      body: profileAsync.when(
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e,_ )=> Center(child: Text('Erreur $e')),
        data: (profile){
          if(profile==null) return _createProfile();
          final info = ref.read(grossesseServiceProvider).getBabyInfo(profile.sa);
          return Column(children: [
            _dashboard(profile, info),
            TabBar(controller: _tab, isScrollable:true, labelColor: ThixSanteColors.primary, tabs: const [Tab(text:'Bébé'), Tab(text:'Maman'), Tab(text:'RDV'), Tab(text:'Journal'), Tab(text:'Prépa'), Tab(text:'Urgences')]),
            Expanded(child: TabBarView(controller: _tab, children: [_tabBebe(profile, info), _tabMaman(), _tabRDV(), _tabJournal(), _tabPrepa(), _tabUrgences(profile)])),
          ]);
        },
      ),
    );
  }

  Widget _dashboard(PregnancyProfile p, BabyWeekInfo info){
    return Container(margin: const EdgeInsets.all(12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Text('🤰', style: TextStyle(fontSize:24)), const SizedBox(width:8), Expanded(child: Text('${p.sa} sem + ${p.daysRemain}j • DPA ${p.dpa.day}/${p.dpa.month}/${p.dpa.year}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize:13))), Container(padding: const EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text('❤️ ${p.remainingDays} j', style: const TextStyle(fontWeight: FontWeight.w800, fontSize:11)))]),
      const SizedBox(height:8), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p.progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight:6)),
      const SizedBox(height:4), Text('${info.fruit} • ${info.size} • ${info.weight} • ${info.desc}', style: const TextStyle(color: Colors.white70, fontSize:10)),
    ]));
  }

  Widget _tabBebe(PregnancyProfile p, BabyWeekInfo info){
    final kicks = ref.watch(kicksProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(info.fruit, style: const TextStyle(fontSize:40)), Text('${info.size} / ${info.weight}', style: const TextStyle(fontWeight: FontWeight.w800)), Text(info.desc, style: const TextStyle(fontSize:11, color: Colors.grey))])),
      const SizedBox(height:12),
      kicks.when(data: (list){
        final today = list.where((e)=> e.createdAt.day==DateTime.now().day).length;
        return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$today coups aujourd\'hui', style: const TextStyle(fontWeight: FontWeight.w800)), Text('${list.length} historique', style: const TextStyle(fontSize:10, color: Colors.grey)) ])),
          if(!isDoctor) ElevatedButton(onPressed: () async { await ref.read(grossesseServiceProvider).addKick(pid); ref.invalidate(kicksProvider(pid)); }, child: const Text('+1 coup')),
        ]));
      }, loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')),
    ]);
  }

  Widget _tabMaman(){
    final vitals = ref.watch(vitalsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing:6, children: [
        _vitalChip('Poids', VitalType.poids), _vitalChip('TA', VitalType.tension), _vitalChip('Glycémie', VitalType.glycemie),
        _vitalChip('Symptôme', VitalType.symptome), _vitalChip('Humeur', VitalType.humeur), _vitalChip('Sommeil', VitalType.sommeil),
      ]),
      const SizedBox(height:12),
      vitals.when(data: (list)=> Column(children: list.map((e)=> Container(margin: const EdgeInsets.only(bottom:6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [Expanded(child: Text('${e.type.name}: ${e.value} ${e.value2??''}')), Text(e.createdAt.toString().substring(0,10), style: const TextStyle(fontSize:10))]))).toList()), loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')),
    ]);
  }

  Widget _tabRDV(){
    final records = ref.watch(grossesseRecordsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      if(isDoctor) ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Ajouter consultation / Echo'), onPressed: ()=> _addConsultation()),
      const SizedBox(height:8),
      records.when(data: (list)=> Column(children: list.map((r)=> Container(margin: const EdgeInsets.only(bottom:6), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Row(children: [Container(width:36,height:36,decoration: BoxDecoration(color: r.typeLightColor, borderRadius: BorderRadius.circular(8)), child: Icon(r.typeIcon, color: r.typeColor, size:18)), const SizedBox(width:8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.title, style: const TextStyle(fontSize:12, fontWeight: FontWeight.w700)), Text('${r.examDate?.day}/${r.examDate?.month} • ${r.doctorName??'Pro'}', style: const TextStyle(fontSize:10, color: Colors.grey))]))]))).toList()), loading: ()=> const CircularProgressIndicator(), error: (e,_ )=> Text('Erreur $e')),
    ]);
  }

  Widget _tabJournal(){
    final journals = ref.watch(journalProvider(pid));
    return Stack(children: [
      journals.when(data: (list)=> ListView.builder(padding: const EdgeInsets.all(16), itemCount: list.length, itemBuilder: (_,i){ final j=list[i]; return Container(margin: const EdgeInsets.only(bottom:8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(j.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize:12)), Text(j.content, style: const TextStyle(fontSize:11)), if(j.mood!=null) Text(j.mood!, style: const TextStyle(fontSize:10))])); }), loading: ()=> const Center(child: CircularProgressIndicator()), error: (_,__ )=> const Text('Erreur')),
      if(!isDoctor) Positioned(bottom:16, right:16, child: FloatingActionButton(onPressed: ()=> _addJournal(), child: const Icon(Icons.add))),
    ]);
  }

  Widget _tabPrepa(){
    final checks = ref.watch(checklistProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('🎒 Valise maternité', style: TextStyle(fontWeight: FontWeight.w800)),
      checks.when(data: (list)=> Column(children: list.map((c)=> CheckboxListTile(value: c.done, title: Text(c.item, style: const TextStyle(fontSize:12)), onChanged: isDoctor? null : (v) async { await ref.read(grossesseServiceProvider).toggleChecklist(c.id, v!); ref.invalidate(checklistProvider(pid)); })).toList()), loading: ()=> const CircularProgressIndicator(), error: (_,__ )=> const Text('Erreur')),
      const SizedBox(height:12),
      const Text('⏱️ Contractions', style: TextStyle(fontWeight: FontWeight.w800)),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [
        Text('$_sec s', style: const TextStyle(fontSize:28, fontWeight: FontWeight.w900)),
        ElevatedButton(onPressed: isDoctor? null : _toggleContraction, style: ElevatedButton.styleFrom(backgroundColor: _timer==null? Colors.green : Colors.red), child: Text(_timer==null? 'START' : 'STOP', style: const TextStyle(color: Colors.white))),
      ])),
    ]);
  }

  Widget _tabUrgences(PregnancyProfile p){
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)), child: const Text('🚨 Saignements, perte liquide, fièvre >38.5, maux tête + mouches, contractions <37 SA, bébé bouge plus 12h -> Urgences', style: TextStyle(fontSize:11, color: Color(0xFFB91C1C)))),
      ListTile(leading: const Icon(Icons.local_hospital, color: Colors.red), title: Text('Hôpital - DPA ${p.dpa.day}/${p.dpa.month}'), subtitle: const Text('15 / 112 - THIX Urgent')),
    ]);
  }

  Widget _vitalChip(String label, VitalType type)=> ActionChip(label: Text(label, style: const TextStyle(fontSize:11)), onPressed: ()=> _addVital(type));

  Widget _createProfile(){
    final ctrl = TextEditingController();
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('🤰', style: TextStyle(fontSize:50)), const Text('DDR - Dernières règles', style: TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height:8),
      TextField(controller: ctrl, readOnly:true, decoration: const InputDecoration(hintText: 'Choisir date', border: OutlineInputBorder()), onTap: () async { final d= await showDatePicker(context: context, initialDate: DateTime.now().subtract(const Duration(days:168)), firstDate: DateTime.now().subtract(const Duration(days:300)), lastDate: DateTime.now()); if(d!=null) ctrl.text = d.toIso8601String().substring(0,10); }),
      const SizedBox(height:12),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () async { if(ctrl.text.isEmpty) return; await ref.read(grossesseServiceProvider).createProfile(pid, DateTime.parse(ctrl.text)); ref.invalidate(grossesseProfileProvider(pid)); }, child: const Text('COMMENCER'))),
    ])));
  }

  void _addVital(VitalType type) async {
    final c = TextEditingController(); final c2 = TextEditingController();
    showDialog(context: context, builder: (_)=> AlertDialog(title: Text('Ajouter ${type.name}'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: c, decoration: const InputDecoration(hintText: 'Valeur')), if(type==VitalType.tension) TextField(controller: c2, decoration: const InputDecoration(hintText: 'Pouls'))]), actions: [TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addVital(pid, type, c.text, value2: c2.text); ref.invalidate(vitalsProvider(pid)); if(mounted) Navigator.pop(context); }, child: const Text('OK'))]));
  }
  void _addJournal() async {
    final t= TextEditingController(); final co= TextEditingController();
    showModalBottomSheet(context: context, isScrollControlled:true, builder: (_)=> Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(padding: const EdgeInsets.all(16), child: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(hintText: 'Titre ex: Ventre S24')), TextField(controller: co, decoration: const InputDecoration(hintText: 'Note'), maxLines:3), ElevatedButton(onPressed: () async { await ref.read(grossesseServiceProvider).addJournal(pid, t.text, co.text, mood: '😊'); ref.invalidate(journalProvider(pid)); if(mounted) Navigator.pop(context); }, child: const Text('Enregistrer'))]))));
  }
  void _addConsultation() async {
    final t= TextEditingController(); final d= TextEditingController();
    showDialog(context: context, builder: (_)=> AlertDialog(title: const Text('Consultation grossesse'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'Titre ex: Echo T2')), TextField(controller: d, decoration: const InputDecoration(labelText: 'Description'))]), actions: [TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addConsultation(pid, t.text, d.text); ref.invalidate(grossesseRecordsProvider(pid)); if(mounted) Navigator.pop(context); }, child: const Text('Enregistrer'))]));
  }
  void _toggleContraction(){
    if(_timer==null){ _sec=0; _timer=Timer.periodic(const Duration(seconds:1), (_)=> setState(()=> _sec++)); }
    else { _timer?.cancel(); _timer=null; final interval = _lastContraction==null? 0 : DateTime.now().difference(_lastContraction!).inSeconds; ref.read(grossesseServiceProvider).addContraction(pid, _sec, interval); _lastContraction=DateTime.now(); setState(()=> _sec=0); }
  }
}
