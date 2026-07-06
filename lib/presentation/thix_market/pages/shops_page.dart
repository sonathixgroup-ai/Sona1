import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../providers/shop_provider.dart';

class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<ShopProvider>();
    await Future.wait([
      provider.loadMyShops(),
      provider.loadFollowedShops(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Boutiques',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes boutiques'),
            Tab(text: 'Boutiques suivies'),
          ],
          indicatorColor: const Color(0xFFE5592F),
          labelColor: const Color(0xFFE5592F),
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.black87),
              onPressed: () => context.push('/market/shop/create'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyShops(shopProvider),
          _buildFollowedShops(shopProvider),
        ],
      ),
    );
  }

  Widget _buildMyShops(ShopProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.myShops.isEmpty) {
      return _buildEmptyState(
        'Vous n\'avez pas encore de boutique',
        'Créez votre première boutique pour commencer à vendre',
        Icons.store,
        () => context.push('/market/shop/create'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.myShops.length,
        itemBuilder: (context, index) {
          final shop = provider.myShops[index];
          return _buildShopCard(shop, isOwner: true);
        },
      ),
    );
  }

  Widget _buildFollowedShops(ShopProvider provider) {
    if (provider.isLoadingFollowed) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.followedShops.isEmpty) {
      return _buildEmptyState(
        'Aucune boutique suivie',
        'Suivez des boutiques pour voir leurs nouveautés',
        Icons.favorite_border,
        () => context.push('/market/search'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: provider.followedShops.length,
        itemBuilder: (context, index) {
          final shop = provider.followedShops[index];
          return _buildShopCard(shop, isOwner: false);
        },
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, {required bool isOwner}) {
    final isActive = shop['status'] == 'active';
    final isVerified = shop['is_verified'] == true;
    final isFollowed = shop['is_followed'] == true;
    final followers = shop['followers'] ?? 0;
    final productsCount = shop['products_count'] ?? 0;
    final rating = (shop['rating'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => context.push('/market/shop/${shop['id']}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En‑tête : logo + nom
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          image: shop['logo_url'] != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(shop['logo_url']),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: shop['logo_url'] == null
                            ? const Icon(Icons.store, size: 32, color: Colors.grey)
                            : null,
                      ),
                      if (isVerified)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      if (!isActive)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Inactif',
                              style: TextStyle(color: Colors.white, fontSize: 9),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop['name'] ?? 'Boutique',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isOwner)
                              IconButton(
                                onPressed: () => _toggleFollow(shop['id']),
                                icon: Icon(
                                  isFollowed ? Icons.favorite : Icons.favorite_border,
                                  color: isFollowed ? Colors.red : Colors.grey[400],
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        RatingBar.builder(
                          initialRating: rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 14,
                          ignoreGestures: true,
                          itemBuilder: (_, __) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (_) {},
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.shopping_bag, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              '$productsCount produits',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.favorite, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              _formatNumber(followers),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Description
              if (shop['description'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  shop['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],

              // Actions (propriétaire)
              if (isOwner) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/market/shop/${shop['id']}/manage'),
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Gérer'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/market/shop/${shop['id']}/stats'),
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text('Stats'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareShop(shop['id']),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Partager'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback onAction) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(title.contains('pas encore de boutique') ? 'Créer ma boutique' : 'Découvrir'),
          ),
        ],
      ),
    );
  }

  // =============================
  // ACTIONS
  // =============================
  void _toggleFollow(String shopId) {
    context.read<ShopProvider>().toggleFollowShop(shopId);
  }

  void _shareShop(String shopId) {
    // Ouvrir la modale de partage (QR, lien, etc.)
    // ou utiliser le widget ShareShopQr directement
    context.push('/market/shop/$shopId/share');
  }

  String _formatNumber(int num) {
    if (num >= 1_000_000) return '${(num / 1_000_000).toStringAsFixed(1)}M';
    if (num >= 1_000) return '${(num / 1_000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
