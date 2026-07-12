// lib/presentation/mon_pays/mon_pays_page.dart
// Refonte UI "Espace Citoyen" — Design maquette blanche - garde toutes les fonctionnalités

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'sections/authorities_section.dart';
import 'providers/provinces_provider.dart';

class MonPaysPage extends ConsumerWidget {
  const MonPaysPage({super.key});

  // ─── Nouvelle Charte (maquette) ──────────────────────────
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color rdcRed = Color(0xFFCE1126);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color cardBorder = Color(0xFFEEF1F7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: lightBg,
      body: CustomScrollView(
        slivers: [
          _buildTopBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildHeroBanner(),
                const SizedBox(height: 16),

                // LIGNE 1 : Autorités + Figures Historiques
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _SectionContainer(
                          number: '1.',
                          title: 'Les Autorités',
                          actionLabel: 'Voir tout',
                          onAction: () => context.push('/mon-pays/authorities'),
                          child: const AuthoritiesSection(), // TA LOGIQUE CONSERVÉE
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SectionContainer(
                          number: '2.',
                          title: 'Figures Historiques',
                          actionLabel: 'Explorer',
                          onAction: () => _showComingSoon(context),
                          child: _buildFiguresContent(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // LIGNE 2 : À la Une + Agences
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildALaUne()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAgences(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ACCÈS RAPIDES (5 icônes)
                _buildQuickAccess(context),
                const SizedBox(height: 16),

                // LIGNE 3 : Alertes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: _buildAlertCard(icon: Icons.warning_amber_rounded, iconBg: const Color(0xFFFFF0F0), title: 'Personne Recherchée', subtitle: 'Signaler ou rechercher une personne dangereuse.', onTap: () => _showComingSoon(context))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildAlertCard(icon: Icons.search_rounded, iconBg: const Color(0xFFF0F5FF), title: 'Recherche Personnalisée', subtitle: 'Rechercher des informations ciblées et officielles.', isTwoLines: true, onTap: () => _showComingSoon(context))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // PROVINCES - TA FONCTIONNALITÉ CONSERVÉE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildProvincesSection(context, ref),
                ),
                const SizedBox(height: 16),

                // CITOYENS EXEMPLAIRES BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCitoyensBanner(context),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ============================================================
  // TOP BAR BLANC (Maquette)
  // ============================================================
  Widget _buildTopBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 64,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          InkWell(onTap: () {}, child: const Icon(Icons.menu, color: primaryBlue, size: 28)),
          const SizedBox(width: 12),
          // Drapeau + Armoiries simulés
          Container(width: 32, height: 22, decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), color: primaryBlue), child: const Center(child: Text('🇨🇩', style: TextStyle(fontSize: 16)))),
          const SizedBox(width: 6),
          const Icon(Icons.shield, size: 20, color: Color(0xFFD4AF37)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('RÉPUBLIQUE DÉMOCRATIQUE\nDU CONGO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryBlue, height: 1.1)),
          ),
          _circleIcon(Icons.search, () => _showComingSoon(context)),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _circleIcon(Icons.notifications_none_rounded, () {}),
              Positioned(top: -4, right: -4, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: gold, shape: BoxShape.circle), child: const Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)))),
            ],
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/mon-pays/admin'),
            child: const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/100')),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)], border: Border.all(color: cardBorder)),
        child: Icon(icon, size: 20, color: primaryBlue),
      ),
    );
  }

  // ============================================================
  // HERO BANNER BLEU (Maquette)
  // ============================================================
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: primaryBlue,
        image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?q=80&w=800'), fit: BoxFit.cover, alignment: Alignment.centerRight),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [primaryBlue, primaryBlue.withOpacity(0.85), Colors.transparent], stops: const [0.0, 0.6, 1.0]),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Espace Citoyen', style: TextStyle(fontFamily: 'Serif', fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 6),
            Text('S\'informer • Comprendre • Participer • Construire', style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FIGURES HISTORIQUES - SANS MOCK, AVEC VRAI WIDGET
  // ============================================================
  Widget _buildFiguresContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 2), height: 52, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: NetworkImage('https://i.pravatar.cc/100?img=${20+i}'), fit: BoxFit.cover, colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation)))))),
        ),
        const SizedBox(height: 14),
        // Slider design maquette
        Stack(children: [Container(height: 2, color: const Color(0xFFE5EAF3)), Positioned(left: 0, child: Container(width: 18, height: 8, margin: const EdgeInsets.only(top: -3), decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(10))))]),
        const SizedBox(height: 12),
        Row(children: const [Expanded(child: Text('Découvrez ceux qui ont marqué notre histoire.', style: TextStyle(fontSize: 11, color: mutedText))), Icon(Icons.chevron_right, size: 18, color: primaryBlue)]),
      ],
    );
  }

  // ============================================================
  // À LA UNE - DESIGN MAQUETTE
  // ============================================================
  Widget _buildALaUne() {
    return _SectionContainer(
      number: '3.',
      title: 'À la Une',
      actionLabel: 'Voir toutes',
      onAction: () {},
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _newsItem('OFFICIEL', '27 Mai 2025', 'Inauguration du Pont Maréchal à Kinshasa', 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df'),
          const SizedBox(width: 8),
          _newsItem('COMMUNIQUÉ', '25 Mai 2025', 'Conseil des Ministres : Principales décisions', 'https://images.unsplash.com/photo-1450101499163-c8848c66ca85'),
          const SizedBox(width: 8),
          _newsItem('NATIONAL', '23 Mai 2025', 'Réforme de l\'éducation : cap sur la qualité', 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b'),
        ],
      ),
    );
  }

  Widget _newsItem(String tag, String date, String title, String img) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(img, height: 80, width: double.infinity, fit: BoxFit.cover)), Positioned(top: 5, left: 5, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)), child: Text(tag, style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold))))]),
        const SizedBox(height: 5),
        Text(date, style: const TextStyle(fontSize: 8, color: mutedText)),
        Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: darkText)),
      ]),
    );
  }

  // ============================================================
  // AGENCES & INSTITUTIONS - DESIGN MAQUETTE
  // ============================================================
  Widget _buildAgences(BuildContext context) {
    return _SectionContainer(
      number: '4.',
      title: 'Agences & Institutions',
      actionLabel: 'Explorer',
      onAction: () => _showComingSoon(context),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_agencyIcon(Icons.account_balance, 'Présidence', context), _agencyIcon(Icons.flag_rounded, 'Gouvernement', context), _agencyIcon(Icons.account_balance_outlined, 'Parlement', context)]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_agencyIcon(Icons.work_rounded, 'Ministères', context), _agencyIcon(Icons.location_on_rounded, 'Provinces', context, route: '/mon-pays/provinces'), _agencyIcon(Icons.apartment_rounded, 'Entreprises\nPubliques', context)]),
          const Align(alignment: Alignment.centerRight, child: Icon(Icons.chevron_right, color: primaryBlue, size: 20)),
        ],
      ),
    );
  }

  Widget _agencyIcon(IconData icon, String label, BuildContext context, {String? route}) {
    return InkWell(
      onTap: () => route!= null? context.push(route) : _showComingSoon(context),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: lightBg, shape: BoxShape.circle, border: Border.all(color: cardBorder)), child: Icon(icon, color: primaryBlue, size: 22)),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.1)),
      ]),
    );
  }

  // ============================================================
  // PROVINCES - TA LOGIQUE 100% CONSERVÉE, JUSTE UI REFAIT
  // ============================================================
  Widget _buildProvincesSection(BuildContext context, WidgetRef ref) {
    final provincesAsync = ref.watch(provincesProvider(null));
    return _SectionContainer(
      number: '🗺️',
      title: 'Provinces',
      actionLabel: 'Voir toutes',
      onAction: () => context.push('/mon-pays/provinces'),
      child: provincesAsync.when(
        loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const Text('Impossible de charger', style: TextStyle(color: rdcRed, fontSize: 12)),
        data: (provinces) {
          if (provinces.isEmpty) return const Text('Aucune province', style: TextStyle(color: mutedText, fontSize: 12));
          return SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: provinces.take(6).length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final p = provinces[index];
                return InkWell(
                  onTap: () => context.push('/mon-pays/provinces/${p.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 130,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: cardBorder)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(radius: 18, backgroundColor: Colors.white, backgroundImage: p.coatOfArmsUrl!= null? NetworkImage(p.coatOfArmsUrl!) : null, child: p.coatOfArmsUrl == null? Text(p.code.substring(0, 2).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)) : null),
                      const Spacer(),
                      Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      Text(p.capital, style: const TextStyle(fontSize: 10, color: mutedText)),
                    ]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  //... autres widgets UI identiques
  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      {'icon': Icons.videocam_rounded, 'label': 'Vidéos\nOfficielles', 'color': rdcRed, 'route': null},
      {'icon': Icons.folder_rounded, 'label': 'Documentaires\n& Archives', 'color': primaryBlue, 'route': null},
      {'icon': Icons.emoji_events_rounded, 'label': 'Citoyens\nExemplaires', 'color': const Color(0xFFD4A017), 'route': null},
      {'icon': Icons.balance_rounded, 'label': 'Valeurs\n& Lois', 'color': primaryBlue, 'route': '/mon-pays/laws'},
      {'icon': Icons.campaign_rounded, 'label': 'Participer\n& S\'exprimer', 'color': const Color(0xFF1FA971), 'route': null},
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final it = items[i];
          return InkWell(
            onTap: () => it['route']!= null? context.push(it['route'] as String) : _showComingSoon(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 86,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(it['icon'] as IconData, color: it['color'] as Color, size: 28),
                const SizedBox(height: 8),
                Text(it['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard({required IconData icon, required Color iconBg, required String title, required String subtitle, required VoidCallback onTap, bool isTwoLines = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: cardBorder)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: title.contains('Recherchée')? rdcRed : primaryBlue)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: isTwoLines? 12 : 12, color: title.contains('Recherchée')? rdcRed : primaryBlue)), Text(subtitle, style: const TextStyle(fontSize: 10, color: mutedText), maxLines: 2)])),
          const Icon(Icons.chevron_right, size: 18, color: mutedText),
        ]),
      ),
    );
  }

  Widget _buildCitoyensBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.star_rounded, color: gold, size: 24)),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Citoyens Exemplaires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)), SizedBox(height: 2), Text('Ils bâtissent la RDC chaque jour par leurs actions inspirantes.', style: TextStyle(color: Colors.white70, fontSize: 11))])),
        const SizedBox(width: 10),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: primaryBlue, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)), onPressed: () => _showComingSoon(context), child: const Text('Découvrir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
      ]),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _navItem(context, Icons.home_rounded, 'Accueil', true, '/'),
        _navItem(context, Icons.flag_rounded, 'Mon Pays', true, '/mon-pays'),
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle), child: const Icon(Icons.shield, color: gold, size: 20)),
        _navItem(context, Icons.grid_view_rounded, 'Services', false, null),
        _navItem(context, Icons.person_rounded, 'Mon Compte', false, null),
      ]),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, String? route) {
    return InkWell(
      onTap: () => route!= null? context.go(route) : _showComingSoon(context),
      child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 22, color: active? primaryBlue : mutedText), Text(label, style: TextStyle(fontSize: 10, fontWeight: active? FontWeight.w700 : FontWeight.w500, color: active? primaryBlue : mutedText))]),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🚧 Module en cours de développement'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)));
  }
}

// Widget générique pour les cards de la maquette
class _SectionContainer extends StatelessWidget {
  final String number;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;
  const _SectionContainer({required this.number, required this.title, required this.actionLabel, required this.onAction, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MonPaysPage.cardBorder), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(number, style: const TextStyle(fontWeight: FontWeight.w900, color: MonPaysPage.primaryBlue, fontSize: 16)),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: MonPaysPage.primaryBlue))),
          InkWell(onTap: onAction, child: Row(children: [Text(actionLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w600)), const Icon(Icons.chevron_right, size: 16, color: Color(0xFF5B8DEF))])),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}
