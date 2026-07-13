// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_routes.dart';
import '../core/thix_sante_colors.dart';

// STATS
class DashboardStats {
  final int consultations, examens, medicaments, rdvs;
  const DashboardStats({this.consultations=0,this.examens=0,this.medicaments=0,this.rdvs=0});
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser?.id;
  if (uid == null) return const DashboardStats();
  try {
    final c = await db.from('health_links').select('id').eq('patient_id', uid);
    final e = await db.from('health_records').select('id').eq('patient_id', uid);
    final p = await db.from('prescriptions').select('id').eq('patient_id', uid).neq('status', 'delivree');
    final r = await db.from('appointments').select('id').eq('patient_id', uid).gte('date_rdv', DateTime.now().toIso8601String());
    return DashboardStats(
      consultations: (c as List).length,
      examens: (e as List).length,
      medicaments: (p as List).length,
      rdvs: (r as List).length,
    );
  } catch (_) {
    return const DashboardStats();
  }
});

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _appBar(context),
            SliverToBoxAdapter(child: _hero(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _stats(stats)),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(child: _title(context, 'Services rapides', AppRoutes.santePlusServices)),
            SliverToBoxAdapter(child: _rapides(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(child: _title(context, 'Services sante', AppRoutes.santePlusServices)),
            SliverToBoxAdapter(child: _sante(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(child: _title(context, 'Pour vous', AppRoutes.santeAssistantIA)),
            SliverToBoxAdapter(child: _pourVous(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverToBoxAdapter(child: _sos(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context) => SliverAppBar(
        floating: true,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        title: Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: ThixSanteColors.primary, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('THIX SANTE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
            Text('Votre sante, notre priorite', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
          ])
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A)), onPressed: () => context.push(AppRoutes.santeAssistantIA)),
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(onTap: () => context.push('/profile'), child: const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=12'))))
        ],
      );

  Widget _hero(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF06B6D4)])),
        child: Row(children: [
          Expanded(
              flex: 3,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bonjour, vous', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('Votre sante\nentre de bonnes\nmains', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1)),
                const SizedBox(height: 10),
                const Text('Gerez tout depuis un seul endroit.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                Row(children: [
                  ElevatedButton(
                      onPressed: () => context.push(AppRoutes.santeDossierMedical),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: ThixSanteColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('Dossier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
                  const SizedBox(width: 10),
                  GestureDetector(
                      onTap: () => context.push(AppRoutes.santeAnalysePredictive),
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white30)),
                          child: const Text('Score 85%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
                ])
              ])),
          Expanded(
              flex: 2,
              child: Image.network('https://cdn3d.iconscout.com/3d/premium/thumb/doctor-3d-icon-download-in-png-blend-fbx-gltf-file-formats--medical-health-care-pack-medical-icons-5183886.png',
                  height: 130, errorBuilder: (_, __, ___) => const Icon(Icons.medical_services_rounded, color: Colors.white, size: 70))),
        ]),
      );

  Widget _stats(AsyncValue<DashboardStats> s) => s.when(
        data: (d) => SizedBox(
            height: 84,
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: [
              _stat('${d.consultations}', 'Consult.', 'Cette annee', const Color(0xFFDBEAFE)),
              _stat('${d.examens}', 'Examens', 'Completes', const Color(0xFFD1FAE5)),
              _stat('${d.medicaments}', 'Medicaments', 'En cours', const Color(0xFFEDE9FE)),
              _stat('${d.rdvs}', 'Rendez-vous', 'A venir', const Color(0xFFFFEDD5)),
            ])),
        loading: () => const SizedBox(height: 84, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const SizedBox(height: 84),
      );

  Widget _stat(String val, String l1, String l2, Color c) => Container(
      width: 118,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(11)), child: Center(child: Text(l1[0], style: const TextStyle(fontWeight: FontWeight.w800)))),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text(l1, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
          Text(l2, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)))
        ])
      ]));

  Widget _title(BuildContext context, String t, String route) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const Spacer(),
        InkWell(onTap: () => context.push(route), child: const Text('Voir tout >', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)))
      ]));

  Widget _rapides(BuildContext context) {
    final items = [
      ['Consulter\nmedecin', AppRoutes.santeConsulterMedecin, false],
      ['Dossier\nmedical', AppRoutes.santeDossierMedical, false],
      ['Resultats\nexamens', AppRoutes.santeResultatsExamens, false],
      ['Mes\nordonnances', AppRoutes.santeOrdonnances, false],
      ['Trouver\nhopital', AppRoutes.santeTrouverHopital, false],
      ['Trouver\nmedicament', AppRoutes.santeTrouverMedicament, false],
      ['Pharmacies\nproches', AppRoutes.santePharmaciesProches, false],
      ['Urgences\nproches', AppRoutes.santeUrgencesProches, false],
      ['Prendre\nRDV', AppRoutes.santePrendreRdv, false],
      ['Teleconsultation', AppRoutes.santeTeleconsultation, false],
      ['Assistant\nIA', AppRoutes.santeAssistantIA, false],
      ['Dossier\npartage', AppRoutes.santeDossierPartage, false],
      ['Epidemies', AppRoutes.santeEpidemies, false],
      ['Don de sang', AppRoutes.santeDonSang, false],
      ['Mon Medecin\nTraitant', AppRoutes.santeMonMedecinTraitant, true],
      ['Dossier\nFamille', AppRoutes.santeDossierFamille, true],
      ['Second Avis', AppRoutes.santeSecondAvis, true],
      ['Rappels\nvaccin', AppRoutes.santeRappelsVaccin, false],
      ['Certificat\nmedical', AppRoutes.santeCertificatMedical, false],
      ['Assurance\nsante', AppRoutes.santeAssurance, false],
    ];
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio:.88),
            itemCount: items.length,
            itemBuilder: (c, i) {
              final l = items[i][0] as String;
              final r = items[i][1] as String;
              final isNew = items[i][2] as bool;
              return InkWell(
                  onTap: () => context.push(r),
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(children: [
                    Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(l[0], style: const TextStyle(fontWeight: FontWeight.w800)))),
                          const SizedBox(height: 8),
                          Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, height: 1.15))
                        ])),
                    if (isNew)
                      Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(6)),
                              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900))))
                  ]));
            }));
  }

  Widget _sante(BuildContext context) {
    final sante = [
      [AppRoutes.santeEnfants, 'Sante\nenfants'],
      [AppRoutes.santeCarnetVaccination, 'Carnet\nvaccination'],
      [AppRoutes.santeSuiviGrossesse, 'Suivi\ngrossesse'],
      [AppRoutes.santeAnalysePredictive, 'Analyse\npredictive'],
      [AppRoutes.santeBienEtreMental, 'Bien-etre\nmental'],
      [AppRoutes.santeNutrition, 'Nutrition'],
      [AppRoutes.santeActivitePhysique, 'Activite\nphysique'],
      [AppRoutes.santeGestionStress, 'Gestion\nstress'],
      [AppRoutes.santeAssuranceSanteDetail, 'Assurance'],
      [AppRoutes.santePlusServices, 'Plus'],
    ];
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio:.9),
            itemCount: sante.length,
            itemBuilder: (c, i) {
              final r = sante[i][0] as String;
              final l = sante[i][1] as String;
              return InkWell(
                  onTap: () => context.push(r),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(l[0], style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(l, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600))
                      ])));
            }));
  }

  Widget _pourVous(BuildContext context) => SizedBox(
      height: 152,
      child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (c, i) => GestureDetector(
              onTap: () => context.push(AppRoutes.santeAssistantIA),
              child: Container(
                  width: 172,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Column(children: [
                    ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network('https://picsum.photos/300/150?random=$i', height: 86, width: 172, fit: BoxFit.cover)),
                    const Padding(padding: EdgeInsets.all(10), child: Text('5 conseils pour rester en bonne sante', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)))
                  ])))));

  Widget _sos(BuildContext context) => Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Center(child: Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFDC2626))))),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Urgence? Nous sommes la', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)), Text('Hopital le plus proche', style: TextStyle(color: Colors.white70, fontSize: 11))])),
        ElevatedButton(onPressed: () => context.push(AppRoutes.santeUrgencesProches), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), elevation: 0), child: const Text('Appeler', style: TextStyle(fontWeight: FontWeight.w800)))
      ]));
}
