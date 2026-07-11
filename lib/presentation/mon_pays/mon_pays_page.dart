// lib/presentation/mon_pays/mon_pays_page.dart
// Page d'accueil du module Mon Pays — Espace Citoyen RDC

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MonPaysPage extends ConsumerWidget {
  const MonPaysPage({super.key});

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Élite (Navy / Bleu / Or)
  // + accents drapeau RDC (bleu ciel / rouge / jaune) réservés aux
  //   éléments officiels (bannière, cocarde)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);
  static const Color rdcSkyBlue = Color(0xFF007FFF);
  static const Color rdcRed = Color(0xFFCE1021);

  // ─── Données provisoires (à connecter à Supabase) ───
  static const List<Map<String, String>> _authorities = [
    {'name': 'Félix-A. Tshisekedi', 'role': 'Président de la République', 'photo': ''},
    {'name': 'Judith Suminwa', 'role': 'Première Ministre', 'photo': ''},
    {'name': 'Sama Lukonde', 'role': 'Président du Sénat', 'photo': ''},
    {'name': 'Vital Kamerhe', 'role': "Président de l'AN", 'photo': ''},
  ];

  static const List<Map<String, String>> _historicalFigures = [
    {'name': 'Patrice Lumumba', 'photo': ''},
    {'name': 'Joseph Kasa-Vubu', 'photo': ''},
    {'name': 'Mobutu Sese Seko', 'photo': ''},
    {'name': 'Laurent-Désiré Kabila', 'photo': ''},
    {'name': 'Joseph Kabila', 'photo': ''},
  ];

  static const List<Map<String, String>> _news = [
    {
      'tag': 'OFFICIEL',
      'date': '27 Mai 2025',
      'title': 'Inauguration du Pont Maréchal à Kinshasa',
      'excerpt': 'Un nouvel ouvrage pour renforcer la mobilité et le développement.',
    },
    {
      'tag': 'COMMUNIQUÉ',
      'date': '25 Mai 2025',
      'title': 'Conseil des Ministres : Principales décisions',
      'excerpt': 'Résumé des décisions prises lors du dernier conseil des ministres.',
    },
    {
      'tag': 'NATIONAL',
      'date': '23 Mai 2025',
      'title': "Réforme de l'éducation : cap sur la qualité",
      'excerpt': "Le Gouvernement réaffirme son engagement pour l'avenir des jeunes.",
    },
  ];

  static const List<Map<String, dynamic>> _agencies = [
    {'icon': Icons.account_balance_rounded, 'label': 'Présidence'},
    {'icon': Icons.flag_rounded, 'label': 'Gouvernement'},
    {'icon': Icons.gavel_rounded, 'label': 'Parlement'},
    {'icon': Icons.work_rounded, 'label': 'Ministères'},
    {'icon': Icons.location_on_rounded, 'label': 'Provinces'},
    {'icon': Icons.apartment_rounded, 'label': 'Entreprises Publiques'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ivory,
      body: CustomScrollView(
        slivers: [
          _buildInstitutionalHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(),
                  const SizedBox(height: 20),
                  _buildTwoColumnRow(
                    left: _buildAuthoritiesCard(context),
                    right: _buildHistoricalFiguresCard(),
                  ),
                  const SizedBox(height: 14),
                  _buildTwoColumnRow(
                    left: _buildNewsCard(),
                    right: _buildAgenciesCard(),
                  ),
                  const SizedBox(height: 20),
                  _buildQuickAccessRow(context),
                  const SizedBox(height: 16),
                  _buildAlertRow(context),
                  const SizedBox(height: 20),
                  _buildCitizensBanner(),
                  const SizedBox(height: 26),
                  _buildModulesGrid(context),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ============================================================
  // HEADER INSTITUTIONNEL — drapeau RDC, blason, recherche, profil
  // ============================================================
  Widget _buildInstitutionalHeader(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: navyDeep,
      surfaceTintColor: navyDeep,
      toolbarHeight: 62,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          _headerIconButton(Icons.menu_rounded, () {}),
          const SizedBox(width: 10),
          // Cocarde drapeau RDC
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [rdcSkyBlue, rdcRed]),
              border: Border.all(color: gold, width: 1.4),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.star_rounded, size: 13, color: gold),
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'RÉPUBLIQUE DÉMOCRATIQUE\nDU CONGO',
              maxLines: 2,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1.25, letterSpacing: 0.3),
            ),
          ),
          _headerIconButton(Icons.search_rounded, () {}),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _headerIconButton(Icons.notifications_none_rounded, () {}),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text('3', textAlign: TextAlign.center, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: navyDeep)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.pushNamed('monPaysAdmin'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 1.4),
              ),
              child: const CircleAvatar(backgroundColor: navy, child: Icon(Icons.person_rounded, size: 15, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Icon(icon, size: 15, color: Colors.white),
      ),
    );
  }

  // ============================================================
  // BANNIÈRE HÉROS — "Espace Citoyen"
  // ============================================================
  Widget _buildHeroBanner() {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navyDeep, navy, primaryBlue],
        ),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(
        children: [
          // Diagonale façon drapeau RDC en filigrane
          Positioned(
            right: -30,
            bottom: -30,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 160,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [rdcRed, gold, rdcSkyBlue]),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Icon(Icons.star_rounded, color: gold.withOpacity(0.9), size: 26),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Espace Citoyen',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  "S'informer • Comprendre • Participer • Construire",
                  style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnRow({required Widget left, required Widget right}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String number, String title, {VoidCallback? onSeeAll, String seeAllLabel = 'Voir tout'}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(6)),
          child: Text(number, style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: darkText)),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(seeAllLabel, style: const TextStyle(color: navy, fontWeight: FontWeight.w700, fontSize: 10)),
                const Icon(Icons.chevron_right_rounded, size: 13, color: navy),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================
  // 1. LES AUTORITÉS
  // ============================================================
  Widget _buildAuthoritiesCard(BuildContext context) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('1', 'Les Autorités', onSeeAll: () => context.pushNamed('monPaysAuthorities')),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _authorities.length,
              itemBuilder: (context, index) {
                final a = _authorities[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: gold, width: 1.6),
                            color: ivory,
                          ),
                          child: const Icon(Icons.person_rounded, color: navy, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a['name']!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: darkText),
                        ),
                        Text(
                          a['role']!,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 7.5, color: mutedText, fontWeight: FontWeight.w500, height: 1.15),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. FIGURES HISTORIQUES — frise chronologique
  // ============================================================
  Widget _buildHistoricalFiguresCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('2', 'Figures Historiques', onSeeAll: () {}, seeAllLabel: 'Explorer'),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _historicalFigures.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: hairline, width: 1.4),
                      color: navy.withOpacity(0.08),
                    ),
                    child: const Icon(Icons.person_rounded, color: navy, size: 20),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Frise chronologique
          Row(
            children: List.generate(_historicalFigures.length, (i) {
              final active = i == 0;
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: active ? 9 : 6,
                      height: active ? 9 : 6,
                      decoration: BoxDecoration(color: active ? gold : hairline, shape: BoxShape.circle),
                    ),
                    if (i != _historicalFigures.length - 1)
                      Expanded(child: Container(height: 1.4, color: hairline)),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text(
            'Découvrez ceux qui ont marqué notre histoire.',
            style: TextStyle(fontSize: 9.5, color: mutedText, fontWeight: FontWeight.w500, height: 1.3),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 3. À LA UNE — actualités officielles
  // ============================================================
  Widget _buildNewsCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('3', 'À la Une', onSeeAll: () {}, seeAllLabel: 'Voir toutes'),
          const SizedBox(height: 12),
          ..._news.take(2).map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: navyDeep, borderRadius: BorderRadius.circular(6)),
                      child: Text(n['tag']!, style: const TextStyle(fontSize: 7, color: gold, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['title']!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: darkText, height: 1.25),
                          ),
                          const SizedBox(height: 2),
                          Text(n['date']!, style: const TextStyle(fontSize: 8.5, color: mutedText, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ============================================================
  // 4. AGENCES & INSTITUTIONS
  // ============================================================
  Widget _buildAgenciesCard() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('4', 'Agences & Institutions', onSeeAll: () {}, seeAllLabel: 'Explorer'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _agencies.length,
            itemBuilder: (context, index) {
              final ag = _agencies[index];
              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                    child: Icon(ag['icon'] as IconData, size: 15, color: navy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ag['label'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: darkText, height: 1.1),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCÈS RAPIDES — 5 raccourcis compacts
  // ============================================================
  Widget _buildQuickAccessRow(BuildContext context) {
    final items = [
      {'icon': Icons.video_library_rounded, 'label': 'Vidéos\nOfficielles', 'color': rdcRed},
      {'icon': Icons.folder_rounded, 'label': 'Documentaires\n& Archives', 'color': primaryBlue},
      {'icon': Icons.emoji_events_rounded, 'label': 'Citoyens\nExemplaires', 'color': gold},
      {'icon': Icons.balance_rounded, 'label': 'Valeurs\n& Lois', 'color': navy},
      {'icon': Icons.campaign_rounded, 'label': 'Participer\n& S\'exprimer', 'color': success},
    ];
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bientôt disponible')),
              );
            },
            child: Container(
              width: 84,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: pureWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hairline),
                boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                  const SizedBox(height: 7),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: darkText, height: 1.2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ALERTES — Personne recherchée / Recherche personnalisée
  // ============================================================
  Widget _buildAlertRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: danger.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: danger.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: danger, size: 20),
                  const SizedBox(height: 8),
                  const Text('Personne Recherchée', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: danger)),
                  const SizedBox(height: 3),
                  Text('Signaler ou rechercher une personne dangereuse.', style: TextStyle(fontSize: 8.5, color: darkText.withOpacity(0.7), fontWeight: FontWeight.w500, height: 1.3)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryBlue.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.travel_explore_rounded, color: navy, size: 20),
                  const SizedBox(height: 8),
                  const Text('Recherche Personnalisée', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: navy)),
                  const SizedBox(height: 3),
                  Text('Rechercher des informations ciblées et officielles.', style: TextStyle(fontSize: 8.5, color: darkText.withOpacity(0.7), fontWeight: FontWeight.w500, height: 1.3)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BANNIÈRE CITOYENS EXEMPLAIRES
  // ============================================================
  Widget _buildCitizensBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [navyDeep, navy]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: gold.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.emoji_events_rounded, color: gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Citoyens Exemplaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 3),
                Text('Ils bâtissent la RDC chaque jour par leurs actions.', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 9.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
            child: const Text('Découvrir', style: TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRILLE COMPLÈTE DES MODULES
  // ============================================================
  Widget _buildModulesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tous les modules', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.15,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _moduleCard(icon: Icons.account_balance_rounded, label: 'Autorités', onTap: () => context.pushNamed('monPaysAuthorities')),
            _moduleCard(icon: Icons.history_edu_rounded, label: 'Figures Historiques', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.newspaper_rounded, label: 'À la Une', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.business_rounded, label: 'Agences & Institutions', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.video_library_rounded, label: 'Vidéos Officielles', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.library_books_rounded, label: 'Documentaires', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.people_alt_rounded, label: 'Citoyens Exemplaires', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.gavel_rounded, label: 'Valeurs & Lois', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.record_voice_over_rounded, label: 'Participer', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.warning_rounded, label: 'Personnes recherchées', onTap: () => _soon(context)),
            _moduleCard(icon: Icons.search_rounded, label: 'Recherche globale', onTap: () => _soon(context)),
          ],
        ),
      ],
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bientôt disponible')),
    );
  }

  Widget _moduleCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: hairline),
          boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: ivory, shape: BoxShape.circle, border: Border.all(color: gold.withOpacity(0.4), width: 1.2)),
              child: Icon(icon, color: navy, size: 26),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: darkText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV — bouton central blason RDC
  // ============================================================
  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: pureWhite,
      elevation: 10,
      child: SizedBox(
        height: 62,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Accueil', true),
            _navItem(Icons.flag_rounded, 'Mon Pays', false),
            const SizedBox(width: 44), // espace pour le bouton central
            _navItem(Icons.apps_rounded, 'Services', false),
            _navItem(Icons.person_rounded, 'Mon Compte', false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: isSelected ? navy : mutedText),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8.5, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? navy : mutedText)),
          ],
        ),
      ),
    );
  }
}
