// lib/presentation/mon_pays/mon_pays_page.dart
// Page d'accueil du module Mon Pays — Espace Citoyen RDC

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'sections/authorities_section.dart';
import 'sections/header_section.dart';
import 'admin/admin_authorities_page.dart';

class MonPaysPage extends ConsumerWidget {
  const MonPaysPage({super.key});

  // ─── Charte institutionnelle ──────────────────────────────────
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ivory,
      body: CustomScrollView(
        slivers: [
          _buildInstitutionalHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // ─── 1. Bannière "Espace Citoyen" ─────────────
                  _buildHeroBanner(),
                  const SizedBox(height: 20),
                  // ─── 2. Les Autorités (FONCTIONNEL) ────────────
                  const AuthoritiesSection(),
                  const SizedBox(height: 16),
                  // ─── Voir toutes les autorités ──────────────────
                  _buildSeeAllButton(context),
                  const SizedBox(height: 24),
                  // ─── 3. Figures Historiques ─────────────────────
                  _buildHistoricalFiguresSection(context),
                  const SizedBox(height: 24),
                  // ─── 4. À la Une ────────────────────────────────
                  _buildNewsSection(context),
                  const SizedBox(height: 24),
                  // ─── 5. Agences & Institutions ──────────────────
                  _buildAgenciesSection(context),
                  const SizedBox(height: 24),
                  // ─── 6. Accès rapides ──────────────────────────
                  _buildQuickAccessRow(context),
                  const SizedBox(height: 20),
                  // ─── 7. Citoyens Exemplaires ────────────────────
                  _buildCitizensBanner(context),
                  const SizedBox(height: 20),
                  // ─── 8. Alertes ──────────────────────────────────
                  _buildAlertRow(context),
                  const SizedBox(height: 20),
                  // ─── 9. Tous les modules ────────────────────────
                  _buildModulesGrid(context),
                  const SizedBox(height: 30),
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
  // HEADER INSTITUTIONNEL
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
          _headerIconButton(Icons.search_rounded, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recherche globale - En développement')),
            );
          }),
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
            onTap: () {
              // ✅ ADMIN - FONCTIONNEL
              context.push('/mon-pays/admin');
            },
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
  // 1. BANNIÈRE "ESPACE CITOYEN"
  // ============================================================
  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [navyDeep, navy, primaryBlue],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: const Row(
        children: [
          Icon(Icons.star_rounded, color: gold, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Espace Citoyen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                ),
                Text(
                  "S'informer • Comprendre • Participer • Construire",
                  style: TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTON "VOIR TOUTES LES AUTORITÉS"
  // ============================================================
  Widget _buildSeeAllButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // ✅ AUTORITÉS - FONCTIONNEL
        context.push('/mon-pays/authorities');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Voir toutes les autorités',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A5276),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Color(0xFF1A5276)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 2. FIGURES HISTORIQUES
  // ============================================================
  Widget _buildHistoricalFiguresSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📜 Figures Historiques', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText)),
            _buildComingSoonButton(context, 'Explorer →'),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: hairline, width: 1.4),
                  color: navy.withOpacity(0.08),
                ),
                child: const Center(
                  child: Icon(Icons.person_rounded, color: navy, size: 24),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        const Text('Découvrez ceux qui ont marqué notre histoire.', style: TextStyle(fontSize: 9.5, color: mutedText, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ============================================================
  // 3. À LA UNE
  // ============================================================
  Widget _buildNewsSection(BuildContext context) {
    final List<Map<String, String>> news = [
      {'tag': 'OFFICIEL', 'date': '27 Mai 2025', 'title': 'Inauguration du Pont Maréchal à Kinshasa', 'excerpt': 'Un nouvel ouvrage pour renforcer la mobilité et le développement.'},
      {'tag': 'COMMUNIQUÉ', 'date': '25 Mai 2025', 'title': 'Conseil des Ministres : Principales décisions', 'excerpt': 'Résumé des décisions prises lors du dernier conseil des ministres.'},
      {'tag': 'NATIONAL', 'date': '23 Mai 2025', 'title': "Réforme de l'éducation : cap sur la qualité", 'excerpt': "Le Gouvernement réaffirme son engagement pour l'avenir des jeunes."},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📰 À la Une', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText)),
            _buildComingSoonButton(context, 'Voir toutes →'),
          ],
        ),
        const SizedBox(height: 10),
        ...news.take(2).map((n) => Padding(
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
    );
  }

  // ============================================================
  // 4. AGENCES & INSTITUTIONS
  // ============================================================
  Widget _buildAgenciesSection(BuildContext context) {
    final List<Map<String, dynamic>> agencies = [
      {'icon': Icons.account_balance_rounded, 'label': 'Présidence'},
      {'icon': Icons.flag_rounded, 'label': 'Gouvernement'},
      {'icon': Icons.gavel_rounded, 'label': 'Parlement'},
      {'icon': Icons.work_rounded, 'label': 'Ministères'},
      {'icon': Icons.location_on_rounded, 'label': 'Provinces'},
      {'icon': Icons.apartment_rounded, 'label': 'Entreprises Publiques'},
      {'icon': Icons.shield_rounded, 'label': 'FARDC'},
      {'icon': Icons.local_police_rounded, 'label': 'PNC'},
      {'icon': Icons.scale_rounded, 'label': 'Cour Constitutionnelle'},
      {'icon': Icons.gavel_rounded, 'label': 'CSM'},
      {'icon': Icons.how_to_vote_rounded, 'label': 'CENI'},
      {'icon': Icons.people_rounded, 'label': 'Gouverneurs'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🏢 Agences & Institutions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText)),
            _buildComingSoonButton(context, 'Explorer →'),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.9,
          ),
          itemCount: agencies.length,
          itemBuilder: (context, index) {
            final ag = agencies[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _showComingSoon(context);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: hairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(ag['icon'] as IconData, color: navy, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      ag['label'] as String,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: darkText),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // 5. ACCÈS RAPIDES
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
              _showComingSoon(context);
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
  // 6. CITOYENS EXEMPLAIRES
  // ============================================================
  Widget _buildCitizensBanner(BuildContext context) {
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
          InkWell(
            onTap: () {
              _showComingSoon(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
              child: const Text('Découvrir', style: TextStyle(color: navyDeep, fontWeight: FontWeight.w800, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 7. ALERTES
  // ============================================================
  Widget _buildAlertRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              _showComingSoon(context);
            },
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
            onTap: () {
              _showComingSoon(context);
            },
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
  // 8. TOUS LES MODULES (grille complète)
  // ============================================================
  Widget _buildModulesGrid(BuildContext context) {
    final modules = [
      {'icon': Icons.account_balance_rounded, 'label': 'Autorités', 'active': true},
      {'icon': Icons.history_edu_rounded, 'label': 'Figures Historiques', 'active': false},
      {'icon': Icons.newspaper_rounded, 'label': 'À la Une', 'active': false},
      {'icon': Icons.business_rounded, 'label': 'Agences & Institutions', 'active': false},
      {'icon': Icons.video_library_rounded, 'label': 'Vidéos Officielles', 'active': false},
      {'icon': Icons.library_books_rounded, 'label': 'Documentaires', 'active': false},
      {'icon': Icons.people_alt_rounded, 'label': 'Citoyens Exemplaires', 'active': false},
      {'icon': Icons.gavel_rounded, 'label': 'Valeurs & Lois', 'active': false},
      {'icon': Icons.record_voice_over_rounded, 'label': 'Participer', 'active': false},
      {'icon': Icons.warning_rounded, 'label': 'Personnes recherchées', 'active': false},
      {'icon': Icons.search_rounded, 'label': 'Recherche globale', 'active': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tous les modules', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: darkText)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: modules.map((module) {
            final isActive = module['active'] as bool;
            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isActive
                  ? () {
                      // ✅ AUTORITÉS - FONCTIONNEL
                      context.push('/mon-pays/authorities');
                    }
                  : () {
                      _showComingSoon(context);
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive ? gold : hairline,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: navyDeep.withOpacity(isActive ? 0.08 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive ? gold.withOpacity(0.15) : ivory,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive ? gold : Colors.grey.shade300,
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        module['icon'] as IconData,
                        color: isActive ? navy : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        module['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? darkText : Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'ACTIF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGETS UTILITAIRES
  // ============================================================
  Widget _buildComingSoonButton(BuildContext context, String label) {
    return InkWell(
      onTap: () => _showComingSoon(context),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, fontSize: 11)),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500, size: 14),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Module en cours de développement'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ============================================================
  // BOTTOM NAV
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
            const SizedBox(width: 44),
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
      onTap: () {
        // Navigation vers les pages correspondantes
        if (label == 'Accueil') {
          context.push('/');
        } else if (label == 'Mon Pays') {
          context.push('/mon-pays');
        } else if (label == 'Services') {
          // TODO: Navigation vers Services
          _showComingSoon(context);
        } else if (label == 'Mon Compte') {
          // TODO: Navigation vers Mon Compte
          _showComingSoon(context);
        }
      },
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
