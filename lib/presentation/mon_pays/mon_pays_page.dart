// lib/presentation/mon_pays/mon_pays_page.dart
// Espace Citoyen — Page d'accueil du module Mon Pays

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ═══════════════════════════════════════════════════════════════
// IMPORTS CORRECTS POUR SUPABASE
// ═══════════════════════════════════════════════════════════════
import '../../providers/authorities_provider.dart';
import '../../providers/news_provider.dart';
import '../../models/authority.dart';
import '../../models/news.dart';
import '../../utils/helpers.dart';

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
    // ✅ Utilisation des providers avec le bon chemin
    final authoritiesAsync = ref.watch(authoritiesProvider(null));
    final newsAsync = ref.watch(newsProvider);

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
                  _buildHeroBannerWithNews(context, ref, newsAsync),
                  const SizedBox(height: 20),
                  _buildAuthoritiesSection(context, ref, authoritiesAsync),
                  const SizedBox(height: 24),
                  _buildAgenciesSection(context),
                  const SizedBox(height: 24),
                  _buildQuickAccessRow(context),
                  const SizedBox(height: 20),
                  _buildCitizensBanner(context),
                  const SizedBox(height: 20),
                  _buildHistoricalFiguresFull(context),
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
  // 1. BANNIÈRE "ESPACE CITOYEN" + À LA UNE
  // ============================================================
  Widget _buildHeroBannerWithNews(BuildContext context, WidgetRef ref, AsyncValue<List<News>> newsAsync) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
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
          const SizedBox(height: 12),
          newsAsync.when(
            loading: () => const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => const SizedBox(
              height: 100,
              child: Center(
                child: Text('Impossible de charger les actualités', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ),
            ),
            data: (news) {
              if (news.isEmpty) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Aucune actualité', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ),
                );
              }
              return SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: news.length,
                  itemBuilder: (context, index) {
                    final item = news[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: const TextStyle(color: navyDeep, fontSize: 6, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.date,
                                style: const TextStyle(color: Colors.white70, fontSize: 7, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          if (item.excerpt.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.excerpt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => context.pushNamed('monPaysNews'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Voir toutes', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w700)),
                  Icon(Icons.arrow_forward_ios, color: gold, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2. AUTORITÉS
  // ============================================================
  Widget _buildAuthoritiesSection(BuildContext context, WidgetRef ref, AsyncValue<List<Authority>> authoritiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('🏛 Les Autorités', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: darkText)),
            InkWell(
              onTap: () => context.pushNamed('monPaysAuthorities'),
              child: const Text('Voir tout →', style: TextStyle(color: navy, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        authoritiesAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(
            height: 180,
            child: Center(child: Text('Impossible de charger les autorités', style: TextStyle(color: danger, fontSize: 12))),
          ),
          data: (authorities) {
            if (authorities.isEmpty) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text('Aucune autorité enregistrée', style: TextStyle(color: mutedText, fontSize: 12))),
              );
            }
            final display = authorities.take(6).toList();
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: display.length,
                itemBuilder: (context, index) {
                  final a = display[index];
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: pureWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: hairline),
                      boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => context.pushNamed('monPaysAuthorityProfile', pathParameters: {'id': a.id}),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: gold, width: 2),
                              color: ivory,
                              image: a.imageUrl != null && a.imageUrl!.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(a.imageUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: a.imageUrl == null || a.imageUrl!.isEmpty
                                ? Center(
                                    child: Text(
                                      Helpers.getInitials(a.name),
                                      style: const TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 22),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: darkText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // 3. AGENCES & INSTITUTIONS
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
            InkWell(
              onTap: () => context.pushNamed('monPaysAgencies'),
              child: const Text('Explorer →', style: TextStyle(color: navy, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${ag['label']} - Bientôt disponible')),
                );
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
  // 4. ACCÈS RAPIDES
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
  // 5. CITOYENS EXEMPLAIRES
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
            onTap: () => context.pushNamed('monPaysCitizens'),
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
  // 6. FIGURES HISTORIQUES
  // ============================================================
  Widget _buildHistoricalFiguresFull(BuildContext context) {
    final List<Map<String, String>> figures = [
      {'name': 'Patrice Lumumba', 'role': 'Héros de l\'indépendance', 'date': '1925-1961'},
      {'name': 'Joseph Kasa-Vubu', 'role': '1er Président', 'date': '1910-1969'},
      {'name': 'Mobutu Sese Seko', 'role': 'Président', 'date': '1930-1997'},
      {'name': 'Laurent-Désiré Kabila', 'role': 'Président', 'date': '1939-2001'},
      {'name': 'Joseph Kabila', 'role': 'Président', 'date': '1971-...'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📜 Figures Historiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
            InkWell(
              onTap: () => context.pushNamed('monPaysHistory'),
              child: const Text('Explorer →', style: TextStyle(color: navy, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: figures.length,
            itemBuilder: (context, index) {
              final f = figures[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: hairline),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: gold, width: 2),
                        color: navy.withOpacity(0.08),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: navy, size: 30),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f['name']!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    Text(
                      f['role']!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9, color: mutedText, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      f['date']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8, color: mutedText, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        const Text('Découvrez ceux qui ont marqué notre histoire.', style: TextStyle(fontSize: 10, color: mutedText, fontWeight: FontWeight.w500)),
      ],
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
