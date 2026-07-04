import 'package:flutter/material.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShopProvider>().loadMyShops();
      context.read<ShopProvider>().loadFollowedShops();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mes Boutiques',
          style: TextStyle(fontWeight: FontWeight.bold),
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
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _createShop(),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyShops(shopProvider, theme),
          _buildFollowedShops(shopProvider, theme),
        ],
      ),
    );
  }

  Widget _buildMyShops(ShopProvider provider, ThemeData theme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.myShops.isEmpty) {
      return _buildEmptyState(
        'Vous n\'avez pas encore de boutique',
        'Créez votre première boutique pour commencer à vendre',
        Icons.store,
        () => _createShop(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.myShops.length,
      itemBuilder: (context, index) {
        final shop = provider.myShops[index];
        return _buildShopCard(shop, isOwner: true);
      },
    );
  }

  Widget _buildFollowedShops(ShopProvider provider, ThemeData theme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.followedShops.isEmpty) {
      return _buildEmptyState(
        'Aucune boutique suivie',
        'Suivez des boutiques pour voir leurs nouveautés',
        Icons.favorite_border,
        () => Navigator.pushNamed(context, '/discover-shops'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.followedShops.length,
      itemBuilder: (context, index) {
        final shop = provider.followedShops[index];
        return _buildShopCard(shop, isOwner: false);
      },
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop, {required bool isOwner}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _gotoShopDetail(shop['id']),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo boutique
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(shop['logo_url'] ?? ''),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: shop['is_verified'] == true
                        ? const Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(Icons.verified, color: Colors.blue, size: 16),
                          )
                        : null,
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
                                shop['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isOwner)
                              IconButton(
                                icon: Icon(
                                  shop['is_followed'] == true
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: shop['is_followed'] == true
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () => _toggleFollow(shop['id']),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RatingBar.builder(
                          initialRating: (shop['rating'] ?? 0).toDouble(),
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
                        Text(
                          '${shop['products_count'] ?? 0} produits · ${shop['followers'] ?? 0} abonnés',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (shop['description'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  shop['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              if (isOwner) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _manageShop(shop['id']),
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Gérer'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewStats(shop['id']),
                        icon: const Icon(Icons.bar_chart, size: 18),
                        label: const Text('Statistiques'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
            child: Text(title == 'Vous n\'avez pas encore de boutique' ? 'Créer ma boutique' : 'Découvrir'),
          ),
        ],
      ),
    );
  }

  void _createShop() {
    Navigator.pushNamed(context, '/create-shop');
  }

  void _gotoShopDetail(String shopId) {
    Navigator.pushNamed(context, '/shop/$shopId');
  }

  void _manageShop(String shopId) {
    Navigator.pushNamed(context, '/manage-shop/$shopId');
  }

  void _viewStats(String shopId) {
    Navigator.pushNamed(context, '/shop-stats/$shopId');
  }

  void _toggleFollow(String shopId) {
    context.read<ShopProvider>().toggleFollowShop(shopId);
  }
}
