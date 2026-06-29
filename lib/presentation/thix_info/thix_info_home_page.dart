import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/news_item.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/admin/admin_routes.dart';
import 'package:thix_id/services/news_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';
import 'package:thix_id/theme.dart';
import 'package:provider/provider.dart';

/// THIX INFO — production screen (no mockups)
///
/// Inspired by the user's reference capture: top actions, category chips,
/// featured carousel, quick shortcuts, recent news, and videos.
class ThixInfoHomePage extends StatefulWidget {
  const ThixInfoHomePage({super.key});

  @override
  State<ThixInfoHomePage> createState() => _ThixInfoHomePageState();
}

class _ThixInfoHomePageState extends State<ThixInfoHomePage> {
  final _news = NewsService();
  final _searchController = TextEditingController();
  final _pageController = PageController(viewportFraction: 0.92);
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  RealtimeChannel? _rt;
  Timer? _rtDebounce;
  Timer? _auto;

  bool _loading = true;
  String? _error;
  List<NewsItem> _items = const [];
  int _page = 0;

  String _category = 'À la une';
  String _query = '';

  static const _categories = <String>[
    'À la une',
    'Politique',
    'Économie',
    'Société',
    'Tech',
    'Sport',
    'Culture',
    'International',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _startRealtime();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _rtDebounce?.cancel();
    _rt?.unsubscribe();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _news.listNews(limit: 300);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      debugPrint('ThixInfoHomePage: load failed err=$e');
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startRealtime() {
    try {
      final channel = SupabaseConfig.client.channel('realtime:${NewsService.table}');
      _rt = channel;
      channel
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: NewsService.table,
          callback: (payload) {
            _rtDebounce?.cancel();
            _rtDebounce = Timer(const Duration(milliseconds: 250), _load);
          },
        )
        ..subscribe((status, err) {
          if (err != null) debugPrint('THIX INFO realtime err=$err');
          debugPrint('THIX INFO realtime status=$status');
        });
    } catch (e) {
      debugPrint('ThixInfoHomePage: realtime init failed err=$e');
    }
  }

