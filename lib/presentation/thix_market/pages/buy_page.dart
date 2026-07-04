import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../widgets/product/product_card.dart';

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';

  final List<Map<String, dynamic>> categories = [
    {'id': 'all', 'name': 'Tous', 'icon': Icons.apps},
    {'id': 'fashion', 'name': 'Mode', 'icon': Icons.checkroom},
    {'id': 'electronics', 'name': 'Électronique', 'icon': Icons.phone_android},
    {'id': 'home', 'name': 'Maison', 'icon': Icons.home},
    {'id': 'services', 'name': 'Services', 'icon': Icons.build},
    {'id': 'vehicles', 'name': 'Véhicules', 'icon': Icons.directions_car},
    {'id': 'realestate', 'name': 'Immobilier', 'icon': Icons.house},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(category: _selectedCategory);
      context.read<ProductProvider>().loadFavorites();
      context.read<ProductProvider>().loadWishlist();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Acheter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explorer'),
            Tab(text: 'Favoris'),
            Tab(text: 'Wishlist'),
          ],
          indicatorColor: const Color(0xFFE5592F),
          labelColor: const Color(0xFFE5592F),
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => _openComparator(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            onPressed: () => _manageAlerts(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(productProvider, theme),
          _buildFavoritesTab(productProvider, theme),
          _buildWishlistTab(productProvider, theme),
        ],
      ),
    );
  }

  Widget _buildExploreTab(ProductProvider provider, ThemeData theme) {
    return Column(
      children: [
        // Catégories horizontales
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category['id'];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = category['id']);
                  provider.loadProducts(category: category['id']);
                },
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE5592F)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? const Color(0xFFE5592F) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Filtres rapides
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildQuickFilterChip('Prix', Icons.attach_money),
              const SizedBox(width: 8),
              _buildQuickFilterChip('Distance', Icons.location_on),
              const SizedBox(width: 8),
              _buildQuickFilterChip('Note', Icons.star),
              const Spacer(),
              TextButton(
                onPressed: () => _showAdvancedFilters(),
                child: const Text('Filtres +'),
              ),
            ],
          ),
        ),
        
        // Produits
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.products.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.products.length,
                      itemBuilder: (context, index) {
                        final product = provider.products[index];
                        return ProductCard(
                          product: product,
                          showFavoriteButton: true,
                          onTap: () => _gotoProductDetail(product['id']),
                          onFavoriteTap: () => provider.toggleFavorite(product['id']),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      onSelected: (_) {},
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFE5592F).withOpacity(0.1),
      side: BorderSide(color: Colors.grey[300]!),
    );
  }

  Widget _buildFavoritesTab(ProductProvider provider, ThemeData theme) {
    if (provider.isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.favorites.isEmpty) {
      return _buildEmptyStateWithAction(
        'Aucun favori',
        'Ajoutez des produits à vos favoris pour les retrouver facilement',
        Icons.favorite_border,
        () => _tabController.animateTo(0),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.favorites.length,
      itemBuilder: (context, index) {
        final product = provider.favorites[index];
        return ProductCard(
          product: product,
          showFavoriteButton: true,
          isFavorite: true,
          onTap: () => _gotoProductDetail(product['id']),
          onFavoriteTap: () => provider.toggleFavorite(product['id']),
        );
      },
    );
  }

  Widget _buildWishlistTab(ProductProvider provider, ThemeData theme) {
    if (provider.isLoadingWishlist) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.wishlist.isEmpty) {
      return _buildEmptyStateWithAction(
        'Wishlist vide',
        'Créez une liste de souhaits partageable',
        Icons.share,
        () => _createWishlist(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.wishlist.length,
      itemBuilder: (context, index) {
        final item = provider.wishlist[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item['image_url'],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(item['name']),
            subtitle: Text('${item['price']} FCFA'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => provider.removeFromWishlist(item['id']),
            ),
            onTap: () => _gotoProductDetail(item['product_id']),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun produit trouvé',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithAction(String title, String subtitle, IconData icon, VoidCallback onAction) {
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
            ),
            child: Text(title == 'Wishlist vide' ? 'Créer ma wishlist' : 'Explorer'),
          ),
        ],
      ),
    );
  }

  void _gotoProductDetail(String productId) {
    Navigator.pushNamed(context, '/product/$productId');
  }

  void _openComparator() {
    Navigator.pushNamed(context, '/compare-products');
  }

  void _manageAlerts() {
    Navigator.pushNamed(context, '/price-alerts');
  }

  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AdvancedFiltersSheet(),
    );
  }

  void _createWishlist() {
    showDialog(
      context: context,
      builder: (context) => const CreateWishlistDialog(),
    );
  }
}

class AdvancedFiltersSheet extends StatelessWidget {
  const AdvancedFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Filtres avancés', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // Range price slider
          // Categories
          // Brands
          // Rating filter
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Réinitialiser'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5592F),
                  ),
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreateWishlistDialog extends StatelessWidget {
  const CreateWishlistDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer une wishlist'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nom de la liste',
              hintText: 'Ex: Cadeaux Noël',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Liste publique'),
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Wishlist créée avec succès')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5592F),
          ),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
