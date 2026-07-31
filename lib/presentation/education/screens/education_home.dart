import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ CORRIGÉ : Imports relatifs exacts
import '../providers/education_provider.dart' hide certificatesProvider;
import '../providers/certificate_provider.dart';

import '../widgets/common/education_category_chip.dart';
import '../widgets/common/formation_card.dart';
import '../widgets/common/edu_image.dart';
import '../models/category.dart';
import '../models/formation.dart';
import '../models/certificate.dart';

class _EduColors {
  static const navyDeep = Color(0xFF0A1F44);
  static const navy = Color(0xFF123B7A);
  static const primaryBlue = Color(0xFF2D6CDF);
  static const lightBlue = Color(0xFF5B9CFF);
  static const softBlue = Color(0xFFEFF5FF);
  static const background = Color(0xFFF7FAFF);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF10192E);
  static const mutedText = Color(0xFF7386A8);
  static const border = Color(0xFFE7EEFC);
  static const gold = Color(0xFFE3B23C);
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF97316);
  static const red = Color(0xFFEF4444);
}

/// Index de l'onglet actif, partagé entre toutes les pages (permet aux
/// raccourcis internes de changer d'onglet sans callback).
final _eduTabIndexProvider = StateProvider<int>((ref) => 0);

/// Nombre de notifications non lues — branché sur Supabase.
/// Adapter le nom de table/colonnes si besoin.
final _unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider).value; 
  if (userId == null) return 0;
  try {
    final res = await Supabase.instance.client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (res as List).length;
  } catch (_) {
    return 0;
  }
});

class EducationHome extends ConsumerWidget {
  const EducationHome({super.key});

