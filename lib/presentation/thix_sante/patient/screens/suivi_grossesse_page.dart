// lib/presentation/thix_sante/sante/screens/suivi_grossesse_page.dart
import 'dart:typed_data';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart'; 
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart';
import '../../core/thix_sante_colors.dart';
import '../../patient/providers/grossesse_provider.dart';
import '../../patient/services/grossesse_advice_service.dart';
import '../../patient/models/grossesse_model.dart';
import '../widgets/countdown_widget.dart';

class SuiviGrossessePage extends ConsumerStatefulWidget {
  final String? patientId; 
  const SuiviGrossessePage({super.key, this.patientId});
  @override 
  ConsumerState<SuiviGrossessePage> createState() => _SuiviGrossessePageState();
}

class _SuiviGrossessePageState extends ConsumerState<SuiviGrossessePage> with SingleTickerProviderStateMixin {
  late TabController _tab;
  Timer? _cTimer; 
  int _cSec = 0; 
  DateTime? _lastC;
  String? get pid => widget.patientId; 
  bool get isDoctor => pid != null;

  @override 
  void initState() { 
    _tab = TabController(length: 6, vsync: this); 
    super.initState(); 
  }

  @override 
  void dispose() { 
    _tab.dispose(); 
    _cTimer?.cancel(); 
    super.dispose(); 
  }

