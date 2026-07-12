// lib/presentation/thix_info/thix_info_home.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../providers/news_provider.dart';
import '../../models/news_article.dart';

// ============================================================
// CHARTE GRAPHIQUE UNIFIÉE — Style "Mon Pays" / Événement / Emploi
// ============================================================
class _InfoColors {
  static const Color primaryBlue = Color(0xFF0B3D91);
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color lightBg = Color(0xFFF6F8FB);
  static const Color gold = Color(0xFFF7C948);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color cardBorder = Color(0xFFEEF1F7);
  static const Color darkText = Color(0xFF10182B);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softBlue = Color(0xFFEEF1F7);
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
    await Future.delayed(Duration.zero);
    
    if (mounted) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      
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

    if (!_isInitialized && isLoading) {
      return const Scaffold(
        backgroundColor: _InfoColors.lightBg,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_InfoColors.primaryBlue),
          ),
        ),
      );
    }

    if (hasError && featuredArticle == null && recentArticles.isEmpty) {
      return Scaffold(
        backgroundColor: _InfoColors.lightBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: _InfoColors.softBlue, shape: BoxShape.circle),
                child: Icon(Icons.error_outline_rounded, size: 38, color: _InfoColors.primaryBlue.withOpacity(0.5)),
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
                  backgroundColor: _InfoColors.primaryBlue,
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
      backgroundColor: _InfoColors.lightBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildCategorySection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFeaturedArticle(featuredArticle),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          
          // Actualités récentes
          SliverToBoxAdapter(child: _buildSectionHeader('Actualités récentes', '/thix-info/recent')),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRecentArticleItem(recentArticles[index]),
                  childCount: recentArticles.length > 5 ? 5 : recentArticles.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildNotificationBanner(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(child: _buildSectionHeader('Vidéos à la une', '/thix-info/videos')),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: videos.length,
                  itemBuilder: (context, index) => _buildVideoCard(videos[index]),
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_InfoColors.navyDeep, _InfoColors.primaryBlue],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x332D6CDF), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go('/'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THIX INFO',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                ),
                SizedBox(height: 2),
                Text(
                  'L\'information vraie, partout.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none, 
            children: [
              InkWell(
                onTap: () => _showNotificationSettings(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 20),
                ),
              ),
              Positioned(
                top: -4, 
                right: -4, 
                child: Container(
                  padding: const EdgeInsets.all(4), 
                  decoration: const BoxDecoration(color: _InfoColors.gold, shape: BoxShape.circle), 
                  child: const Text('3', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _InfoColors.primaryBlue))
                )
              ),
            ]
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE RECHERCHE
  // ============================================================
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => context.push('/thix-info/search'),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _InfoColors.pureWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _InfoColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: _InfoColors.mutedText),
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
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Catégories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _InfoColors.primaryBlue),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? _InfoColors.primaryBlue : _InfoColors.pureWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.transparent : _InfoColors.cardBorder),
                      boxShadow: isSelected
                          ? [BoxShadow(color: _InfoColors.primaryBlue.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat['icon'] as IconData, size: 14, color: isSelected ? _InfoColors.gold : _InfoColors.primaryBlue),
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
        ),
      ],
    );
  }

  // ============================================================
  // ARTICLE À LA UNE
  // ============================================================
  Widget _buildFeaturedArticle(NewsArticle article) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${article.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: _InfoColors.navyDeep.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              Image.network(
                article.imageUrl!,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(height: 240, color: _InfoColors.softBlue, child: const Center(child: CircularProgressIndicator(color: _InfoColors.primaryBlue)));
                },
                errorBuilder: (context, error, stackTrace) => Container(height: 240, color: _InfoColors.softBlue, child: Icon(Icons.broken_image_rounded, size: 38, color: _InfoColors.navy.withOpacity(0.4))),
              )
            else
              Container(height: 240, color: _InfoColors.navyDeep),
              
            Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [_InfoColors.primaryBlue.withOpacity(0.95), Colors.transparent],
                  stops: const [0, 0.7],
                ),
              ),
            ),
            
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _InfoColors.gold, borderRadius: BorderRadius.circular(8)),
                child: const Text('À LA UNE', style: TextStyle(fontSize: 9, color: _InfoColors.navyDeep, fontWeight: FontWeight.w900)),
              ),
            ),
            
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w900, height: 1.15),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(6)),
                        child: Text(_getCategoryName(article.category), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatTimeAgo(article.publishedAt), style: const TextStyle(fontSize: 11, color: _InfoColors.gold, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.visibility_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(_formatCount(article.viewsCount), style: const TextStyle(fontSize: 11, color: Colors.white70)),
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _InfoColors.primaryBlue)),
          GestureDetector(
            onTap: () => context.push(route),
            child: const Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 12, color: Color(0xFF5B8DEF), fontWeight: FontWeight.w700)),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF5B8DEF)),
              ],
            ),
          ),
        ],
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _InfoColors.pureWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _InfoColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  article.imageUrl!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(width: 70, height: 70, color: _InfoColors.softBlue, child: const Center(child: CircularProgressIndicator(color: _InfoColors.primaryBlue)));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: _InfoColors.softBlue, child: Icon(Icons.broken_image_rounded, size: 26, color: _InfoColors.primaryBlue)),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: _InfoColors.softBlue, borderRadius: BorderRadius.circular(6)),
                        child: Text(_getCategoryName(article.category), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _InfoColors.primaryBlue)),
                      ),
                      const Spacer(),
                      Text(_formatTimeAgo(article.publishedAt), style: const TextStyle(fontSize: 10, color: _InfoColors.mutedText)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(article.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _InfoColors.darkText, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
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
          border: Border.all(color: _InfoColors.cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  video.imageUrl ?? '',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(height: 150, color: _InfoColors.softBlue, child: const Center(child: CircularProgressIndicator(color: _InfoColors.primaryBlue)));
                  },
                  errorBuilder: (context, error, stackTrace) => Container(height: 150, color: _InfoColors.softBlue, child: Icon(Icons.videocam_rounded, size: 38, color: _InfoColors.primaryBlue)),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _InfoColors.navyDeep.withOpacity(0.7), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _InfoColors.darkText, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded, size: 12, color: _InfoColors.mutedText),
                      const SizedBox(width: 4),
                      Text(_formatCount(video.viewsCount), style: const TextStyle(fontSize: 10, color: _InfoColors.mutedText)),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(fontSize: 10, color: _InfoColors.mutedText.withOpacity(0.5))),
                      const SizedBox(width: 8),
                      Text(_formatTimeAgo(video.publishedAt), style: const TextStyle(fontSize: 10, color: _InfoColors.mutedText)),
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
  // BANNIÈRE NOTIFICATIONS
  // ============================================================
  Widget _buildNotificationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _InfoColors.primaryBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _InfoColors.primaryBlue.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_rounded, color: _InfoColors.gold, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Alerte Info', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('Soyez notifié des actus importantes.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: _InfoColors.gold,
              foregroundColor: _InfoColors.primaryBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Activer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BARRE DE NAVIGATION BOTTOM
  // ============================================================
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), 
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)]
      ), 
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, 
          children: [
            _navItem(Icons.home_rounded, 'Accueil', 0), 
            _navItem(Icons.category_rounded, 'Catégories', 1), 
            _navItem(Icons.flash_on_rounded, 'Fil Info', 2), 
            _navItem(Icons.bookmark_rounded, 'Favoris', 3), 
          ]
        ),
      )
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index), 
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? _InfoColors.primaryBlue : _InfoColors.mutedText, size: 22), 
          Text(label, style: TextStyle(fontSize: 10, color: isSelected ? _InfoColors.primaryBlue : _InfoColors.mutedText, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
        ]
      )
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
            onPressed: () {
              Navigator.pop(context);
              _requestNotificationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _InfoColors.gold,
              foregroundColor: _InfoColors.primaryBlue,
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