  static const _titles = ['Accueil', 'Mes cours', 'Apprendre', 'Certificats', 'Bibliothèque', 'Profil'];
  static const _navIcons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.school_rounded,
    Icons.workspace_premium_rounded,
    Icons.library_books_rounded,
    Icons.person_rounded,
  ];
  static const _pages = [
    _HomePage(),
    _MyLearningPage(),
    _AllFormationsPage(),
    _CertificatesPage(),
    _LibraryPage(),
    _ProfilePage(),
  ];

  void _openMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: _EduColors.border, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 18),
          _MenuTile(icon: Icons.card_giftcard_rounded, label: 'Cours gratuits', color: _EduColors.green, onTap: () { Navigator.pop(context); context.push('/education/free-courses'); }),
          _MenuTile(icon: Icons.videocam_rounded, label: 'Webinaires', color: _EduColors.primaryBlue, onTap: () { Navigator.pop(context); context.push('/education/webinars'); }),
          _MenuTile(icon: Icons.groups_rounded, label: 'Mentorat', color: _EduColors.orange, onTap: () { Navigator.pop(context); context.push('/education/mentorat'); }),
          _MenuTile(icon: Icons.event_rounded, label: 'Événements', color: _EduColors.navy, onTap: () { Navigator.pop(context); context.push('/education/events'); }),
          _MenuTile(icon: Icons.support_agent_rounded, label: 'Aide & support', color: _EduColors.mutedText, onTap: () { Navigator.pop(context); context.push('/education/help'); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(_eduTabIndexProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final unreadAsync = ref.watch(_unreadNotificationsProvider);

    return Scaffold(
      backgroundColor: _EduColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: Container(
          color: _EduColors.pureWhite,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openMoreMenu(context),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: _EduColors.softBlue, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.menu_rounded, color: _EduColors.navy),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [_EduColors.navyDeep, _EduColors.primaryBlue]), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(children: [
                        const TextSpan(text: 'THIX ', style: TextStyle(color: _EduColors.darkText, fontSize: 17, fontWeight: FontWeight.w800)),
                        TextSpan(
                          text: selectedIndex == 0 ? 'FORMATION' : _titles[selectedIndex].toUpperCase(),
                          style: const TextStyle(color: _EduColors.primaryBlue, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ]),
                    ),
                    if (selectedIndex == 0)
                      const Text('Apprenez aujourd\'hui, réussissez demain.', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _EduColors.mutedText, fontSize: 11.5)),
                  ]),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: () => context.push('/education/search'),
                  child: Container(width: 40, height: 40, alignment: Alignment.center, child: const Icon(Icons.search_rounded, color: _EduColors.navy, size: 22)),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(21),
                  onTap: () => context.push('/notifications'),
                  child: Container(
                    width: 40, height: 40, alignment: Alignment.center,
                    child: Stack(clipBehavior: Clip.none, children: [
                      const Icon(Icons.notifications_none_rounded, color: _EduColors.navy, size: 23),
                      Positioned(
                        right: -2, top: -2,
                        child: unreadAsync.maybeWhen(
                          data: (count) => count > 0
                              ? Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: const BoxDecoration(color: _EduColors.red, shape: BoxShape.circle),
                                  child: Text(count > 9 ? '9+' : '$count', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                                )
                              : const SizedBox(),
                          orElse: () => const SizedBox(),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => ref.read(_eduTabIndexProvider.notifier).state = 5,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: _EduColors.softBlue,
                    backgroundImage: (user?.userMetadata?['avatar_url'] != null) ? NetworkImage(user!.userMetadata!['avatar_url']) : null,
                    child: (user?.userMetadata?['avatar_url'] == null) ? const Icon(Icons.person_rounded, color: _EduColors.navy, size: 18) : null,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: _EduColors.navyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0, 9))]),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_titles.length, (i) {
                final isCenter = i == 2; // "Apprendre" mis en avant comme sur la maquette
                final isSelected = selectedIndex == i;
                if (isCenter) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => ref.read(_eduTabIndexProvider.notifier).state = i,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_EduColors.navyDeep, _EduColors.primaryBlue]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _EduColors.primaryBlue.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: Icon(_navIcons[i], color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 3),
                      Text(_titles[i], style: const TextStyle(fontSize: 9, color: _EduColors.primaryBlue, fontWeight: FontWeight.w800)),
                    ]),
                  );
                }
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => ref.read(_eduTabIndexProvider.notifier).state = i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: isSelected ? _EduColors.softBlue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_navIcons[i], color: isSelected ? _EduColors.primaryBlue : _EduColors.mutedText, size: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(_titles[i], style: TextStyle(fontSize: 9, color: isSelected ? _EduColors.primaryBlue : _EduColors.mutedText, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500)),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _EduColors.darkText)),
        ]),
      ),
    );
  }
}

// ============================== HOME ==============================

