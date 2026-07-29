// lib/presentation/mon_pays/mon_pays_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/featured_provinces_provider.dart';
import 'providers/authorities_provider.dart';

// 💡 TODO: Importez ici votre Provider d'authentification
// import '../../providers/auth_provider.dart';

class MonPaysPage extends HookConsumerWidget {
  const MonPaysPage({super.key});

  // ─── Charte Graphique Institutionnelle RDC ────────────────────────
  static const Color primaryBlue = Color(0xFF0052A5);
  static const Color lightBg = Color(0xFFF4F7FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color rdcRed = Color(0xFFCE1126);
  static const Color mutedText = Color(0xFF5A6B87);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color darkText = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ─── Gestion des Hooks (Remplace le StatefulWidget) ─────────────
    final patrioticCtrl = usePageController(viewportFraction: 0.92);
    final currentPatriotic = useState(0);

    // Timer automatique géré proprement par un Hook (pas de memory leak)
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (patrioticCtrl.hasClients) {
          final nextPage = (currentPatriotic.value + 1) % _patrioticPosters.length;
          patrioticCtrl.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
          );
          currentPatriotic.value = nextPage;
        }
      });
      return timer.cancel; // Cleanup automatique
    }, [patrioticCtrl]);

    return Scaffold(
      backgroundColor: lightBg,
      body: CustomScrollView(
        slivers: [
          // 🚀 On passe 'ref' pour permettre l'écoute de l'utilisateur connecté
          _buildSliverAppBar(context, ref),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildPatrioticCarousel(patrioticCtrl, currentPatriotic.value),
                const SizedBox(height: 24),
                
                // ── Sections principales ──
                _buildSectionPadding(child: _buildAutoritesTop(context, ref)),
                const SizedBox(height: 20),
                _buildSectionPadding(child: _buildInstitutions(context)),
                const SizedBox(height: 20),
                _buildSectionPadding(child: _buildActualites(context)),
                const SizedBox(height: 20),
                _buildSectionPadding(child: _buildProvincesSection(context, ref)),
                const SizedBox(height: 20),
                _buildQuickAccess(context),
                const SizedBox(height: 20),
                _buildSectionPadding(child: _buildAlertRow()),
                const SizedBox(height: 24),
                _buildSectionPadding(child: _buildFiguresHistoriques(context)),
                const SizedBox(height: 24),
                _buildSectionPadding(child: _buildCitoyensBanner(context)),
                const SizedBox(height: 120), // Espace pour la BottomNav
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      extendBody: true, // Permet à la liste de scroller derrière la bottom nav floutée
    );
  }

  // ─── Helpers de Layout ───────────────────────────────────────────
  Widget _buildSectionPadding({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }

  // ─── En-tête Institutionnel ──────────────────────────────────────
  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    // 🚀 VÉRIFICATION DU RÔLE (À adapter selon votre authProvider)
    // final user = ref.watch(authProvider).value;
    // final isAdmin = user?.role == 'admin';
    final isAdmin = true; // Bouchon : Mettez à false pour tester la disparition

    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0.5,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      toolbarHeight: 72,
      title: Row(
        children: [
          // Armoiries de la RDC
          Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Coat_of_arms_of_the_Democratic_Republic_of_the_Congo.svg/200px-Coat_of_arms_of_the_Democratic_Republic_of_the_Congo.svg.png',
            height: 40,
            errorBuilder: (_, __, ___) => const Icon(Icons.shield, color: gold),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RÉPUBLIQUE DÉMOCRATIQUE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'DU CONGO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: rdcRed,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          _actionIconButton(Icons.search_rounded, () => _showComingSoon(context)),
          const SizedBox(width: 8),
          _actionIconButton(Icons.notifications_none_rounded, () {}, badge: 3),
          
          // 🚀 AFFICHAGE CONDITIONNEL DU BOUTON ADMIN
          if (isAdmin) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () => context.push('/mon-pays/admin'),
              borderRadius: BorderRadius.circular(20),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: cardBorder,
                backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionIconButton(IconData icon, VoidCallback onTap, {int? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder),
              color: lightBg,
            ),
            child: Icon(icon, size: 20, color: primaryBlue),
          ),
        ),
        if (badge != null && badge > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: rdcRed,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                badge.toString(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Carrousel ───────────────────────────────────────────────────
  Widget _buildPatrioticCarousel(PageController ctrl, int currentIndex) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: ctrl,
            itemCount: _patrioticPosters.length,
            itemBuilder: (context, index) {
              final p = _patrioticPosters[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(p['img']!),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        primaryBlue.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['title']!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: primaryBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p['subtitle']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _patrioticPosters.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: index == currentIndex ? 24 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index == currentIndex ? primaryBlue : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Autorités (Logique déportée dans le Provider) ───────────────
  Widget _buildAutoritesTop(BuildContext context, WidgetRef ref) {
    final authoritiesAsync = ref.watch(topAuthoritiesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Hautes Autorités',
            icon: Icons.account_balance,
            onTap: () => context.push('/mon-pays/authorities'),
          ),
          const SizedBox(height: 16),
          
          authoritiesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: primaryBlue)),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
            data: (authorities) {
              if (authorities.isEmpty) return const Text('Aucune donnée');

              final president = authorities.first;
              final others = authorities.skip(1).take(3).toList();

              return Column(
                children: [
                  _buildPresidentCard(context, president),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSubAuthoritiesGrid(context, others),
                  ]
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresidentCard(BuildContext context, dynamic president) {
    return InkWell(
      onTap: () => context.push('/mon-pays/authorities/${president.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold, width: 2),
                boxShadow: [BoxShadow(color: gold.withOpacity(0.3), blurRadius: 8)],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(president.imageUrl ?? ''),
                onBackgroundImageError: (_, __) {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    president.title?.toUpperCase() ?? 'PRÉSIDENT DE LA RÉPUBLIQUE',
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    president.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: darkText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubAuthoritiesGrid(BuildContext context, List<dynamic> others) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
      ),
      itemCount: others.length,
      itemBuilder: (context, i) {
        final a = others[i];
        return InkWell(
          onTap: () => context.push('/mon-pays/authorities/${a.id}'),
          child: Column(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: cardBorder,
                backgroundImage: NetworkImage(a.imageUrl ?? ''),
              ),
              const SizedBox(height: 8),
              Text(
                a.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              Text(
                a.title ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: mutedText, height: 1.1),
              ),
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: cardBorder),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
    ],
  );

  Widget _buildSectionHeader({required String title, required IconData icon, VoidCallback? onTap}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, color: primaryBlue, fontSize: 16),
        ),
        const Spacer(),
        if (onTap != null)
          InkWell(
            onTap: onTap,
            child: const Text('Voir tout', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildProvincesSection(BuildContext context, WidgetRef ref) {
    final provAsync = ref.watch(featuredProvincesProvider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _buildSectionHeader(
            title: 'Provinces',
            icon: Icons.map_rounded,
            onTap: () => context.push('/mon-pays/provinces'),
          ),
          const SizedBox(height: 16),
          provAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const Text('Erreur de chargement'),
            data: (list) => SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (c, i) {
                  final p = list[i];
                  return InkWell(
                    onTap: () => context.push('/mon-pays/provinces/${p.id}'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: lightBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: Text(p.code.substring(0, 2), style: const TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                          ),
                          const Spacer(),
                          Text(p.name, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          Text(p.capital, style: const TextStyle(fontSize: 11, color: mutedText)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(Icons.home_rounded, 'Accueil', false, () => context.go('/')),
          _navItem(Icons.flag_rounded, 'Mon Pays', true, () {}),
          FloatingActionButton(
            elevation: 0,
            backgroundColor: primaryBlue,
            onPressed: () => _showComingSoon(context),
            shape: const CircleBorder(),
            child: const Icon(Icons.shield, color: gold),
          ),
          _navItem(Icons.grid_view_rounded, 'Services', false, () => _showComingSoon(context)),
          _navItem(Icons.person_rounded, 'Profil', false, () => _showComingSoon(context)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    final color = isActive ? primaryBlue : mutedText;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Module en cours de déploiement', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildInstitutions(BuildContext context) => const SizedBox();
  Widget _buildActualites(BuildContext context) => const SizedBox();
  Widget _buildQuickAccess(BuildContext context) => const SizedBox();
  Widget _buildAlertRow() => const SizedBox();
  Widget _buildFiguresHistoriques(BuildContext context) => const SizedBox();
  Widget _buildCitoyensBanner(BuildContext context) => const SizedBox();

  static const _patrioticPosters = [
    {'title': 'RDC', 'subtitle': 'Bendele ya Congo', 'img': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4'},
    {'title': 'DEVOIR', 'subtitle': 'S\'engager pour la Patrie', 'img': 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac'},
  ];
}
