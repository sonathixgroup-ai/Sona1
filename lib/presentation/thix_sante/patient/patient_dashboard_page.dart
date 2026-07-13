// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/thix_sante_colors.dart';
// Imports des pages Patient
import 'screens/consulter_medecin_page.dart';
import 'screens/dossier_famille_page.dart';
import 'screens/dossier_medical_page.dart';
import 'screens/mes_ordonnances_page.dart';
import 'screens/mon_medecin_traitant_page.dart';
import 'screens/resultats_examens_page.dart';
import 'screens/second_avis_page.dart';
import 'screens/prendre_rdv_page.dart';
import 'screens/trouver_hopital_page.dart';
import 'screens/pharmacies_proches_page.dart';
import 'screens/trouver_medicament_page.dart';
import 'screens/urgences_proches_page.dart';
// Imports des pages Santé
import '../sante/screens/sante_enfants_page.dart';
import '../sante/screens/carnet_vaccination_page.dart';
import '../sante/screens/suivi_grossesse_page.dart';

// =============================================================================
// PROVIDERS (100% Supabase, Zéro Mock-up)
// =============================================================================

final patientProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser?.id;
  if (uid == null) return {'full_name': 'Patient'};
  
  try {
    return await db.from('profiles').select('full_name, avatar_url').eq('uid', uid).single();
  } catch (_) {
    return {'full_name': 'Patient'};
  }
});

class DashboardStats {
  final int consultations;
  final int examens;
  final int medicamentsEnCours;
  final int rendezVousAVenir;
  const DashboardStats({required this.consultations, required this.examens, required this.medicamentsEnCours, required this.rendezVousAVenir});
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = Supabase.instance.client;
  final uid = db.auth.currentUser?.id;
  if (uid == null) return const DashboardStats(consultations: 0, examens: 0, medicamentsEnCours: 0, rendezVousAVenir: 0);
  
  try {
    final consult = await db.from('consultations').select('id').eq('patient_uid', uid);
    final exams = await db.from('health_records').select('id').eq('patient_uid', uid).eq('type', 'laboratoire');
    final meds = await db.from('prescriptions').select('id').eq('patient_uid', uid).neq('status', 'delivree');
    final rdvs = await db.from('appointments').select('id').eq('patient_uid', uid).gte('date', DateTime.now().toIso8601String());
    
    return DashboardStats(
      consultations: (consult as List).length,
      examens: (exams as List).length,
      medicamentsEnCours: (meds as List).length,
      rendezVousAVenir: (rdvs as List).length,
    );
  } catch (_) {
    return const DashboardStats(consultations: 0, examens: 0, medicamentsEnCours: 0, rendezVousAVenir: 0);
  }
});

// =============================================================================
// INTERFACE PREMIUM
// =============================================================================

