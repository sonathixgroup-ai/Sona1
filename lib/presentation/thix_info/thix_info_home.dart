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
    {'slug': 'featured', 'name': 'À la une', 'icon': Icons.local_fire_department},
    {'slug': 'politique', 'name': 'Politique', 'icon': Icons.account_balance},
    {'slug': 'economie', 'name': 'Économie', 'icon': Icons.trending_up},
    {'slug': 'societe', 'name': 'Société', 'icon': Icons.people},
    {'slug': 'tech', 'name': 'Tech', 'icon': Icons.computer},
    {'slug': 'sport', 'name': 'Sport', 'icon': Icons.sports_soccer},
    {'slug': 'culture', 'name': 'Culture', 'icon': Icons.museum},
    {'slug': 'international', 'name': 'International', 'icon': Icons.public},
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
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
          ),
        ),
      );
    }

    // Afficher une erreur si nécessaire
    if (hasError && featuredArticle == null && recentArticles.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger les actualités',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                newsProvider.error ?? 'Erreur inconnue',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0B1B3D),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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
                    style: TextStyle(color: Colors.grey),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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
                    style: TextStyle(color: Colors.grey),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B3D), Color(0xFF1A2B4D)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIX INFO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 2),
                  Text('L\'information vraie, partout.', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                    onPressed: () => _showNotificationSettings(),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: const CircleAvatar(radius: 14, backgroundColor: Colors.white24, child: Icon(Icons.person, size: 14, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: GestureDetector(
        onTap: () => context.push('/thix-info/search'),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 16, color: Colors.grey),
              SizedBox(width: 8),
              Text('Rechercher une actualité, un sujet...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['slug'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat['name'], style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat['slug']);
                  context.read<NewsProvider>().fetchArticles(category: cat['slug']);
                }
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFD4AF37).withOpacity(0.15),
              checkmarkColor: const Color(0xFFD4AF37),
              side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedArticle(NewsArticle article) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${article.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  article.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(article.summary ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4), maxLines: 3),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(_formatTimeAgo(article.publishedAt), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      const SizedBox(width: 12),
                      Icon(Icons.visibility, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(_formatCount(article.viewsCount), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Lire l\'article', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37))),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 12, color: const Color(0xFFD4AF37)),
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

  Widget _buildRecentArticleItem(NewsArticle article) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${article.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
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
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(_getCategoryName(article.category), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37))),
                      ),
                      const SizedBox(width: 6),
                      Text(_formatTimeAgo(article.publishedAt), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(article.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(_formatCount(article.viewsCount), style: TextStyle(fontSize: 9, color: Colors.grey[400])),
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

  Widget _buildVideoCard(NewsArticle video) {
    return GestureDetector(
      onTap: () => context.push('/thix-info/article/${video.id}'),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    video.imageUrl ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 140,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 140,
                      color: Colors.grey[200],
                      child: const Icon(Icons.videocam, size: 40, color: Colors.grey),
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
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Text(_formatCount(video.viewsCount), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                      const SizedBox(width: 6),
                      Text(_formatTimeAgo(video.publishedAt), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
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

  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => context.push(route),
            child: Row(
              children: [
                Text('Voir tout', style: TextStyle(fontSize: 11, color: const Color(0xFFD4AF37))),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, size: 10, color: const Color(0xFFD4AF37)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B3D), Color(0xFF1A2B4D)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active, color: Color(0xFFD4AF37), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Restez informé en temps réel !', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Activez les notifications pour ne rien manquer', style: TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _requestNotificationPermission,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(20)),
              child: const Text('Activer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0B1B3D))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 9),
        unselectedLabelStyle: const TextStyle(fontSize: 9),
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 20), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.category, size: 20), label: 'Catégories'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on, size: 20), label: 'Fil Info'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark, size: 20), label: 'Favoris'),
        ],
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
        title: const Text('Notifications', style: TextStyle(fontSize: 16)),
        content: const Text('Recevoir les alertes en temps réel ?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard', style: TextStyle(fontSize: 12))),
          ElevatedButton(
            onPressed: _requestNotificationPermission,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('Activer', style: TextStyle(fontSize: 12)),
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