class _HomePage extends ConsumerStatefulWidget {
  const _HomePage();
  @override
  ConsumerState<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<_HomePage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 300) {
        ref.read(formationsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final formationsAsync = ref.watch(formationsProvider);
    final userId = ref.watch(currentUserIdProvider);

    return formationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _EduColors.primaryBlue)),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (paginated) {
        final formations = paginated.items;
        final recommended = [...formations]..sort((a, b) => b.rating.compareTo(a.rating));

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(formationsProvider);
            ref.invalidate(categoriesProvider);
            if (userId != null) ref.invalidate(myEnrollmentsProvider(userId));
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 0), child: _HeroCarousel()),
              const SizedBox(height: 18),
              const _QuickActionsRow(),
              const SizedBox(height: 22),

              // Catégories populaires — Supabase
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Catégories populaires', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText)),
                  InkWell(onTap: () => ref.read(_eduTabIndexProvider.notifier).state = 2, child: const Text('Voir tout', style: TextStyle(color: _EduColors.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13))),
                ]),
              ),
              const SizedBox(height: 10),
              categoriesAsync.when(
                data: (cats) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    EducationCategoryChip(
                      label: 'Tous',
                      isSelected: ref.read(formationsProvider.notifier).currentCategory == null,
                      onTap: () => ref.read(formationsProvider.notifier).filterByCategory(null),
                    ),
                    ...cats.map((cat) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: EducationCategoryChip(
                            label: cat.name,
                            isSelected: ref.read(formationsProvider.notifier).currentCategory == cat.id,
                            onTap: () => ref.read(formationsProvider.notifier).filterByCategory(cat.id),
                          ),
                        )),
                  ]),
                ),
                loading: () => const SizedBox(height: 36),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 24),

              // Formations recommandées — Supabase (triées par note)
              if (recommended.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Formations recommandées', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText)),
                    InkWell(onTap: () => ref.read(_eduTabIndexProvider.notifier).state = 2, child: const Text('Voir tout', style: TextStyle(color: _EduColors.primaryBlue, fontWeight: FontWeight.w700, fontSize: 13))),
                  ]),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 236,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: recommended.length > 8 ? 8 : recommended.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (c, i) => SizedBox(
                      width: 152,
                      child: FormationCard(formation: recommended[i], onTap: () => context.push('/education/formation/${recommended[i].id}')),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Bandeau certificats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => ref.read(_eduTabIndexProvider.notifier).state = 3,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: _EduColors.softBlue, borderRadius: BorderRadius.circular(22)),
                    child: Row(children: [
                      Container(width: 54, height: 54, decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.workspace_premium_rounded, color: _EduColors.primaryBlue, size: 28)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Obtenez des certificats reconnus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: _EduColors.darkText)),
                          SizedBox(height: 3),
                          Text('Valorisez vos compétences et démarquez-vous.', style: TextStyle(fontSize: 12, color: _EduColors.mutedText)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _EduColors.primaryBlue),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Reprendre + Objectif du mois — Supabase (myEnrollmentsProvider)
              if (userId != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _ProgressRow(userId: userId)),
              const SizedBox(height: 24),

              // Toutes les formations — Supabase, en bas de page
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Toutes les formations', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: _EduColors.darkText)),
              ])),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: formations.length + (paginated.hasMore ? 2 : 0),
                  itemBuilder: (c, i) {
                    if (i >= formations.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                    }
                    return FormationCard(formation: formations[i], onTap: () => context.push('/education/formation/${formations[i].id}'));
                  },
                ),
              ),
              if (paginated.isLoadingMore) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            ]),
          ),
        );
      },
    );
  }
}

/// Carousel du hero — seul élément "maquette" de l'écran (contenu éditorial,
/// pas de données formation). Auto-scroll toutes les 4s, 6 slides.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel();
  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  static const _slides = [
    {'title': 'Développez vos compétences,\nchangez votre avenir.', 'subtitle': 'Des milliers de cours et certificats pour booster votre carrière.', 'icon': Icons.trending_up_rounded},
    {'title': 'Apprenez à votre rythme,\noù que vous soyez.', 'subtitle': 'Cours accessibles 24h/24 depuis votre téléphone.', 'icon': Icons.phone_iphone_rounded},
    {'title': 'Des formateurs experts\nde chez vous.', 'subtitle': 'Des professionnels congolais partagent leur savoir-faire.', 'icon': Icons.groups_rounded},
    {'title': 'Décrochez un certificat\nreconnu.', 'subtitle': 'Valorisez votre profil auprès des recruteurs.', 'icon': Icons.workspace_premium_rounded},
    {'title': 'Rejoignez une communauté\nd\'apprenants.', 'subtitle': 'Échangez, progressez et réussissez ensemble.', 'icon': Icons.diversity_3_rounded},
    {'title': 'Commencez gratuitement\ndès aujourd\'hui.', 'subtitle': 'Découvrez nos cours gratuits sans engagement.', 'icon': Icons.card_giftcard_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _page = (_page + 1) % _slides.length;
      _controller.animateToPage(_page, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 158,
        child: PageView.builder(
          controller: _controller,
          itemCount: _slides.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (c, i) {
            final s = _slides[i];
            return GestureDetector(
              onTap: () => (context.mounted ? ProviderScope.containerOf(context, listen: false).read(_eduTabIndexProvider.notifier).state = 2 : null),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_EduColors.navyDeep, _EduColors.navy, _EduColors.primaryBlue]), borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.all(22),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _EduColors.gold, borderRadius: BorderRadius.circular(12)), child: const Text('À LA UNE', style: TextStyle(color: _EduColors.navyDeep, fontSize: 10.5, fontWeight: FontWeight.w800))),
                      const SizedBox(height: 10),
                      Text(s['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.2)),
                      const SizedBox(height: 6),
                      Text(s['subtitle'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Container(width: 68, height: 68, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18)), child: Icon(s['icon'] as IconData, color: _EduColors.gold, size: 30)),
                ]),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_slides.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _page == i ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(color: _page == i ? _EduColors.primaryBlue : _EduColors.border, borderRadius: BorderRadius.circular(3)),
          ))),
    ]);
  }
}

