// lib/presentation/thix_info/thix_info_home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

// DEFINITIONS CONST TOP-LEVEL - CORRIGE ERREUR STATIC
const _kPrimaryBlue = Color(0xFF0B3D91);
const _kGold = Color(0xFFFFB800);
const _kGoldLight = Color(0xFFFFC72C);
const _kBg = Color(0xFFF7F8FB);
const _kWhite = Color(0xFFFFFFFF);
const _kTextDark = Color(0xFF101840);
const _kTextMuted = Color(0xFF8A8FA8);
const _kBorder = Color(0xFFECEEF4);

class ThixInfoHome extends StatefulWidget {
  const ThixInfoHome({super.key});
  @override State<ThixInfoHome> createState() => _ThixInfoHomeState();
}

class _ThixInfoHomeState extends State<ThixInfoHome> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'featured';
  int _selectedNavIndex = 0;
  bool _isInitialized = false;

  final List<Map<String, String>> _categories = [
    {'slug': 'featured', 'name': 'À la une'},
    {'slug': 'politique', 'name': 'Politique'},
    {'slug': 'economie', 'name': 'Économie'},
    {'slug': 'societe', 'name': 'Société'},
    {'slug': 'tech', 'name': 'Tech'},
    {'slug': 'sport', 'name': 'Sport'},
    {'slug': 'culture', 'name': 'Culture'},
    {'slug': 'international', 'name': 'International'},
  ];

  final List<Map<String, dynamic>> _quickActions = [
    {'label': 'Fil Info', 'icon': Icons.article_rounded, 'color': Color(0xFF2F80ED), 'bg': Color(0xFFEFF6FF)},
    {'label': 'Vidéos', 'icon': Icons.play_circle_rounded, 'color': Color(0xFFEB5757), 'bg': Color(0xFFFFF0F0)},
    {'label': 'Podcasts', 'icon': Icons.headset_rounded, 'color': Color(0xFF9B51E0), 'bg': Color(0xFFF5EFFF)},
    {'label': 'Magazines', 'icon': Icons.menu_book_rounded, 'color': Color(0xFFF2994A), 'bg': Color(0xFFFFF6EB)},
    {'label': 'Communiqués', 'icon': Icons.campaign_rounded, 'color': Color(0xFF2D9CDB), 'bg': Color(0xFFEFF8FF)},
    {'label': 'Alertes', 'icon': Icons.notifications_rounded, 'color': Color(0xFF27AE60), 'bg': Color(0xFFECFFF3)},
  ];

  @override void initState() { super.initState(); _initializeData(); }

  Future<void> _initializeData() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final provider = Provider.of<NewsProvider>(context, listen: false);
    try { await Future.wait([provider.fetchArticles(), provider.fetchVideos()]); } catch (e) { debugPrint('❌ $e'); }
    if (mounted) setState(() => _isInitialized = true);
  }

  @override void dispose() { _scrollController.dispose(); super.dispose(); }

  void _onNavTap(int i) {
    setState(() => _selectedNavIndex = i);
    HapticFeedback.lightImpact();
    switch (i) {
      case 0: break;
      case 1: context.push('/thix-info/categories'); break;
      case 2: context.push('/thix-info/breaking'); break;
      case 3: context.push('/thix-info/saved'); break;
      case 4: context.push('/profile'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();
    final featured = newsProvider.featuredArticle;
    final recents = newsProvider.recentArticles;
    final videos = newsProvider.videos;

    if (!_isInitialized && newsProvider.isLoading) {
      return const Scaffold(backgroundColor: _kBg, body: Center(child: CircularProgressIndicator(color: _kPrimaryBlue)));
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(controller: _scrollController, slivers: [
        SliverToBoxAdapter(child: _buildTopBar()),
        SliverToBoxAdapter(child: _buildSearch()),
        SliverToBoxAdapter(child: const SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildCategoryPills()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: featured != null ? _buildHeroCard(featured) : _buildHeroPlaceholder()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _buildQuickActions()),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        SliverToBoxAdapter(child: _buildSectionHeader('Actualités récentes', '/thix-info/recent')),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildRecentHorizontal(recents, newsProvider.isLoading)),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildAlertBanner())),
        const SliverToBoxAdapter(child: SizedBox(height: 22)),
        SliverToBoxAdapter(child: _buildSectionHeader('Vidéos à la une', '/thix-info/videos')),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _buildVideosHorizontal(videos, newsProvider.isLoading)),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // TOP BAR AVEC ACCES ADMIN OUVERT
  Widget _buildTopBar() {
    return Container(
      color: _kWhite,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.menu_rounded, size: 26), onPressed: () => context.go('/')),
        const SizedBox(width: 4),
        Container(width: 42, height: 42, decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.newspaper_rounded, color: Colors.white)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text('THIX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kTextDark)), SizedBox(width: 6), Text('INFO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _kGold))]),
          Text("L'information vraie, partout.", style: TextStyle(fontSize: 11, color: _kTextMuted)),
        ])),
        // BOUTON ADMIN - OUVERT - CONNECTÉ
        InkWell(
          onTap: () => context.push('/admin'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.black),
              SizedBox(width: 4),
              Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        Stack(clipBehavior: Clip.none, children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, size: 26)),
          Positioned(top: 4, right: 4, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
        ]),
      ]),
    );
  }

  Widget _buildSearch() => Container(color: _kWhite, padding: const EdgeInsets.fromLTRB(16, 0, 16, 14), child: GestureDetector(onTap: () => context.push('/thix-info/search'), child: Container(height: 44, decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [const Icon(Icons.search_rounded, color: _kTextMuted, size: 20), const SizedBox(width: 8), const Expanded(child: Text('Rechercher une actualité, un sujet...', style: TextStyle(color: _kTextMuted, fontSize: 13))), Container(width: 1, height: 22, color: _kBorder, margin: const EdgeInsets.symmetric(horizontal: 10)), const Icon(Icons.tune_rounded, size: 20, color: _kTextDark)]))));

  Widget _buildCategoryPills() => SizedBox(height: 36, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _categories.length, separatorBuilder: (_, __) => const SizedBox(width: 8), itemBuilder: (_, i) { final cat = _categories[i]; final sel = _selectedCategory == cat['slug']; return GestureDetector(onTap: () { setState(() => _selectedCategory = cat['slug']!); context.read<NewsProvider>().fetchArticles(category: cat['slug']); }, child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: sel ? _kGold : _kWhite, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? _kGold : _kBorder)), alignment: Alignment.center, child: Text(cat['name']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _kTextDark)))); }));

  // CORRIGE : summary au lieu de excerpt
  Widget _buildHeroCard(NewsArticle a) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: GestureDetector(onTap: () => context.push('/thix-info/article/${a.id}'), child: Container(height: 210, decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6))]), clipBehavior: Clip.antiAlias, child: Row(children: [Expanded(flex: 5, child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _kGoldLight.withOpacity(0.28), borderRadius: BorderRadius.circular(6)), child: const Text('À LA UNE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: _kTextDark))), const SizedBox(height: 10), Text(a.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, height: 1.2, color: _kTextDark)), const SizedBox(height: 8), Text(a.summary ?? 'Un plan ambitieux pour stimuler la croissance, créer des emplois et améliorer le pouvoir d\'achat.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: _kTextMuted, height: 1.3)), const Spacer(), Row(children: [const Icon(Icons.access_time_rounded, size: 12, color: _kTextMuted), const SizedBox(width: 4), Text(_formatTimeAgo(a.publishedAt), style: const TextStyle(fontSize: 11, color: _kTextMuted)), const SizedBox(width: 10), const Icon(Icons.remove_red_eye_outlined, size: 12, color: _kTextMuted), const SizedBox(width: 4), Text('${_formatCount(a.viewsCount)} vues', style: const TextStyle(fontSize: 11, color: _kTextMuted))]), const SizedBox(height: 10), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Text("Lire l'article", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), SizedBox(width: 6), Icon(Icons.arrow_forward_rounded, size: 14)]))]))), Expanded(flex: 5, child: Stack(children: [Positioned.fill(child: a.imageUrl != null && a.imageUrl!.isNotEmpty ? Image.network(a.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _kBg)) : Container(color: _kPrimaryBlue)), Positioned(bottom: 10, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 3), width: i == 0 ? 18 : 8, height: 6, decoration: BoxDecoration(color: i == 0 ? _kGold : Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(10))))))]))]))));

  Widget _buildHeroPlaceholder() => Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 210, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Center(child: CircularProgressIndicator(color: _kPrimaryBlue)));
  Widget _buildQuickActions() => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: _kBorder)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _quickActions.map((e) => Column(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: e['bg'] as Color, borderRadius: BorderRadius.circular(12)), child: Icon(e['icon'] as IconData, color: e['color'] as Color, size: 22)), const SizedBox(height: 6), Text(e['label'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTextDark))])).toList()));
  Widget _buildSectionHeader(String t, String r) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _kTextDark)), GestureDetector(onTap: () => context.push(r), child: const Row(children: [Text('Voir tout', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF9A7B11))), SizedBox(width: 2), Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9A7B11))]))]));
  Widget _buildRecentHorizontal(List<NewsArticle> list, bool loading) { if (loading && list.isEmpty) return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())); if (list.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucune actualité', style: TextStyle(color: _kTextMuted)))); return SizedBox(height: 200, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: list.length > 8 ? 8 : list.length, itemBuilder: (_, i) { final a = list[i]; return GestureDetector(onTap: () => context.push('/thix-info/article/${a.id}'), child: Container(width: 165, margin: EdgeInsets.only(right: i == list.length - 1 ? 0 : 12), decoration: BoxDecoration(color: _kWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)), clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [SizedBox(height: 90, width: double.infinity, child: a.imageUrl != null ? Image.network(a.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: _kBg)) : Container(color: _kBg)), Positioned(top: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: _badgeFor(a.category), borderRadius: BorderRadius.circular(6)), child: Text(_getCategoryName(a.category).toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.white))))]), Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(10, 8, 10, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_formatTimeAgo(a.publishedAt), style: const TextStyle(fontSize: 10, color: _kTextMuted)), const SizedBox(height: 4), Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.25, color: _kTextDark)), const Spacer(), Row(children: [Text('${_formatCount(a.viewsCount)} vues', style: const TextStyle(fontSize: 10, color: _kTextMuted)), const Spacer(), const Icon(Icons.bookmark_border_rounded, size: 16, color: _kTextMuted)])])))]))); })); }
  Widget _buildAlertBanner() => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFFE9A8))), child: Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: _kGold.withOpacity(0.22), shape: BoxShape.circle), child: const Icon(Icons.notifications_rounded, color: _kGold)), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Restez informé en temps réel !', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _kTextDark)), SizedBox(height: 2), Text('Activez vos notifications et ne manquez aucune information importante.', style: TextStyle(fontSize: 11, color: _kTextMuted, height: 1.3))])), const Icon(Icons.close_rounded, size: 18, color: _kTextMuted)]));
  Widget _buildVideosHorizontal(List<NewsArticle> vids, bool loading) { if (loading && vids.isEmpty) return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())); if (vids.isEmpty) return const SizedBox(height: 60, child: Center(child: Text('Aucune vidéo', style: TextStyle(color: _kTextMuted)))); return SizedBox(height: 190, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: vids.length, itemBuilder: (_, i) { final v = vids[i]; return GestureDetector(onTap: () => context.push('/thix-info/article/${v.id}'), child: Container(width: 160, margin: EdgeInsets.only(right: i == vids.length - 1 ? 0 : 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(height: 100, width: 160, child: v.imageUrl != null ? Image.network(v.imageUrl!, fit: BoxFit.cover) : Container(color: Colors.black12))), Positioned.fill(child: Center(child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle), child: const Icon(Icons.play_arrow_rounded, size: 20))))]), const SizedBox(height: 8), Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, height: 1.25, color: _kTextDark)), const SizedBox(height: 4), Text('${_formatCount(v.viewsCount)} vues • ${_formatTimeAgo(v.publishedAt)}', style: const TextStyle(fontSize: 10, color: _kTextMuted))]))); })); }
  Widget _buildBottomNav() => Container(margin: const EdgeInsets.fromLTRB(12, 0, 12, 12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18)]), child: SafeArea(top: false, child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_nav(Icons.home_rounded, 'Accueil', 0), _nav(Icons.grid_view_rounded, 'Catégories', 1), _centerFab(), _nav(Icons.bookmark_border_rounded, 'Favoris', 3), _nav(Icons.person_outline_rounded, 'Profil', 4)])));
  Widget _nav(IconData ic, String lb, int idx) { final active = _selectedNavIndex == idx; return InkWell(onTap: () => _onNavTap(idx), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(ic, color: active ? _kGold : _kTextMuted, size: 22), const SizedBox(height: 2), Text(lb, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? _kGold : _kTextMuted))])); }
  Widget _centerFab() => InkWell(onTap: () => _onNavTap(2), child: Container(width: 56, height: 56, decoration: const BoxDecoration(color: _kGold, shape: BoxShape.circle), child: const Icon(Icons.newspaper_rounded, color: Colors.white)));
  Color _badgeFor(String slug) { switch (slug) { case 'politique': return const Color(0xFF2F80ED); case 'economie': return const Color(0xFF27AE60); case 'tech': return const Color(0xFF2D9CDB); case 'sport': return const Color(0xFFF2994A); default: return _kPrimaryBlue; } }
  String _formatTimeAgo(DateTime d) { final diff = DateTime.now().difference(d); if (diff.inDays >= 1) return 'il y a ${diff.inDays}j'; if (diff.inHours >= 1) return 'il y a ${diff.inHours}h'; if (diff.inMinutes >= 1) return 'il y a ${diff.inMinutes}min'; return 'maintenant'; }
  String _formatCount(int c) { if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M'; if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}k'; return '$c'; }
  String _getCategoryName(String slug) { final cat = _categories.firstWhere((e) => e['slug'] == slug, orElse: () => {'slug': slug, 'name': slug}); return cat['name']!; }
}
