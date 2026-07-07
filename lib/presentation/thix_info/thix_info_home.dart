// lib/presentation/thix_info/thix_info_home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/news_provider.dart';
import '../../models/news_article.dart';
import 'article_detail_page.dart';
import 'search_page.dart';
import 'category_articles_page.dart';
import 'saved_articles_page.dart';
import 'breaking_news_page.dart';

// ============================================================
// CHARTE THIX INFO — Élite Institutionnel Bleu / Blanc
// ============================================================
class _InfoColors {
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color background = Color(0xFFF7FAFF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color border = Color(0xFFE7EEFC);
  static const Color gold = Color(0xFFE3B23C);
}

class ThixInfoHome extends StatefulWidget {
  const ThixInfoHome({super.key});

  @override
  State<ThixInfoHome> createState() => _ThixInfoHomeState();
}

class _ThixInfoHomeState extends State<ThixInfoHome> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'featured';
  int _selectedNavIndex = 0;
  bool _isInitialized = false;

  final List<Map<String, dynamic>> _categories = [
    {'slug': 'featured', 'name': 'À la une', 'icon': Icons.local_fire_department_rounded},
    {'slug': 'politique', 'name': 'Politique', 'icon': Icons.account_balance_rounded},
    {'slug': 'economie', 'name': 'Économie', 'icon': Icons.trending_up_rounded},
    {'slug': 'societe', 'name': 'Société', 'icon': Icons.people_alt_rounded},
    {'slug': 'tech', 'name': 'Tech', 'icon': Icons.computer_rounded},
    {'slug': 'sport', 'name': 'Sport', 'icon': Icons.sports_soccer_rounded},
    {'slug': 'culture', 'name': 'Culture', 'icon': Icons.museum_rounded},
    {'slug': 'international', 'name': 'International', 'icon': Icons.public_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Attendre que le contexte soit disponible
    await Future.delayed(Duration.zero);
    
    if (mounted) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      
      // Charger les données avec gestion d'erreur
      try {
        await Future.wait([
          newsProvider.fetchArticles(),
          newsProvider.fetchVideos(),
        ]);
      } catch (e) {
        debugPrint('❌ Erreur lors du chargement initial: $e');
      }
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    HapticFeedback.lightImpact();
    
    switch (index) {
      case 0:
        break;
      case 1:
        context.push('/thix-info/categories');
        break;
      case 2:
        context.push('/thix-info/breaking');
        break;
      case 3:
        context.push('/thix-info/saved');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = Provider.of<NewsProvider>(context);
    final featuredArticle = newsProvider.featuredArticle;
    final recentArticles = newsProvider.recentArticles;
    final videos = newsProvider.videos;
    final isLoading = newsProvider.isLoading;
    final hasError = newsProvider.error != null;

    // Afficher un loader pendant l'initialisation
    if (!_isInitialized && isLoading) {
      return const Scaffold(
        backgroundColor: _InfoColors.background,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_InfoColors.primaryBlue),
          ),
        ),
      );
    }

