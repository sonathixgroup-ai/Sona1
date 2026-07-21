// lib/presentation/thix_sante/patient/screens/suivi_grossesse_page.dart
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
  final DateTime dpa;
  const CountdownWidget({super.key, required this.dpa});
  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = widget.dpa.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _remaining = widget.dpa.difference(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return const Text('Bébé est là !', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16));
    }
    final m = _remaining.inDays ~/ 30;
    final w = (_remaining.inDays % 30) ~/ 7;
    final d = (_remaining.inDays % 30) % 7;
    final h = _remaining.inHours % 24;
    final min = _remaining.inMinutes % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
      child: Text('$m mois $w sem $d j  •  $h h $min m', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.1)),
    );
  }
}

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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: Text(isDoctor ? 'Suivi Patiente' : 'Mon Suivi de Grossesse', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: ThixSanteColors.primary), onPressed: _exportPdf)
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur $e')),
        data: (profile) {
          if (profile == null) return _createProfileWizard();
          
          final advice = GrossesseAdviceService.getWeekAdvice(profile.sa);
          final info = GrossesseAdviceService.getBabyInfo(profile.sa);
          
          return Column(children: [
            _riskAlerts(profile),
            _dashboard(profile, info),
            TabBar(
                controller: _tab,
                isScrollable: true,
                indicatorColor: ThixSanteColors.primary,
                labelColor: ThixSanteColors.primary,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Bébé'),
                  Tab(text: 'Maman'),
                  Tab(text: 'RDV & Docs'),
                  Tab(text: 'Journal'),
                  Tab(text: 'Prépa'),
                  Tab(text: 'Urgences')
                ]),
            Expanded(
                child: TabBarView(controller: _tab, children: [
              _tabBebe(profile, advice, info),
              _tabMaman(),
              _tabDocs(),
              _tabJournal(),
              _tabPrepa(profile),
              _tabUrgences(profile)
            ])),
          ]);
        },
      ),
    );
  }

  // ================= 1. WIZARD CREATION =================
  Widget _createProfileWizard() {
    int step = 0;
    final ddrCtrl = TextEditingController();
    final concepCtrl = TextEditingController();
    final echoCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '25');
    final poidsCtrl = TextEditingController(text: '60');
    final tailleCtrl = TextEditingController(text: '165');
    final parityCtrl = TextEditingController(text: '0');
    final gestiteCtrl = TextEditingController(text: '1');
    PregnancyType type = PregnancyType.singleton;
    BloodGroup bg = BloodGroup.O;
    Rhesus rh = Rhesus.pos;
    bool tabac = false, alcool = false, diabete = false, hta = false;
    final antecedents = <String>{};

    return StatefulBuilder(builder: (context, setLocal) {
      DateTime calcDPA() {
        if (echoCtrl.text.isNotEmpty) return DateTime.parse(echoCtrl.text).add(const Duration(days: 266));
        if (concepCtrl.text.isNotEmpty) return DateTime.parse(concepCtrl.text).add(const Duration(days: 266));
        if (ddrCtrl.text.isEmpty) return DateTime.now().add(const Duration(days: 280));
        
        final ddr = DateTime.parse(ddrCtrl.text);
        final days = type == PregnancyType.jumeaux ? 259 : type.index == 2 ? 245 : 280;

        return ddr.add(Duration(days: days));
      }

      double calcBMI() {
        try {
          final p = double.parse(poidsCtrl.text);
          final t = double.parse(tailleCtrl.text) / 100;
          return p / (t * t);
        } catch (_) { return 0; }
      }

      Future<void> pickDate(TextEditingController c) async {
        final d = await showDatePicker(
            context: context,
            firstDate: DateTime.now().subtract(const Duration(days: 320)),
            lastDate: DateTime.now(),
            initialDate: DateTime.now().subtract(const Duration(days: 60)));
        if (d != null) setLocal(() => c.text = d.toIso8601String().substring(0, 10));
      }

      return SafeArea(
        child: Stepper(
          currentStep: step,
          onStepContinue: () async {
            if (step == 0 && ddrCtrl.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DDR obligatoire')));
              return;
            }
            if (step < 3) {
              setLocal(() => step++);
            } else {
              DateTime? parse(String s) => s.isEmpty ? null : DateTime.tryParse(s);
              await ref.read(grossesseServiceProvider).createFullProfile(
                    pid: pid,
                    ddr: DateTime.parse(ddrCtrl.text),
                    conception: parse(concepCtrl.text),
                    echo: parse(echoCtrl.text),
                    type: type,
                    age: int.parse(ageCtrl.text),
                    parity: int.parse(parityCtrl.text),
                    gravida: int.parse(gestiteCtrl.text),
                    poids: double.parse(poidsCtrl.text),
                    taille: double.parse(tailleCtrl.text),
                    bloodGroup: bg,
                    rhesus: rh,
                    antecedents: antecedents.toList(),
                    tabac: tabac, alcool: alcool, diabete: diabete, hta: hta,
                  );
              ref.invalidate(grossesseProfileProvider(pid));
            }
          },
          onStepCancel: () => setLocal(() { if (step > 0) step--; }),
          steps: [
            Step(title: const Text('DATATION', style: TextStyle(fontWeight: FontWeight.w900)), content: Column(children: [TextFormField(controller: ddrCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'DDR*', border: OutlineInputBorder()), onTap: () => pickDate(ddrCtrl)), const SizedBox(height: 8), TextFormField(controller: concepCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Conception', border: OutlineInputBorder()), onTap: () => pickDate(concepCtrl)), const SizedBox(height: 8), TextFormField(controller: echoCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Echo T1', border: OutlineInputBorder()), onTap: () => pickDate(echoCtrl)), const SizedBox(height: 8), DropdownButtonFormField<PregnancyType>(value: type, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Type'), items: PregnancyType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) => setLocal(() => type = v!)), const SizedBox(height: 8), if (ddrCtrl.text.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)), child: Text('DPA: ${calcDPA().day}/${calcDPA().month}/${calcDPA().year} - IMC ${calcBMI().toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))])),
            Step(title: const Text('PROFIL'), content: Column(children: [Row(children: [Expanded(child: TextFormField(controller: ageCtrl, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextFormField(controller: tailleCtrl, decoration: const InputDecoration(labelText: 'Taille cm', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextFormField(controller: poidsCtrl, decoration: const InputDecoration(labelText: 'Poids kg', border: OutlineInputBorder())))]), const SizedBox(height: 8), Row(children: [Expanded(child: DropdownButtonFormField<BloodGroup>(value: bg, decoration: const InputDecoration(labelText: 'Groupe', border: OutlineInputBorder()), items: BloodGroup.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) => setLocal(() => bg = v!))), const SizedBox(width: 8), Expanded(child: DropdownButtonFormField<Rhesus>(value: rh, decoration: const InputDecoration(labelText: 'Rhesus', border: OutlineInputBorder()), items: Rhesus.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) => setLocal(() => rh = v!)))])])),
            Step(title: const Text('RISQUES'), content: Column(children: [Wrap(spacing: 6, children: ['Pre-eclampsie', 'Diabete', 'Cesarienne', 'Fausse couche'].map((e) => FilterChip(label: Text(e, style: const TextStyle(fontSize: 10)), selected: antecedents.contains(e), onSelected: (v) => setLocal(() { if (v) { antecedents.add(e); } else { antecedents.remove(e); } }))).toList()), CheckboxListTile(value: tabac, dense: true, title: const Text('Tabac', style: TextStyle(fontSize: 12)), onChanged: (v) => setLocal(() => tabac = v!)), CheckboxListTile(value: hta, dense: true, title: const Text('HTA', style: TextStyle(fontSize: 12)), onChanged: (v) => setLocal(() => hta = v!))])),
            Step(title: const Text('CONFIRMATION'), content: Text('DPA ${calcDPA().toString().substring(0, 10)} - Le système va démarrer', style: const TextStyle(fontSize: 12))),
          ],
        ),
      );
    });
  }

  // ================= 2. DASHBOARD PRO & ALERTES =================
  Widget _riskAlerts(PregnancyProfile profile) {
    final vitals = ref.watch(vitalsProvider(pid)).value ?? [];
    final kicks = ref.watch(kicksProvider(pid)).value ?? [];
    final contractions = ref.watch(contractionsProvider(pid)).value ?? [];
    final risks = ref.read(grossesseServiceProvider).calculateRisks(sa: profile.sa, vitals: vitals, kicks: kicks, contractions: contractions);
    
    if (risks.isEmpty) {
      return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
          child: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text("Grossesse normale - Pensez à vos vitamines", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF166534)))
          ]));
    }
    return Column(
        children: risks.map((r) => Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFCA5A5))),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFB91C1C), size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB91C1C))))
                ]))).toList());
  }

  Widget _dashboard(PregnancyProfile p, BabyWeekInfo info) {
    final isLabor = p.sa >= 37;
    final recordsAsync = ref.watch(grossesseRecordsProvider(pid)); // Fetch next RDV

    return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: isLabor ? [Colors.red.shade700, const Color(0xFFB91C1C)] : [ThixSanteColors.primary, const Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: (isLabor ? Colors.red : ThixSanteColors.primary).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(p.trimester().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
                    Text('${p.sa} SA + ${p.daysRemain}j', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))
                  ]),
              const SizedBox(height: 16),
              Row(children: [
                Container(width: 65, height: 65, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Center(child: Text(info.fruit, style: const TextStyle(fontSize: 32)))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Bébé fait la taille de : ${info.fruit}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('📏 ${info.size}   •   ⚖️ ${info.weight}', style: const TextStyle(color: Colors.white, fontSize: 12))
                    ]))
              ]),
              const SizedBox(height: 16),
              CountdownWidget(dpa: p.dpa),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: p.progress, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white), minHeight: 8)),
              
              // Widget Prochain RDV Intégré
              recordsAsync.when(
                data: (records) {
                  if (records.isEmpty) return const SizedBox();
                  return Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.event_available, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Dernier/Prochain RDV : ${records.first.title}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis))
                    ]),
                  );
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox()
              )
            ]));
  }

  // ================= 3. ONGLETS SPÉCIFIQUES =================
  Widget _tabBebe(PregnancyProfile p, WeekAdvice advice, BabyWeekInfo info) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(advice.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ThixSanteColors.ink)),
      const SizedBox(height: 12),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: advice.babyDevelopment
                 .map((e) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: ThixSanteColors.primary)), Expanded(child: Text(e, style: const TextStyle(fontSize: 13, height: 1.4)))])))
                 .toList())),
      const SizedBox(height: 16),
      _kickCounter()
    ]);
  }

  Widget _kickCounter() {
    final kicksAsync = ref.watch(kicksProvider(pid));
    return kicksAsync.when(
        data: (List<PregnancyKick> list) {
          final today = list.where((k) => k.createdAt.day == DateTime.now().day).length;
          return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: ThixSanteColors.primary.withOpacity(0.2))),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [Icon(Icons.pan_tool_rounded, color: ThixSanteColors.primary, size: 20), SizedBox(width: 8), Text('Mouvements (Aujourd\'hui)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
                      Text('$today / 10', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: ThixSanteColors.primary))
                    ]),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (today / 10).clamp(0, 1).toDouble(), minHeight: 10, backgroundColor: Colors.grey.shade100, valueColor: const AlwaysStoppedAnimation(ThixSanteColors.primary))),
                if (!isDoctor)
                  Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () async { await ref.read(grossesseServiceProvider).addKick(pid); ref.invalidate(kicksProvider(pid)); },
                              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                              label: const Text('Enregistrer un coup', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
              ]));
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('Erreur'));
  }

  Widget _tabMaman() {
    final vitals = ref.watch(vitalsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('📈 Suivi du Poids', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 12),
      Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
          child: vitals.when(
              data: (List<PregnancyVital> list) {
                final poids = list.where((v) => v.type == 'poids').toList().reversed.take(7).toList().reversed.toList();
                if (poids.isEmpty) return const Center(child: Text('Aucune donnée de poids pour le moment', style: TextStyle(fontSize: 12, color: Colors.grey)));
                final spots = <FlSpot>[];
                for (int i = 0; i < poids.length; i++) { spots.add(FlSpot(i.toDouble(), double.tryParse(poids[i].value) ?? 0)); }
                return LineChart(LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: ThixSanteColors.primary, barWidth: 4, belowBarData: BarAreaData(show: true, color: ThixSanteColors.primary.withOpacity(0.1)), dotData: const FlDotData(show: true))]
                ));
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Erreur'))),
      const SizedBox(height: 20),
      const Text('Saisie Rapide', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        ActionChip(label: const Text('⚖️ Poids', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, onPressed: () => _addVital('poids')),
        ActionChip(label: const Text('🩸 Tension', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, onPressed: () => _addVital('tension')),
        ActionChip(label: const Text('💧 Glycémie', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, onPressed: () => _addVital('glycemie'))
      ]),
    ]);
  }

  Widget _tabDocs() {
    final records = ref.watch(grossesseRecordsProvider(pid));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        if (isDoctor) Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary, foregroundColor: Colors.white), icon: const Icon(Icons.add), label: const Text('Consultation'), onPressed: _addConsultation)),
        if (isDoctor) const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: ThixSanteColors.primary, side: const BorderSide(color: ThixSanteColors.primary)), icon: const Icon(Icons.upload_file), label: const Text('Ajouter Doc'), onPressed: _pickDoc)),
      ]),
      const SizedBox(height: 20),
      const Text('Dossier Médical', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      records.when(
          data: (list) {
            if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Aucun document pour le moment.", style: TextStyle(color: Colors.grey))));
            return Column(children: list.map((r) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: ListTile(
                  leading: CircleAvatar(backgroundColor: ThixSanteColors.primary.withOpacity(0.1), child: const Icon(Icons.description, color: ThixSanteColors.primary)),
                  title: Text(r.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  subtitle: Text(r.description ?? 'Aucune note', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey))
            )).toList());
          },
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('Erreur $e')),
    ]);
  }

  Widget _tabJournal() {
    final journals = ref.watch(journalProvider(pid));
    return Stack(children: [
      journals.when(
          data: (List<PregnancyJournal> list) {
            final monthEntries = list.where((j) => j.createdAt.month == DateTime.now().month).length;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Résumé du mois
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFFEDD5))),
                  child: Row(children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFEA580C), size: 24),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Résumé de votre mois', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                      Text('$monthEntries souvenir(s) enregistré(s)', style: const TextStyle(fontSize: 12, color: Color(0xFFC2410C))),
                    ])
                  ]),
                ),
                const SizedBox(height: 16),
                ...list.map((j) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (j.photoUrl != null)
                            ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                child: Image.network(j.photoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(j.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(j.content, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                                const SizedBox(height: 8),
                                Text(j.createdAt.toString().substring(0, 10), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          )
                        ])))
              ]
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Erreur')),
      if (!isDoctor)
        Positioned(bottom: 16, right: 16, child: FloatingActionButton.extended(onPressed: _addJournalPhoto, backgroundColor: ThixSanteColors.primary, icon: const Icon(Icons.add_a_photo, color: Colors.white), label: const Text('Nouveau Souvenir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
    ]);
  }

  Widget _tabPrepa(PregnancyProfile p) {
    final checks = ref.watch(checklistProvider(pid));
    final contractions = ref.watch(contractionsProvider(pid));
    
    return ListView(padding: const EdgeInsets.all(16), children: [
      // Section Plan de Naissance & Education
      const Text('Plan & Éducation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: InkWell(onTap: (){}, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.assignment, color: Colors.blue), SizedBox(height: 8), Text('Plan de Naissance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent))])))),
        const SizedBox(width: 8),
        Expanded(child: InkWell(onTap: (){}, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12)), child: const Column(children: [Icon(Icons.menu_book, color: Colors.purple), SizedBox(height: 8), Text('Conseils Pratiques', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purpleAccent))])))),
      ]),
      const SizedBox(height: 20),

      // Suivi des Contractions Intelligent
      const Text('⏱️ Chronomètre Contractions', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
          child: Column(children: [
            Text('$_cSec s', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: ThixSanteColors.primary)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  onPressed: isDoctor ? null : _toggleContraction,
                  style: ElevatedButton.styleFrom(backgroundColor: _cTimer == null ? Colors.green : Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_cTimer == null ? 'DÉMARRER' : 'ARRÊTER', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)))
            ),
            const SizedBox(height: 16),
            contractions.when(
                data: (List<PregnancyContraction> list) {
                  if (list.isEmpty) return const Text('Aucune contraction enregistrée', style: TextStyle(fontSize: 12, color: Colors.grey));
                  
                  // Détection de Travail Actif
                  bool activeLabor = false;
                  if (list.length >= 3) {
                    final avgDur = list.take(3).map((e) => e.durationSec).reduce((a, b) => a + b) / 3;
                    final avgInter = list.take(3).map((e) => e.intervalSec).reduce((a, b) => a + b) / 3;
                    if (avgDur >= 40 && avgInter <= 300) activeLabor = true; // +40s, - de 5 minutes
                  }

                  return Column(children: [
                    if (activeLabor) Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.warning, color: Colors.red, size: 18), SizedBox(width: 8), Expanded(child: Text('⚠️ Travail Actif Probable ! Contactez la maternité.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)))])),
                    const Align(alignment: Alignment.centerLeft, child: Text('Dernières contractions :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ...list.take(4).map((c) => ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.timer_outlined, color: Colors.grey), title: Text('Durée : ${c.durationSec}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), trailing: Text('Intervalle : ${(c.intervalSec / 60).toStringAsFixed(1)} min', style: const TextStyle(color: Colors.grey, fontSize: 12))))
                  ]);
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Erreur')),
          ])),
      
      const SizedBox(height: 20),
      const Text('🎒 Valise de Maternité', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: checks.when(
            data: (List<ChecklistItem> list) => Column(
                children: list.map((c) => CheckboxListTile(
                        value: c.done,
                        activeColor: ThixSanteColors.primary,
                        title: Text(c.item, style: TextStyle(fontSize: 13, decoration: c.done ? TextDecoration.lineThrough : null)),
                        onChanged: (v) async {
                          await ref.read(grossesseServiceProvider).toggleChecklist(c.id, v!);
                          ref.invalidate(checklistProvider(pid));
                        }))
                   .toList()),
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Erreur')),
      ),
    ]);
  }

  Widget _tabUrgences(PregnancyProfile p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Quand se rendre à la Maternité ?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 12),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UrgenceItem('Saignements', 'Similaires à des règles.'),
                    _UrgenceItem('Perte de liquide', 'Rupture de la poche des eaux (même sans contraction).'),
                    _UrgenceItem('Fièvre > 38°C', 'Risque d\'infection pour le bébé.'),
                    _UrgenceItem('Baisse des mouvements', 'Si le bébé bouge moins de 10 fois par jour.'),
                    _UrgenceItem('Contractions intenses', 'Toutes les 5 minutes depuis plus de 2 heures.'),
                  ],
                )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: (){}, 
              icon: const Icon(Icons.phone_in_talk, size: 28), 
              label: Text('APPELER LA MATERNITÉ\nDPA: ${p.dpa.day}/${p.dpa.month}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900))
            )
          ]);

  void _addVital(String type) async {
    final c = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: Text('Ajouter une mesure ($type)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                content: TextField(controller: c, keyboardType: TextInputType.number, decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Valeur')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary),
                      onPressed: () async {
                        await ref.read(grossesseServiceProvider).addVital(pid, type, c.text);
                        ref.invalidate(vitalsProvider(pid));
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)))
                ]));
  }

  void _addJournalPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final path = 'journal/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage.from('pregnancy_photos').uploadBinary(path, bytes);
    final url = Supabase.instance.client.storage.from('pregnancy_photos').getPublicUrl(path);
    await ref.read(grossesseServiceProvider).addJournal(pid, 'Souvenir S${ref.read(grossesseProfileProvider(pid)).value?.sa ?? ''}', 'Mon évolution', photoUrl: url);
    ref.invalidate(journalProvider(pid));
  }

  void _pickDoc() async {
    final res = await FilePicker.platform.pickFiles(withData: true, type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
    if (res == null) return;
    final f = res.files.first;
    if (f.bytes == null) return;

    final bytes = f.bytes!;
    final uid = pid ?? Supabase.instance.client.auth.currentUser!.id;
    final path = 'docs/$uid/${DateTime.now().millisecondsSinceEpoch}_${f.name}';
    await Supabase.instance.client.storage.from('pregnancy_photos').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${f.name} téléchargé', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
  }

  void _addConsultation() async {
    final t = TextEditingController();
    final d = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Nouvelle Consultation'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: t, decoration: const InputDecoration(labelText: 'Titre (ex: Echo T1)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: d, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()))
                ]),
                actions: [
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: ThixSanteColors.primary),
                      onPressed: () async {
                        await ref.read(grossesseServiceProvider).addConsultation(pid, t.text, d.text);
                        ref.invalidate(grossesseRecordsProvider(pid));
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('Enregistrer', style: TextStyle(color: Colors.white)))
                ]));
  }

  void _toggleContraction() async {
    if (_cTimer == null) {
      _cSec = 0;
      _cTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _cSec++);
      });
    } else {
      _cTimer?.cancel();
      _cTimer = null;
      final inter = _lastC == null ? 0 : DateTime.now().difference(_lastC!).inSeconds;
      final sec = _cSec;
      setState(() => _cSec = 0);
      _lastC = DateTime.now();
      await ref.read(grossesseServiceProvider).addContraction(pid, sec, inter);
      ref.invalidate(contractionsProvider(pid));
    }
  }

  Future<void> _exportPdf() async {
    final profile = ref.read(grossesseProfileProvider(pid)).value;
    if (profile == null) return;
    final vitals = ref.read(vitalsProvider(pid)).value ?? [];
    final doc = pw.Document();
    doc.addPage(pw.Page(
        build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Dossier de Suivi de Grossesse', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('DPA (Date Prévue d\'Accouchement) : ${profile.dpa.toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 16)),
              pw.Divider(),
              pw.Text('Historique des Constantes (Vitals)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...vitals.map((v) => pw.Text('${v.createdAt.toString().substring(0, 10)} - ${v.type.toUpperCase()}: ${v.value}'))
            ])));
    await Printing.layoutPdf(onLayout: (f) => doc.save(), name: 'Dossier_Grossesse.pdf');
  }
}

// Widget utilitaire pour l'onglet urgences
class _UrgenceItem extends StatelessWidget {
  final String title;
  final String desc;
  const _UrgenceItem(this.title, this.desc);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
              Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ))
        ],
      ),
    );
  }
}