  @override 
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(grossesseProfileProvider(pid));
    return Scaffold(
      backgroundColor: ThixSanteColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), 
        title: Text(isDoctor ? 'Suivi Patiente' : 'Mon Suivi', style: const TextStyle(fontWeight: FontWeight.w800)), 
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () => _exportPdf()),
          PopupMenuButton(itemBuilder: (_) => [const PopupMenuItem(value: 'share', child: Text('Partager')), const PopupMenuItem(value: 'lang', child: Text('FR/EN/AR'))]),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur $e')),
        data: (profile) {
          if (profile == null) return _createProfile();
          final advice = GrossesseAdviceService.getWeekAdvice(profile.sa);
          final info = GrossesseAdviceService.getBabyInfo(profile.sa);
          return Column(children: [
            _riskAlerts(),
            _dashboard(profile, info),
            TabBar(
              controller: _tab, 
              isScrollable: true, 
              labelColor: ThixSanteColors.primary, 
              tabs: const [Tab(text: 'Bébé'), Tab(text: 'Maman'), Tab(text: 'RDV & Docs'), Tab(text: 'Journal'), Tab(text: 'Prépa'), Tab(text: 'Urgences')]
            ),
            Expanded(
              child: TabBarView(
                controller: _tab, 
                children: [_tabBebe(profile, advice, info), _tabMaman(), _tabDocs(), _tabJournal(), _tabPrepa(profile), _tabUrgences(profile)]
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _riskAlerts() {
    final vitals = ref.watch(vitalsProvider(pid)).value ?? [];
    final kicks = ref.watch(kicksProvider(pid)).value ?? [];
    final contractions = ref.watch(contractionsProvider(pid)).value ?? [];
    final profile = ref.watch(grossesseProfileProvider(pid)).value;
    if (profile == null) return const SizedBox();
    final risks = ref.read(grossesseServiceProvider).calculateRisks(sa: profile.sa, vitals: vitals, kicks: kicks, contractions: contractions);
    if (risks.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(8), 
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)), 
        child: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 6), Text('Tout va bien - N\'oubliez pas vos vitamines', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))])
      );
    }
    return Column(
      children: risks.map((r) => Container(
        width: double.infinity, 
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))), 
        child: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C)))
      )).toList()
    );
  }

  Widget _dashboard(PregnancyProfile p, BabyWeekInfo info) {
    final isLabor = p.sa >= 37;
    return Semantics(
      header: true, 
      child: Container(
        margin: const EdgeInsets.all(12), 
        padding: const EdgeInsets.all(14), 
        decoration: BoxDecoration(gradient: LinearGradient(colors: isLabor ? [Colors.red, const Color(0xFFB91C1C)] : [const Color(0xFFEC4899), const Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(16)), 
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p.trimester(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)), Text('${p.sa} SA + ${p.daysRemain}j', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 8),
          Row(children: [Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/baby/week_${p.sa}.png', errorBuilder: (_, __, ___) => Center(child: Text(info.fruit, style: const TextStyle(fontSize: 28)))))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Bébé taille ${info.fruit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)), Text('${info.size} • ${info.weight}', style: const TextStyle(color: Colors.white, fontSize: 11))]))]),
          const SizedBox(height: 10),
          CountdownWidget(dpa: p.dpa),
          const SizedBox(height: 8), 
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: p.progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 6)),
          if (isLabor && !isDoctor) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white), onPressed: () {}, child: const Text('🚨 JE SUIS EN TRAVAIL', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900))))),
        ])
      )
    );
  }

  Widget _tabBebe(PregnancyProfile p, WeekAdvice advice, BabyWeekInfo info) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(advice.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), 
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), 
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...advice.babyDevelopment.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $e', style: const TextStyle(fontSize: 12)))),
          const Divider(),
          Row(children: [
            Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('✔ À privilégier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF166534))), ...advice.nutrition.map((e) => Text(e, style: const TextStyle(fontSize: 11)))]))), 
            const SizedBox(width: 8), 
            Expanded(child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('❌ À éviter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF991B1B))), ...advice.avoid.map((e) => Text(e, style: const TextStyle(fontSize: 11)))])))
          ]),
        ])
      ),
      const SizedBox(height: 12),
      _kickCounter(),
    ]);
  }

  Widget _kickCounter() {
    final kicksAsync = ref.watch(kicksProvider(pid));
    return kicksAsync.when(
      data: (list) {
        final today = list.where((k) => k.createdAt.day == DateTime.now().day).length;
        return Container(
          padding: const EdgeInsets.all(12), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), 
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Coups aujourd\'hui', style: TextStyle(fontWeight: FontWeight.bold)), Text('$today / 10', style: const TextStyle(fontWeight: FontWeight.w900, color: ThixSanteColors.primary))]),
            const SizedBox(height: 8), 
            LinearProgressIndicator(value: (today / 10).clamp(0, 1).toDouble(), minHeight: 8, borderRadius: BorderRadius.circular(8)),
            if (!isDoctor) Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () async { await ref.read(grossesseServiceProvider).addKick(pid); ref.invalidate(kicksProvider(pid)); }, icon: const Icon(Icons.touch_app), label: const Text('Enregistrer un coup')))),
          ])
        );
      }, 
      loading: () => const CircularProgressIndicator(), 
      error: (_, __) => const Text('Erreur')
    );
  }

  Widget _tabMaman() {
    final vitals = ref.watch(vitalsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('📈 Courbes réelles', style: TextStyle(fontWeight: FontWeight.w900)), 
      const SizedBox(height: 8),
      Container(
        height: 160, 
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), 
        child: vitals.when(
          data: (list) {
            final poids = list.where((v) => v.type == 'poids').toList().reversed.take(7).toList().reversed.toList();
            if (poids.isEmpty) return const Center(child: Text('Pas encore de données', style: TextStyle(fontSize: 11, color: Colors.grey)));
            final spots = <FlSpot>[]; 
            for (int i = 0; i < poids.length; i++) { 
              spots.add(FlSpot(i.toDouble(), double.tryParse(poids[i].value) ?? 0)); 
            }
            return LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: ThixSanteColors.primary, barWidth: 3, dotData: const FlDotData(show: true))], titlesData: const FlTitlesData(show: true)));
          }, 
          loading: () => const CircularProgressIndicator(), 
          error: (_, __) => const Text('Erreur')
        )
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 6, children: [_vitalChip('Poids', 'poids'), _vitalChip('TA', 'tension'), _vitalChip('Glycémie', 'glycemie')]),
      const SizedBox(height: 12),
      vitals.when(
        data: (list) => Column(children: list.take(10).map((v) => ListTile(dense: true, title: Text('${v.type}: ${v.value}'), subtitle: Text(v.createdAt.toString().substring(0, 16)))).toList()), 
        loading: () => const CircularProgressIndicator(), 
        error: (_, __) => const Text('Erreur')
      ),
    ]);
  }

  Widget _tabDocs() {
    final records = ref.watch(grossesseRecordsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (isDoctor) ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Ajouter consultation'), onPressed: () => _addConsultation()),
      OutlinedButton.icon(icon: const Icon(Icons.upload_file), label: const Text('Ajouter PDF écho/analyse'), onPressed: () => _pickDoc()),
      const SizedBox(height: 12),
      records.when(
        data: (list) => Column(children: list.map((r) => Card(child: ListTile(title: Text(r.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), subtitle: Text(r.description ?? '', style: const TextStyle(fontSize: 10)), trailing: IconButton(icon: const Icon(Icons.visibility), onPressed: () {})))).toList()), 
        loading: () => const CircularProgressIndicator(), 
        error: (e, _) => Text('Erreur $e')
      ),
    ]);
  }

  Widget _tabJournal() {
    final journals = ref.watch(journalProvider(pid));
    return Stack(children: [
      journals.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(16), 
          itemCount: list.length, 
          itemBuilder: (_, i) { 
            final j = list[i]; 
            return Container(
              margin: const EdgeInsets.only(bottom: 8), 
              padding: const EdgeInsets.all(10), 
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), 
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (j.photoUrl != null) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(j.photoUrl!, height: 120, width: double.infinity, fit: BoxFit.cover)), 
                Text(j.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), 
                Text(j.content, style: const TextStyle(fontSize: 11))
              ])
            ); 
          }
        ), 
        loading: () => const Center(child: CircularProgressIndicator()), 
        error: (_, __) => const Text('Erreur')
      ),
      if (!isDoctor) Positioned(bottom: 16, right: 16, child: FloatingActionButton(onPressed: () => _addJournalPhoto(), child: const Icon(Icons.add_a_photo))),
    ]);
  }

  Widget _tabPrepa(PregnancyProfile p) {
    final checks = ref.watch(checklistProvider(pid));
    final contractions = ref.watch(contractionsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('⏱️ Contractions', style: TextStyle(fontWeight: FontWeight.w900)), 
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), 
        child: Column(children: [
          Text('$_cSec s', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)), 
          const SizedBox(height: 8),
          ElevatedButton(onPressed: isDoctor ? null : _toggleContraction, style: ElevatedButton.styleFrom(backgroundColor: _cTimer == null ? Colors.green : Colors.red), child: Text(_cTimer == null ? 'START' : 'STOP', style: const TextStyle(color: Colors.white))),
          const Divider(),
          contractions.when(
            data: (list) { 
              if (list.isEmpty) return const Text('Aucune', style: TextStyle(fontSize: 11)); 
              final avgDur = list.map((e) => e.durationSec).reduce((a, b) => a + b) / list.length; 
              final avgInter = list.length > 1 ? list.map((e) => e.intervalSec).reduce((a, b) => a + b) / list.length : 0; 
              return Column(children: [
                Text('Moyenne: ${avgDur.toStringAsFixed(0)}s durée / ${(avgInter / 60).toStringAsFixed(0)} min intervalle', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ...list.take(5).map((c) => ListTile(dense: true, title: Text('${c.durationSec}s'), subtitle: Text('Intervalle ${(c.intervalSec / 60).toStringAsFixed(0)} min')))
              ]); 
            }, 
            loading: () => const CircularProgressIndicator(), 
            error: (_, __) => const Text('Erreur')
          ),
        ])
      ),
      const SizedBox(height: 12),
      const Text('🎒 Valise', style: TextStyle(fontWeight: FontWeight.w900)),
      checks.when(
        data: (list) => Column(
          children: list.map<Widget>((c) => CheckboxListTile(
            value: c.done, 
            title: Text(c.item, style: const TextStyle(fontSize: 12)), 
            onChanged: (v) async { 
              await ref.read(grossesseServiceProvider).toggleChecklist(c.id, v!); 
              ref.invalidate(checklistProvider(pid)); 
            }
          )).toList(),
        ), 
        loading: () => const CircularProgressIndicator(), 
        error: (_, __) => const Text('Erreur')
      ),
    ]); // FERMETURE DU LISTVIEW DE _tabPrepa
  } // FERMETURE DE LA MÉTHODE _tabPrepa

  Widget _tabUrgences(PregnancyProfile p) => ListView(padding: const EdgeInsets.all(16), children: [Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12)), child: const Text('🚨 Saignements, liquide, fièvre >38.5, TA >140, 0 mouvement 12h, contractions <37 SA', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)))), ListTile(leading: const Icon(Icons.local_hospital, color: Colors.red), title: Text('Maternité DPA ${p.dpa.day}/${p.dpa.month}'), subtitle: const Text('15 / 112 - THIX Urgent'))]);

  Widget _vitalChip(String label, String type) => ActionChip(label: Text(label, style: const TextStyle(fontSize: 11)), onPressed: () => _addVital(type));

  Widget _createProfile() {
    final ctrl = TextEditingController(); 
    PregnancyType selectedType = PregnancyType.singleton;
    return StatefulBuilder(builder: (context, setLocal) { 
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24), 
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🤰', style: TextStyle(fontSize: 50)), 
            const Text('Créer suivi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            DropdownButton<PregnancyType>(value: selectedType, items: PregnancyType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) { if (v != null) setLocal(() => selectedType = v); }),
            TextField(controller: ctrl, readOnly: true, decoration: const InputDecoration(hintText: 'DDR', border: OutlineInputBorder()), onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now().subtract(const Duration(days: 168)), firstDate: DateTime.now().subtract(const Duration(days: 300)), lastDate: DateTime.now()); if (d != null) ctrl.text = d.toIso8601String().substring(0, 10); }),
            const SizedBox(height: 12), 
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () async { if (ctrl.text.isEmpty) return; await ref.read(grossesseServiceProvider).createProfile(pid, DateTime.parse(ctrl.text), selectedType); ref.invalidate(grossesseProfileProvider(pid)); }, child: const Text('COMMENCER'))),
          ])
        )
      ); 
    });
  }

  void _addVital(String type) async { final c = TextEditingController(); showDialog(context: context, builder: (_) => AlertDialog(title: Text('Ajouter $type'), content: TextField(controller: c), actions: [TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addVital(pid, type, c.text); ref.invalidate(vitalsProvider(pid)); if (mounted) Navigator.pop(context); }, child: const Text('OK'))])); }
  
  void _addJournalPhoto() async {
    final picker = ImagePicker(); 
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return; 
    final bytes = await file.readAsBytes();
    final url = await ref.read(grossesseServiceProvider).uploadPhoto(pid, file.path, bytes);
    final t = TextEditingController(text: 'Ventre S${ref.read(grossesseProfileProvider(pid)).value?.sa ?? ''}');
    if (!mounted) return; 
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Journal'), content: TextField(controller: t), actions: [TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addJournal(pid, t.text, 'Photo ventre', photoUrl: url); ref.invalidate(journalProvider(pid)); if (mounted) Navigator.pop(context); }, child: const Text('Enregistrer'))]));
  }
  
  void _pickDoc() async { 
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']); 
    if (res == null) return; 
    final bytes = res.files.first.bytes; 
    if (bytes == null) return; 
    await ref.read(grossesseServiceProvider).uploadDoc(pid, res.files.first.name, bytes); 
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploadé'))); 
  }
  
  void _addConsultation() async { final t = TextEditingController(); final d = TextEditingController(); showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Consultation'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: t, decoration: const InputDecoration(labelText: 'Titre')), TextField(controller: d, decoration: const InputDecoration(labelText: 'Notes'))]), actions: [TextButton(onPressed: () async { await ref.read(grossesseServiceProvider).addConsultation(pid, t.text, d.text); ref.invalidate(grossesseRecordsProvider(pid)); if (mounted) Navigator.pop(context); }, child: const Text('OK'))])); }
  
  void _toggleContraction() { if (_cTimer == null) { _cSec = 0; _cTimer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _cSec++)); } else { _cTimer?.cancel(); _cTimer = null; final inter = _lastC == null ? 0 : DateTime.now().difference(_lastC!).inSeconds; ref.read(grossesseServiceProvider).addContraction(pid, _cSec, inter); ref.invalidate(contractionsProvider(pid)); _lastC = DateTime.now(); setState(() => _cSec = 0); } }
  
  Future<void> _exportPdf() async {
    final profile = ref.read(grossesseProfileProvider(pid)).value; 
    if (profile == null) return;
    final vitals = ref.read(vitalsProvider(pid)).value ?? [];
    final doc = pw.Document(); 
    doc.addPage(pw.Page(build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('Suivi Grossesse - DPA ${profile.dpa.day}/${profile.dpa.month}/${profile.dpa.year}'), pw.SizedBox(height: 10), ...vitals.map((v) => pw.Text('${v.type}: ${v.value} - ${v.createdAt.toString().substring(0, 10)}'))])));
    await Printing.layoutPdf(onLayout: (f) => doc.save());
  }
}