class _QuickActionsRow extends ConsumerWidget {
  const _QuickActionsRow();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      {'icon': Icons.grid_view_rounded, 'label': 'Toutes les\nformations', 'onTap': () => ref.read(_eduTabIndexProvider.notifier).state = 2},
      {'icon': Icons.workspace_premium_rounded, 'label': 'Certifications', 'onTap': () => ref.read(_eduTabIndexProvider.notifier).state = 3},
      {'icon': Icons.local_fire_department_rounded, 'label': 'Populaires', 'onTap': () => ref.read(_eduTabIndexProvider.notifier).state = 2},
      {'icon': Icons.menu_book_rounded, 'label': 'Mes cours', 'onTap': () => ref.read(_eduTabIndexProvider.notifier).state = 1},
      {'icon': Icons.history_rounded, 'label': 'Reprendre', 'onTap': () => ref.read(_eduTabIndexProvider.notifier).state = 1},
      {'icon': Icons.more_horiz_rounded, 'label': 'Plus', 'onTap': () => (context as Element).findAncestorWidgetOfExactType<EducationHome>()},
    ];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (c, i) {
          final item = items[i];
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: item['label'] == 'Plus' ? () => Scaffold.of(context).showBottomSheet((_) => const SizedBox()) : item['onTap'] as VoidCallback,
            child: Container(
              width: 74,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: _EduColors.border)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(item['icon'] as IconData, color: _EduColors.primaryBlue, size: 22),
                const SizedBox(height: 6),
                Text(item['label'] as String, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _EduColors.darkText, height: 1.1)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// "Continuez votre apprentissage" + "Objectif du mois" — données réelles
/// issues de myEnrollmentsProvider (aucune valeur fictive).
class _ProgressRow extends ConsumerWidget {
  final String userId;
  const _ProgressRow({required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollAsync = ref.watch(myEnrollmentsProvider(userId));
    return enrollAsync.when(
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox(),
      data: (list) {
        final inProgress = list.where((e) => e.formation != null && (e.progress ?? 0) > 0 && (e.progress ?? 0) < 1).toList();
        final current = inProgress.isNotEmpty ? inProgress.first : null;
        final completedCount = list.where((e) => (e.progress ?? 0) >= 1).length;
        const goal = 5; // objectif fixe — remplace par une valeur Supabase si tu en stockes une

        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: current == null
                ? _EmptyProgressCard()
                : InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/education/formation/${current.formation!.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _EduColors.border)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Continuez votre apprentissage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _EduColors.mutedText)),
                        const SizedBox(height: 10),
                        Row(children: [
                          EduImage(url: current.formation!.imageUrl, width: 44, height: 44, radius: BorderRadius.circular(12)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(current.formation!.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: _EduColors.darkText)),
                            ]),
                          ),
                        ]),
                        const SizedBox(height: 10),
                        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: current.progress, minHeight: 6, backgroundColor: _EduColors.border, color: _EduColors.green)),
                        const SizedBox(height: 6),
                        Text('${((current.progress ?? 0) * 100).round()}% terminé', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _EduColors.green)),
                      ]),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _EduColors.border)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Objectif', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _EduColors.mutedText)),
                const SizedBox(height: 8),
                Text('Terminez $goal formations\npour un badge.', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _EduColors.darkText, height: 1.3)),
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (completedCount / goal).clamp(0.0, 1.0), minHeight: 6, backgroundColor: _EduColors.border, color: _EduColors.primaryBlue)),
                const SizedBox(height: 6),
                Text('$completedCount / $goal formations', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _EduColors.primaryBlue)),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}