    // Afficher une erreur si nécessaire
    if (hasError && featuredArticle == null && recentArticles.isEmpty) {
      return Scaffold(
        backgroundColor: _InfoColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: _InfoColors.softBlue, shape: BoxShape.circle),
                child: Icon(Icons.error_outline_rounded, size: 38, color: _InfoColors.navy.withOpacity(0.5)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Impossible de charger les actualités',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _InfoColors.darkText),
              ),
              const SizedBox(height: 8),
              Text(
                newsProvider.error ?? 'Erreur inconnue',
                style: const TextStyle(fontSize: 12, color: _InfoColors.mutedText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  newsProvider.clearError();
                  newsProvider.fetchArticles();
                  newsProvider.fetchVideos();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _InfoColors.navyDeep,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _InfoColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildCategories()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          
          // Article à la une
          if (isLoading && featuredArticle == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_InfoColors.primaryBlue),
                  ),
                ),
              ),
            )
          else if (featuredArticle != null)
            SliverToBoxAdapter(child: _buildFeaturedArticle(featuredArticle)),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSectionHeader('Actualités récentes', '/thix-info/recent')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          
          // Actualités récentes
          if (isLoading && recentArticles.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_InfoColors.primaryBlue),
                  ),
                ),
              ),
            )
          else if (recentArticles.isEmpty && !isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucune actualité disponible',
                    style: TextStyle(color: _InfoColors.mutedText),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildRecentArticleItem(recentArticles[index]),
                childCount: recentArticles.length > 5 ? 5 : recentArticles.length,
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildNotificationBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildSectionHeader('Vidéos à la une', '/thix-info/videos')),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          
          // Vidéos
          if (isLoading && videos.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_InfoColors.primaryBlue),
                  ),
                ),
              ),
            )
          else if (videos.isEmpty && !isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucune vidéo disponible',
                    style: TextStyle(color: _InfoColors.mutedText),
                  ),
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: videos.length,
                  itemBuilder: (context, index) => _buildVideoCard(videos[index]),
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // HEADER — dégradé incurvé bleu institutionnel
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_InfoColors.navyDeep, _InfoColors.navy, _InfoColors.primaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x332D6CDF), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(9)),
                        child: const Icon(Icons.newspaper_rounded, size: 15, color: _InfoColors.gold),
                      ),
                      const SizedBox(width: 7),
                      const Text('THIX INFO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5, letterSpacing: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('L\'information vraie, partout.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Row(
                children: [
                  _headerIconButton(Icons.notifications_none_rounded, () => _showNotificationSettings()),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Icon(Icons.person_rounded, size: 15, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  // ============================================================
  // BARRE DE RECHERCHE
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/thix-info/search'),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _InfoColors.pureWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _InfoColors.border),
            boxShadow: [BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 17, color: _InfoColors.mutedText),
              SizedBox(width: 9),
              Text('Rechercher une actualité, un sujet...', style: TextStyle(fontSize: 12.5, color: _InfoColors.mutedText)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATÉGORIES
  // ============================================================
  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['slug'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() => _selectedCategory = cat['slug']);
                context.read<NewsProvider>().fetchArticles(category: cat['slug']);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected ? const LinearGradient(colors: [_InfoColors.navyDeep, _InfoColors.primaryBlue]) : null,
                  color: isSelected ? null : _InfoColors.pureWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? Colors.transparent : _InfoColors.border),
                  boxShadow: isSelected
                      ? [BoxShadow(color: _InfoColors.primaryBlue.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat['icon'] as IconData, size: 13, color: isSelected ? Colors.white : _InfoColors.navy),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : _InfoColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ARTICLE À LA UNE
  // ============================================================
  Widget _buildFeaturedArticle(NewsArticle article) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${article.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _InfoColors.pureWhite,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _InfoColors.border),
          boxShadow: [BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Image.network(
                  article.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: _InfoColors.softBlue,
                      child: const Center(child: CircularProgressIndicator(color: _InfoColors.primaryBlue)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: _InfoColors.softBlue,
                    child: Icon(Icons.broken_image_rounded, size: 38, color: _InfoColors.navy.withOpacity(0.4)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3, color: _InfoColors.darkText)),
                  const SizedBox(height: 6),
                  Text(article.summary ?? '', style: const TextStyle(fontSize: 12, color: _InfoColors.mutedText, height: 1.4), maxLines: 3),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: _InfoColors.mutedText),
                      const SizedBox(width: 4),
                      Text(_formatTimeAgo(article.publishedAt), style: const TextStyle(fontSize: 10, color: _InfoColors.mutedText)),
                      const SizedBox(width: 12),
                      const Icon(Icons.visibility_rounded, size: 12, color: _InfoColors.mutedText),
                      const SizedBox(width: 4),
                      Text(_formatCount(article.viewsCount), style: const TextStyle(fontSize: 10, color: _InfoColors.mutedText)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text('Lire l\'article', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _InfoColors.primaryBlue)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: _InfoColors.primaryBlue),
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

  // ============================================================
  // ARTICLE RÉCENT (item liste)
  // ============================================================
  Widget _buildRecentArticleItem(NewsArticle article) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${article.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _InfoColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _InfoColors.border),
          boxShadow: [BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  article.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      color: _InfoColors.softBlue,
                      child: const Center(child: CircularProgressIndicator(color: _InfoColors.primaryBlue)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: _InfoColors.softBlue,
                    child: Icon(Icons.broken_image_rounded, size: 26, color: _InfoColors.navy.withOpacity(0.4)),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: _InfoColors.softBlue, borderRadius: BorderRadius.circular(6)),
                        child: Text(_getCategoryName(article.category), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _InfoColors.navy)),
                      ),
                      const SizedBox(width: 6),
                      Text(_formatTimeAgo(article.publishedAt), style: const TextStyle(fontSize: 9, color: _InfoColors.mutedText)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(article.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _InfoColors.darkText), maxLines: 2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 10, color: _InfoColors.mutedText.withOpacity(0.8)),
                      const SizedBox(width: 2),
                      Text(_formatCount(article.viewsCount), style: TextStyle(fontSize: 9, color: _InfoColors.mutedText.withOpacity(0.8))),
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

  // ============================================================
  // CARTE VIDÉO
  // ============================================================
  Widget _buildVideoCard(NewsArticle video) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${video.id}'),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _InfoColors.pureWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _InfoColors.border),
          boxShadow: [BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    video.imageUrl ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: _InfoColors.softBlue,
                        child: const Center(
                          child: CircularProgressIndicator(color: _InfoColors.primaryBlue),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: _InfoColors.softBlue,
                      child: Icon(Icons.videocam_rounded, size: 38, color: _InfoColors.navy.withOpacity(0.4)),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(color: _InfoColors.navyDeep.withOpacity(0.55), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _InfoColors.darkText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 10, color: _InfoColors.mutedText.withOpacity(0.8)),
                      const SizedBox(width: 2),
                      Text(_formatCount(video.viewsCount), style: TextStyle(fontSize: 9, color: _InfoColors.mutedText.withOpacity(0.8))),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(fontSize: 9, color: _InfoColors.mutedText.withOpacity(0.5))),
                      const SizedBox(width: 6),
                      Text(_formatTimeAgo(video.publishedAt), style: TextStyle(fontSize: 9, color: _InfoColors.mutedText.withOpacity(0.8))),
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

  // ============================================================
  // EN-TÊTE DE SECTION
  // ============================================================
  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _InfoColors.darkText)),
          GestureDetector(
            onTap: () => context.push(route),
            child: const Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 11.5, color: _InfoColors.primaryBlue, fontWeight: FontWeight.w700)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: _InfoColors.primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANNIÈRE NOTIFICATIONS
  // ============================================================
  Widget _buildNotificationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_InfoColors.navyDeep, _InfoColors.navy, _InfoColors.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.notifications_active_rounded, color: _InfoColors.gold, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Restez informé en temps réel !', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Activez les notifications pour ne rien manquer', style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 9.5, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _requestNotificationPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(color: _InfoColors.gold, borderRadius: BorderRadius.circular(20)),
              child: const Text('Activer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _InfoColors.navyDeep)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE NAVIGATION BOTTOM — flottante, incurvée
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      decoration: BoxDecoration(
        color: _InfoColors.pureWhite,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.12), blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Accueil', 0),
              _navItem(Icons.category_rounded, 'Catégories', 1),
              _navItem(Icons.flash_on_rounded, 'Fil Info', 2),
              _navItem(Icons.bookmark_rounded, 'Favoris', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _onNavTap(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSelected ? _InfoColors.softBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? _InfoColors.primaryBlue : _InfoColors.mutedText, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                color: isSelected ? _InfoColors.primaryBlue : _InfoColors.mutedText,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return 'il y a ${diff.inDays}j';
    if (diff.inHours >= 1) return 'il y a ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'il y a ${diff.inMinutes}min';
    return 'maintenant';
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  String _getCategoryName(String slug) {
    final cat = _categories.firstWhere((c) => c['slug'] == slug, orElse: () => {'name': slug});
    return cat['name'] as String;
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _InfoColors.darkText)),
        content: const Text('Recevoir les alertes en temps réel ?', style: TextStyle(fontSize: 13, color: _InfoColors.mutedText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard', style: TextStyle(fontSize: 12))),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: _InfoColors.gold,
              foregroundColor: _InfoColors.navyDeep,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Activer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _requestNotificationPermission() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications activées'), duration: Duration(seconds: 1)),
    );
  }
}