class PatientDashboardPage extends ConsumerWidget {
  const PatientDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final profileAsync = ref.watch(patientProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, profileAsync),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(child: _buildHero(context, profileAsync)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _buildStats(statsAsync)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: _buildServicesRapides(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: _buildServicesSante(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: _buildSOS(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AsyncValue<Map<String, dynamic>> profileAsync) {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: ThixSanteColors.ink, size: 28),
        onPressed: () {}, // Action menu
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ThixSanteColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: ThixSanteColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('THIX ID', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5, color: ThixSanteColors.ink)),
            ],
          ),
          const Text('Votre santé, notre priorité', style: TextStyle(fontSize: 12, color: ThixSanteColors.muted, fontWeight: FontWeight.w500)),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: ThixSanteColors.ink, size: 28),
                onPressed: () {}, // Action notifications
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: ThixSanteColors.danger, shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF8FAFC), width: 2)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: profileAsync.when(
            data: (profile) => CircleAvatar(
              radius: 20,
              backgroundColor: ThixSanteColors.primaryLight,
              backgroundImage: profile['avatar_url'] != null ? NetworkImage(profile['avatar_url']) : null,
              child: profile['avatar_url'] == null ? Text(profile['full_name'][0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: ThixSanteColors.primary)) : null,
            ),
            loading: () => const CircleAvatar(radius: 20, backgroundColor: ThixSanteColors.borderLight),
            error: (_, __) => const CircleAvatar(radius: 20, backgroundColor: ThixSanteColors.borderLight, child: Icon(Icons.person, color: ThixSanteColors.muted)),
          ),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, AsyncValue<Map<String, dynamic>> profileAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              profileAsync.when(
                data: (profile) {
                  final name = profile['full_name']?.split(' ')[0] ?? 'Patient';
                  return Text('Bonjour, $name 👋', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600));
                },
                loading: () => const Text('Chargement...', style: TextStyle(color: Colors.white70)),
                error: (_, __) => const Text('Bonjour 👋', style: TextStyle(color: Colors.white70)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text('Vérifié', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Votre santé\nentre de bonnes mains', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ThixSanteColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DossierMedicalPage())),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_special_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Mon Dossier Santé', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AsyncValue<DashboardStats> statsAsync) {
    return statsAsync.when(
      data: (s) => SizedBox(
        height: 90,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          children: [
            _statCard(icon: Icons.monitor_heart_rounded, value: '${s.consultations}', label: 'Consultations', color: const Color(0xFFEFF6FF), iconColor: const Color(0xFF3B82F6)),
            _statCard(icon: Icons.science_rounded, value: '${s.examens}', label: 'Examens', color: const Color(0xFFF0FDF4), iconColor: const Color(0xFF22C55E)),
            _statCard(icon: Icons.medication_rounded, value: '${s.medicamentsEnCours}', label: 'Médicaments', color: const Color(0xFFFAF5FF), iconColor: const Color(0xFFA855F7)),
            _statCard(icon: Icons.event_available_rounded, value: '${s.rendezVousAVenir}', label: 'À venir', color: const Color(0xFFFFF7ED), iconColor: const Color(0xFFF97316)),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 90, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _statCard({required IconData icon, required String value, required String label, required Color color, required Color iconColor}) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: ThixSanteColors.ink.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 18)),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: iconColor)),
            ],
          ),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ThixSanteColors.inkLight)),
        ],
      ),
    );
  }

  Widget _buildServicesRapides(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'l': 'Consulter', 'i': Icons.medical_services_rounded, 'c': const Color(0xFF3B82F6), 'p': const ConsulterMedecinPage()},
      {'l': 'Dossier', 'i': Icons.folder_shared_rounded, 'c': const Color(0xFF6366F1), 'p': const DossierMedicalPage()},
      {'l': 'Famille', 'i': Icons.family_restroom_rounded, 'c': const Color(0xFFEC4899), 'p': const DossierFamillePage(), 'n': true},
      {'l': 'Résultats', 'i': Icons.biotech_rounded, 'c': const Color(0xFF10B981), 'p': const ResultatsExamensPage()},
      {'l': 'Médecin', 'i': Icons.person_add_alt_1_rounded, 'c': const Color(0xFF06B6D4), 'p': const MonMedecinTraitantPage(), 'n': true},
      {'l': 'Ordonnances', 'i': Icons.receipt_long_rounded, 'c': const Color(0xFF8B5CF6), 'p': const MesOrdonnancesPage()},
      {'l': 'Second Avis', 'i': Icons.people_alt_rounded, 'c': const Color(0xFFF59E0B), 'p': const SecondAvisPage(), 'n': true},
      {'l': 'RDV', 'i': Icons.edit_calendar_rounded, 'c': const Color(0xFF14B8A6), 'p': const PrendreRdvPage()},
      {'l': 'Hôpital', 'i': Icons.local_hospital_rounded, 'c': const Color(0xFFEF4444), 'p': const TrouverHopitalPage()},
      {'l': 'Pharmacie', 'i': Icons.local_pharmacy_rounded, 'c': const Color(0xFF22C55E), 'p': const PharmaciesProchesPage()},
      {'l': 'Médicaments', 'i': Icons.medication_liquid_rounded, 'c': const Color(0xFF6366F1), 'p': const TrouverMedicamentPage()},
      {'l': 'Urgences', 'i': Icons.emergency_rounded, 'c': const Color(0xFFEF4444), 'p': const UrgencesProchesPage()},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('Services Rapides', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ThixSanteColors.ink, letterSpacing: -0.5)),
              const Spacer(),
              InkWell(onTap: () {}, child: const Text('Tout voir', style: TextStyle(color: ThixSanteColors.primary, fontSize: 13, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 16),
            itemCount: items.length,
            itemBuilder: (c, i) {
              final it = items[i];
              return InkWell(
                onTap: () {
                  if (it['p'] != null) {
                    Navigator.push(c, MaterialPageRoute(builder: (_) => it['p'] as Widget));
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: (it['c'] as Color).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]),
                          child: Icon(it['i'] as IconData, color: it['c'] as Color, size: 24),
                        ),
                        const SizedBox(height: 8),
                        Text(it['l'] as String, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ThixSanteColors.ink)),
                      ],
                    ),
                    if (it['n'] == true)
                      Positioned(
                        top: -4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: ThixSanteColors.danger, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)),
                          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSante(BuildContext context) {
    final List<Map<String, dynamic>> sante = [
      {'l': 'Enfants', 'i': Icons.child_care_rounded, 'c': const Color(0xFFF59E0B), 'p': const SanteEnfantsPage()},
      {'l': 'Vaccins', 'i': Icons.vaccines_rounded, 'c': const Color(0xFF10B981), 'p': const CarnetVaccinationPage()},
      {'l': 'Grossesse', 'i': Icons.pregnant_woman_rounded, 'c': const Color(0xFFEC4899), 'p': const SuiviGrossessePage()},
      {'l': 'Nutrition', 'i': Icons.restaurant_menu_rounded, 'c': const Color(0xFF84CC16), 'p': null},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text('Parcours Santé', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: ThixSanteColors.ink, letterSpacing: -0.5)),
              const Spacer(),
              InkWell(onTap: () {}, child: const Text('Tout voir', style: TextStyle(color: ThixSanteColors.primary, fontSize: 13, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: sante.map((it) => GestureDetector(
              onTap: () {
                if (it['p'] != null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => it['p'] as Widget));
                }
              },
              child: Container(
                width: 78,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: ThixSanteColors.borderLight)),
                child: Column(
                  children: [
                    Icon(it['i'] as IconData, color: it['c'] as Color, size: 28),
                    const SizedBox(height: 8),
                    Text(it['l'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ThixSanteColors.inkLight)),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSOS(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UrgencesProchesPage()));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('SOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: ThixSanteColors.danger))),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Urgence Médicale ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Appelez immédiatement les secours', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