class _EmptyProgressCard extends StatelessWidget {
  const _EmptyProgressCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _EduColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Continuez votre apprentissage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _EduColors.mutedText)),
        SizedBox(height: 10),
        Text('Aucune formation en cours', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _EduColors.darkText)),
      ]),
    );
  }
}

// ============================ AUTRES ONGLETS (inchangés) ============================

class _MyLearningPage extends ConsumerWidget {
  const _MyLearningPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const Center(child: Text('Non connecté'));
    final enrollAsync = ref.watch(myEnrollmentsProvider(userId));
    return enrollAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) {
        if (list.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 84, height: 84, decoration: const BoxDecoration(color: _EduColors.softBlue, shape: BoxShape.circle), child: Icon(Icons.book_rounded, size: 36, color: _EduColors.navy.withOpacity(0.5))),
              const SizedBox(height: 16),
              const Text('Aucune formation en cours', style: TextStyle(fontWeight: FontWeight.w800)),
            ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (c, i) {
            final enrollment = list[i];
            final formation = enrollment.formation;
            if (formation == null) return const SizedBox();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FormationCard(formation: formation, onTap: () => context.push('/education/formation/${formation.id}'), progress: enrollment.progress?.toDouble()),
            );
          },
        );
      },
    );
  }
}

class _AllFormationsPage extends ConsumerWidget {
  const _AllFormationsPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formationsAsync = ref.watch(formationsProvider);
    return formationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (paginated) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: paginated.items.length,
        itemBuilder: (c, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: FormationCard(formation: paginated.items[i], onTap: () => context.push('/education/formation/${paginated.items[i].id}'))),
      ),
    );
  }
}

class _CertificatesPage extends ConsumerWidget {
  const _CertificatesPage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const Center(child: Text('Non connecté'));
    final certsAsync = ref.watch(certificatesProvider(userId));
    return certsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (certs) {
        if (certs.isEmpty) return const Center(child: Text('Aucun certificat'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: certs.length,
          itemBuilder: (c, i) {
            final cert = certs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _EduColors.pureWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: _EduColors.border)),
              child: Row(children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_EduColors.navyDeep, _EduColors.primaryBlue]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 14),
                Expanded(child: Text('Délivré le ${cert.issuedAt.day}/${cert.issuedAt.month}/${cert.issuedAt.year}')),
                IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => context.push('/education/certificate/${cert.id}', extra: cert)),
              ]),
            );
          },
        );
      },
    );
  }
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Bibliothèque - Bientôt'));
}

class _ProfilePage extends ConsumerWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 100, height: 100, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [_EduColors.navyDeep, _EduColors.primaryBlue])), child: const Icon(Icons.person_rounded, size: 48, color: Colors.white)),
          const SizedBox(height: 18),
          Text(user?.email ?? 'Utilisateur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/instructor/dashboard'),
              icon: const Icon(Icons.school_rounded),
              label: const Text('Passer en mode formateur'),
              style: ElevatedButton.styleFrom(backgroundColor: _EduColors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            ),
          ),
        ]),
      ),
    );
  }
}
