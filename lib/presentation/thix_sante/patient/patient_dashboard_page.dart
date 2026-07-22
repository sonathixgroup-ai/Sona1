// lib/presentation/thix_sante/patient/patient_dashboard_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports des pages (assure-toi que les chemins sont corrects)
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

// Modele pour les statistiques réelles
class DashboardStats {
  final int consultations, examens, medicaments, rdvs;
  const DashboardStats({this.consultations = 0, this.examens = 0, this.medicaments = 0, this.rdvs = 0});
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

// Modèle de service pour la grille unifiée
class ServiceItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  ServiceItem(this.title, this.icon, this.color, this.page);
}

class PatientDashboardPage extends ConsumerStatefulWidget {
  const PatientDashboardPage({super.key});
  @override
  ConsumerState<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends ConsumerState<PatientDashboardPage> {
  final PageController _heroCtrl = PageController();
  int _heroIndex = 0;
  Timer? _timer;

  // Liste UNIQUE de tous les services (sans doublons)
  // L'Assistant IA est en première position
  final List<ServiceItem> _allServices = [
    ServiceItem('Assistant IA', Icons.auto_awesome_rounded, const Color(0xFF8B5CF6), const AssistantIAPage()),
    ServiceItem('Téléconsult', Icons.videocam_rounded, const Color(0xFF2563EB), const TeleconsultationPage()),
    ServiceItem('Rendez-vous', Icons.calendar_month_rounded, const Color(0xFF0284C7), const PrendreRdvPage()),
    ServiceItem('Urgences', Icons.emergency_rounded, const Color(0xFFEF4444), const UrgencesProchesPage()),
    
    ServiceItem('Dossier Médical', Icons.folder_shared_rounded, const Color(0xFF16A34A), const DossierMedicalPage()),
    ServiceItem('Ordonnances', Icons.receipt_long_rounded, const Color(0xFFF59E0B), const MesOrdonnancesPage()),
    ServiceItem('Résultats', Icons.biotech_rounded, const Color(0xFF7C3AED), const ResultatsExamensPage()),
    ServiceItem('Vaccination', Icons.vaccines_rounded, const Color(0xFF06B6D4), const CarnetVaccinationPage()),
    
    ServiceItem('Pharmacies', Icons.local_pharmacy_rounded, const Color(0xFF10B981), const PharmaciesProchesPage()),
    ServiceItem('Hôpitaux', Icons.local_hospital_rounded, const Color(0xFFDC2626), const TrouverHopitalPage()),
    ServiceItem('Médicaments', Icons.medication_rounded, const Color(0xFF059669), const TrouverMedicamentPage()),
    ServiceItem('Consulter', Icons.medical_services_rounded, const Color(0xFF2563EB), const ConsulterMedecinPage()),
    
    ServiceItem('Mon Médecin', Icons.person_rounded, const Color(0xFF475569), const MonMedecinTraitantPage()),
    ServiceItem('Second Avis', Icons.people_alt_rounded, const Color(0xFFEA580C), const SecondAvisPage()),
    ServiceItem('Assurance', Icons.shield_rounded, const Color(0xFF3B82F6), const AssuranceSantePage()),
    ServiceItem('Don de sang', Icons.bloodtype_rounded, const Color(0xFFE11D48), const DonSangPage()),

    ServiceItem('Grossesse', Icons.pregnant_woman_rounded, const Color(0xFFEC4899), const SuiviGrossessePage()),
    ServiceItem('Enfants', Icons.child_care_rounded, const Color(0xFF0EA5E9), const SanteEnfantsPage()),
    ServiceItem('Famille', Icons.family_restroom_rounded, const Color(0xFF8B5CF6), const DossierFamillePage()),
    ServiceItem('Nutrition', Icons.restaurant_rounded, const Color(0xFF84CC16), const NutritionPage()),

    ServiceItem('Santé Mentale', Icons.psychology_rounded, const Color(0xFF9333EA), const BienEtreMentalPage()),
    ServiceItem('Prédictions', Icons.query_stats_rounded, const Color(0xFF6366F1), const AnalysePredictivePage()),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_heroCtrl.hasClients) return;
      _heroIndex = (_heroIndex + 1) % 4;
      _heroCtrl.animateToPage(_heroIndex, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
    });
  }

  @override
  void dispose() { 
    _timer?.cancel(); 
    _heroCtrl.dispose(); 
    super.dispose(); 
  }

  void _go(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond gris très clair ultra pro
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _appBar(),
            SliverToBoxAdapter(child: const SizedBox(height: 10)),
            SliverToBoxAdapter(child: _heroCarousel()),
            SliverToBoxAdapter(child: const SizedBox(height: 20)),
            
            // Section Statistiques
            SliverToBoxAdapter(child: _sectionTitle('Mon Suivi')),
            SliverToBoxAdapter(child: _resumeCards(stats)),
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            
            // Grille unifiée de TOUS les services
            SliverToBoxAdapter(child: _sectionTitle('Tous les services')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75, // Ajusté pour Icone + Texte
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _serviceGridItem(_allServices[index]),
                  childCount: _allServices.length,
                ),
              ),
            ),
            
            SliverToBoxAdapter(child: const SizedBox(height: 24)),
            SliverToBoxAdapter(child: _sosBanner()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------- APPBAR ----------
  Widget _appBar() => SliverAppBar(
    floating: true,
    backgroundColor: const Color(0xFFF8FAFC),
    elevation: 0,
    toolbarHeight: 64,
    leadingWidth: 60,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Icon(Icons.grid_view_rounded, color: Color(0xFF0F172A), size: 20),
        ),
      ),
    ),
    title: Row(children:[
      Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(colors:[Color(0xFF2563EB), Color(0xFF059669)]),
        ),
        child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 18),
      ),
      const SizedBox(width: 8),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[
          Text('THIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A), letterSpacing: -0.5)), 
          Text(' SANTÉ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669), letterSpacing: -0.5))
        ]),
        Text('Votre santé, notre priorité', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ])
    ]),
    actions: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Stack(children:[
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 22), onPressed: (){}),
          Positioned(top: 8, right: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
        ]),
      ),
      const SizedBox(width: 16),
    ],
  );

  // ---------- HERO BANNERS (Médecins Africains) ----------
  Widget _heroCarousel() {
    final banners = [
      {'t1':'Votre santé','t2':'entre de bonnes mains','sub':'Consultez et suivez votre santé.','btn':'Mon Dossier','img':'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?q=80&w=500'}, // Medecin homme noir
      {'t1':'Téléconsultation','t2':'24h/24 et 7j/7','sub':'Parlez à un médecin certifié.','btn':'Consulter','img':'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=500'}, // Femme medecin noire
      {'t1':'Urgences &','t2':'Interventions','sub':'Localisez l\'hôpital le plus proche.','btn':'Urgences','img':'https://images.unsplash.com/photo-1537368910025-700350fe46c7?q=80&w=500'}, // Medecin noir souriant
      {'t1':'Pharmacie','t2':'à proximité','sub':'Trouvez vos médicaments vitaux.','btn':'Chercher','img':'https://images.unsplash.com/photo-1594824436998-058a23116fc7?q=80&w=500'}, // Infirmiere/Docteur
    ];
    
    return Column(children:[
      SizedBox(
        height: 170,
        child: PageView.builder(
          controller: _heroCtrl,
          onPageChanged: (i) => setState(() => _heroIndex = i),
          itemCount: 4,
          itemBuilder: (_, i) {
            final b = banners[i];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1E293B),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children:[
                Positioned(
                  right: 0, bottom: 0, top: 0,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.black]
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.network(b['img']!, width: 180, fit: BoxFit.cover),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [const Color(0xFF0F172A).withOpacity(0.95), Colors.transparent],
                      stops: const [0.4, 1.0]
                    )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 140, 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children:[
                    Text('${b['t1']}\n${b['t2']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18, height: 1.15)),
                    const SizedBox(height: 6),
                    Text(b['sub']!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 10, height: 1.3)),
                    const Spacer(),
                    InkWell(
                      onTap: () => _go(const DossierMedicalPage()), // A adapter selon le banner
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(8)),
                        child: Text(b['btn']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.white)),
                      ),
                    )
                  ]),
                )
              ]),
            );
          },
        ),
      ),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: _heroIndex == i ? 18 : 6, height: 6,
        decoration: BoxDecoration(
          color: _heroIndex == i ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), 
          borderRadius: BorderRadius.circular(10)
        ),
      ))),
    ]);
  }

  // ---------- EN-TÊTE DE SECTION ----------
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A), letterSpacing: -0.3)),
  );

  // ---------- RÉSUMÉ (VRAIES DONNÉES UNIQUEMENT) ----------
  Widget _resumeCards(AsyncValue<DashboardStats> s) {
    return s.when(
      data: (d) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children:[
          _statCard('Consults.', d.consultations.toString(), Icons.medical_services_rounded, const Color(0xFF2563EB)),
          _statCard('Examens', d.examens.toString(), Icons.biotech_rounded, const Color(0xFF059669)),
          _statCard('Traitements', d.medicaments.toString(), Icons.medication_rounded, const Color(0xFF7C3AED)),
          _statCard('RDV', d.rdvs.toString(), Icons.event_rounded, const Color(0xFFEA580C)),
        ]),
      ),
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _statCard(String title, String val, IconData icon, Color c) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)]
        ),
        child: Column(children:[
          Icon(icon, size: 18, color: c),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ]),
      )
    );
  }

  // ---------- GRILLE DES SERVICES (4 COLONNES) ----------
  Widget _serviceGridItem(ServiceItem item) {
    return InkWell(
      onTap: () => _go(item.page),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.color.withOpacity(0.15)),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BANNIÈRE URGENCE (FONCTIONNELLE, SANS MOCKUP DONNEES) ----------
  Widget _sosBanner() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2), 
      borderRadius: BorderRadius.circular(16), 
      border: Border.all(color: const Color(0xFFFECDD3))
    ),
    child: Row(children:[
      Container(
        width: 44, height: 44, 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), 
        child: const Icon(Icons.local_shipping_rounded, color: Color(0xFFEF4444))
      ),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Text('Urgence Médicale ?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF991B1B))),
        SizedBox(height: 2),
        Text('Appelez les secours immédiatement.', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
      ])),
      ElevatedButton(
        onPressed: (){ /* Action Appel */ }, 
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444), 
          foregroundColor: Colors.white, 
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0), 
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
        ),
        child: const Text('Appeler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  // ---------- NAVIGATION BOTTOM (ULTRA CLEAN) ----------
  Widget _bottomNav() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    child: SizedBox(
      height: 60,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children:[
        _nav(Icons.home_rounded, 'Accueil', true),
        _nav(Icons.folder_shared_rounded, 'Dossier', false),
        
        // Bouton Central Flottant style
        InkWell(
          onTap: (){},
          child: Container(
            width: 44, height: 44, 
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB), 
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
            ), 
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20)
          ),
        ),
        
        _nav(Icons.chat_bubble_rounded, 'Messages', false),
        _nav(Icons.person_rounded, 'Profil', false),
      ]),
    ),
  );

  Widget _nav(IconData i, String l, bool active) => InkWell(
    onTap: (){},
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(mainAxisSize: MainAxisSize.min, children:[
        Icon(i, color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), size: 22),
        const SizedBox(height: 4),
        Text(l, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w600, color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8))),
      ]),
    ),
  );
}