  void _startAutoScroll() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 6), (_) {
      final featured = _featured;
      if (featured.length <= 1) return;
      final next = (_page + 1) % featured.length;
      _pageController.animateToPage(next, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    });
  }

  List<NewsItem> get _featured {
    final f = _items.where((e) => e.featured).toList(growable: false);
    if (f.isNotEmpty) return f;
    return _items.take(5).toList(growable: false);
  }

  List<NewsItem> get _filtered {
    final q = _query.trim().toLowerCase();
    Iterable<NewsItem> list = _items;

    if (_category != 'À la une') {
      list = list.where((e) => e.category.trim().toLowerCase() == _category.toLowerCase());
    }
    if (q.isNotEmpty) {
      list = list.where((e) {
        final hay = '${e.title}\n${e.subtitle}\n${e.source}\n${e.category}'.toLowerCase();
        return hay.contains(q);
      });
    }
    return list.toList(growable: false);
  }

  void _openAdminInfo() {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }
    context.push('${AppRoutes.admin}/${AdminModule.news.slug}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? DarkModeColors.metalGold : LightModeColors.metalGold;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: cs.background,
      drawer: _InfoDrawer(onOpenAdmin: _openAdminInfo),
      body: SafeArea(
        child: Column(
          children: [
            ThixInfoTopBar(
              onMenu: () => _scaffoldKey.currentState?.openDrawer(),
              onNotifications: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications THIX INFO'))),
              onProfile: () {
                final auth = context.read<AuthController>();
                context.go(auth.isAuthenticated ? AppRoutes.userDashboard : AppRoutes.login);
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 0),
              child: ThixInfoSearchField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 0),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final c = _categories[index];
                  final selected = c == _category;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(c),
                    showCheckmark: false,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: selected ? Colors.black : cs.onSurface),
                    selectedColor: gold,
                    backgroundColor: cs.surface,
                    side: BorderSide(color: cs.onSurface.withValues(alpha: 0.10)),
                    onSelected: (_) => setState(() => _category = c),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _categories.length,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_error != null)
                      ? _InfoErrorState(error: _error!, onRetry: _load)
                      : _InfoContent(
                          gold: gold,
                          featured: _featured,
                          items: _filtered,
                          pageController: _pageController,
                          pageIndex: _page,
                          onPageChanged: (v) => setState(() => _page = v),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ThixInfoBottomBar(
        onHome: () => context.go(AppRoutes.home),
        onCenter: () => _scrollToTopAndHighlight(context),
        onFavorites: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favoris (bientôt)'))),
        onProfile: () {
          final auth = context.read<AuthController>();
          context.go(auth.isAuthenticated ? AppRoutes.userDashboard : AppRoutes.login);
        },
      ),
    );
  }

  void _scrollToTopAndHighlight(BuildContext context) {
    // Center action in the capture focuses the feed.
    // Here we simply reset filters to show the main feed.
    setState(() {
      _category = 'À la une';
      _query = '';
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fil info')));
  }
}

class ThixInfoTopBar extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const ThixInfoTopBar({super.key, required this.onMenu, required this.onNotifications, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? DarkModeColors.metalGold : LightModeColors.metalGold;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: Icon(Icons.menu_rounded, color: cs.onSurface),
            style: IconButton.styleFrom(backgroundColor: cs.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('THIX INFO', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                Text('Information vraie, partout.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
          _TopActionIcon(
            icon: Icons.notifications_none_rounded,
            onTap: onNotifications,
            badgeColor: Colors.red,
            badgeText: '4',
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.person_rounded, color: gold, size: 22),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.surface, width: 2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color badgeColor;
  final String? badgeText;

  const _TopActionIcon({required this.icon, required this.onTap, required this.badgeColor, this.badgeText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: cs.onSurface)),
            if (badgeText != null)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
                  child: Text(badgeText!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ThixInfoSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const ThixInfoSearchField({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Rechercher une actualité, un sujet...',
        prefixIcon: Icon(Icons.search_rounded, color: cs.onSurface.withValues(alpha: 0.55)),
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.45), width: 1.4)),
      ),
    );
  }
}

class _InfoDrawer extends StatelessWidget {
  final VoidCallback onOpenAdmin;
  const _InfoDrawer({required this.onOpenAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIX INFO', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Espace info & publications.', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.60))),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: const Text('Espace Admin — Info'),
              subtitle: const Text('Gérer les publications THIX INFO'),
              onTap: () {
                context.pop();
                onOpenAdmin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Retour Accueil'),
              onTap: () => context.go(AppRoutes.home),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Réglages'),
              onTap: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoContent extends StatelessWidget {
  final Color gold;
  final List<NewsItem> featured;
  final List<NewsItem> items;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  const _InfoContent({
    required this.gold,
    required this.featured,
    required this.items,
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recent = items.take(8).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.only(bottom: 18),
      children: [
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: featured.isEmpty ? 1 : featured.length,
            itemBuilder: (context, index) {
              final item = featured.isEmpty ? null : featured[index];
              return Padding(
                padding: const EdgeInsets.only(left: 6, right: 6),
                child: ThixFeaturedNewsCard(gold: gold, item: item),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _DotsIndicator(count: featured.isEmpty ? 1 : featured.length, index: pageIndex, activeColor: gold),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ThixInfoShortcutsRow(gold: gold),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text('Actualités récentes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              TextButton(
                onPressed: () {},
                child: Text('Voir tout', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => ThixNewsMiniCard(item: recent[index], gold: gold),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: recent.length,
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ThixRealtimeBanner(gold: gold),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Expanded(child: Text('Vidéos à la une', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              TextButton(
                onPressed: () {},
                child: Text('Voir tout', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => ThixVideoCard(item: items[index % items.length], gold: gold),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: items.isEmpty ? 0 : (items.length < 8 ? items.length : 8),
          ),
        ),
      ],
    );
  }
}

class ThixFeaturedNewsCard extends StatelessWidget {
  final Color gold;
  final NewsItem? item;
  const ThixFeaturedNewsCard({super.key, required this.gold, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final it = item;
    return InkWell(
      onTap: it == null ? null : () => context.push(AppRoutes.thixInfoArticle(it.id)),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
          color: cs.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _ThixNewsImage(
                url: it?.imageUrl,
                fit: BoxFit.cover,
                placeholder: _ThixNewsPlaceholder(gold: gold, variant: _ThixNewsPlaceholderVariant.hero),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.10), Colors.black.withValues(alpha: 0.55)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      (it?.category ?? 'À LA UNE').toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.3),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    it?.title ?? 'Aucune actualité pour le moment',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.12),
                  ),
                  if (it != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      it.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88), height: 1.3),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: Colors.white.withValues(alpha: 0.90), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            it.source,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _ArrowPill(gold: gold),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArrowPill extends StatelessWidget {
  final Color gold;
  const _ArrowPill({required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 26,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.25))),
      alignment: Alignment.center,
      child: Icon(Icons.arrow_forward_rounded, color: gold, size: 16),
    );
  }
}

class ThixInfoShortcutsRow extends StatelessWidget {
  final Color gold;
  const ThixInfoShortcutsRow({super.key, required this.gold});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = const [
      ('Fil info', Icons.feed_rounded),
      ('Vidéos', Icons.play_circle_outline_rounded),
      ('Podcasts', Icons.podcasts_rounded),
      ('Magazines', Icons.library_books_rounded),
      ('Communiqué', Icons.campaign_rounded),
      ('Alertes', Icons.notifications_active_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final (label, icon) in items)
            Expanded(
              child: InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label))),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: gold.withValues(alpha: 0.30)),
                        ),
                        child: Icon(icon, color: cs.onSurface, size: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ThixNewsMiniCard extends StatelessWidget {
  final NewsItem item;
  final Color gold;
  const ThixNewsMiniCard({super.key, required this.item, required this.gold});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push(AppRoutes.thixInfoArticle(item.id)),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 175,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 82,
              width: double.infinity,
              child: _ThixNewsImage(
                url: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: _ThixNewsPlaceholder(gold: gold, icon: Icons.newspaper_rounded, variant: _ThixNewsPlaceholderVariant.tile),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(999))),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.source, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.60), fontWeight: FontWeight.w700))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThixRealtimeBanner extends StatelessWidget {
  final Color gold;
  const ThixRealtimeBanner({super.key, required this.gold});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
        color: gold.withValues(alpha: 0.12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Restez informé en temps réel !\nActivez les notifications pour ne rien rater.', maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications activées (demo)'))),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }
}

class ThixVideoCard extends StatelessWidget {
  final NewsItem item;
  final Color gold;
  const ThixVideoCard({super.key, required this.item, required this.gold});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.push(AppRoutes.thixInfoArticle(item.id)),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 170,
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.onSurface.withValues(alpha: 0.10))),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: _ThixNewsImage(
                url: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: _ThixNewsPlaceholder(gold: gold, icon: Icons.play_circle_filled_rounded, variant: _ThixNewsPlaceholderVariant.tile),
              ),
            ),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)])))),
            Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.28))),
                child: Icon(Icons.play_arrow_rounded, color: gold, size: 26),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, height: 1.15)),
            ),
          ],
        ),
      ),
    );
  }
}

class ThixInfoBottomBar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onCenter;
  final VoidCallback onFavorites;
  final VoidCallback onProfile;

  const ThixInfoBottomBar({super.key, required this.onHome, required this.onCenter, required this.onFavorites, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gold = isDark ? DarkModeColors.metalGold : LightModeColors.metalGold;
    final cs = theme.colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            Expanded(child: _BottomItem(icon: Icons.home_rounded, label: 'Accueil', onTap: onHome)),
            Expanded(
              child: Center(
                child: InkWell(
                  onTap: onCenter,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.feed_rounded, color: Colors.black, size: 26),
                  ),
                ),
              ),
            ),
            Expanded(child: _BottomItem(icon: Icons.bookmark_rounded, label: 'Favoris', onTap: onFavorites)),
            Expanded(child: _BottomItem(icon: Icons.person_rounded, label: 'Profil', onTap: onProfile)),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BottomItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: cs.onSurface.withValues(alpha: 0.72)),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _InfoErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _InfoErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 32),
            const SizedBox(height: 10),
            Text('Impossible de charger THIX INFO', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, maxLines: 4, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  final Color activeColor;
  const _DotsIndicator({required this.count, required this.index, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    final inactive = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? activeColor : inactive,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}

enum _ThixNewsPlaceholderVariant { hero, tile }

class _ThixNewsPlaceholder extends StatelessWidget {
  final Color gold;
  final IconData? icon;
  final _ThixNewsPlaceholderVariant variant;
  const _ThixNewsPlaceholder({required this.gold, this.icon, required this.variant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navy = isDark ? DarkModeColors.primary : LightModeColors.primary;
    final navy2 = isDark ? DarkModeColors.cyberDarkBlue : LightModeColors.secondary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [navy.withValues(alpha: 0.96), navy2.withValues(alpha: 0.90), gold.withValues(alpha: 0.14)]),
      ),
      child: variant == _ThixNewsPlaceholderVariant.tile
          ? Center(child: Icon(icon ?? Icons.campaign_rounded, color: gold, size: 22))
          : Align(
              alignment: const Alignment(-0.90, -0.72),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: gold.withValues(alpha: 0.35)),
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.10),
                ),
                child: Text('THIX INFO', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w900, letterSpacing: 0.4)),
              ),
            ),
    );
  }
}

class _ThixNewsImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final Widget placeholder;
  const _ThixNewsImage({required this.url, required this.fit, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    final u = (url ?? '').trim();
    if (u.isEmpty) return placeholder;
    if (!u.startsWith('http')) return Image.asset(u, fit: fit);
    return Image.network(
      u,
      fit: fit,
      errorBuilder: (context, error, stack) {
        debugPrint('THIX INFO image load failed url=$u err=$error');
        return placeholder;
      },
    );
  }
}
