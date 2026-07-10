import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../widgets/products/product_card.dart';

class BuyPage extends StatefulWidget {
  const BuyPage({super.key});

  @override
  State<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all';
  final ScrollController _scrollController = ScrollController();

  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color bgLight = Color(0xFFF8F9FA);

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
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<ProductProvider>();
    await Future.wait([
      provider.loadProducts(category: _selectedCategory),
      provider.loadFavorites(),
      provider.loadWishlist(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: bgLight,
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
          indicatorColor: primaryBlue,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows, color: Colors.black87),
            onPressed: () => context.push('/market/compare'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.black87),
            onPressed: () => context.push('/market/price-alerts'),
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
          _buildExploreTab(productProvider),
          _buildFavoritesTab(productProvider),
          _buildWishlistTab(productProvider),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 1 : EXPLORER
  // ============================================================
  Widget _buildExploreTab(ProductProvider provider) {
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryBlue : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          category['icon'] as IconData,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? primaryBlue : Colors.grey[600],
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
                child: const Text(
                  'Filtres +',
                  style: TextStyle(color: primaryBlue),
                ),
              ),
            ],
          ),
        ),
        
        // Produits
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.products.isEmpty
                  ? _buildEmptyState('Aucun produit trouvé')
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: GridView.builder(
                        controller: _scrollController,
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
                            onTap: (_) => context.push('/market/product/${product['id']}'),
                            onFavoriteTap: (productId) => provider.toggleFavorite(productId),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon) {
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: Colors.grey[600]),
      onSelected: (_) {},
      backgroundColor: Colors.white,
      selectedColor: primaryBlue.withOpacity(0.1),
      side: BorderSide(color: Colors.grey[300]!),
    );
  }

  // ============================================================
  // TAB 2 : FAVORIS
  // ============================================================
  Widget _buildFavoritesTab(ProductProvider provider) {
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
          onTap: (_) => context.push('/market/product/${product['id']}'),
          onFavoriteTap: (productId) => provider.toggleFavorite(productId),
        );
      },
    );
  }

  // ============================================================
  // TAB 3 : WISHLIST
  // ============================================================
  Widget _buildWishlistTab(ProductProvider provider) {
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item['image_url'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 24),
                ),
              ),
            ),
            title: Text(
              item['name'] ?? 'Produit',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${item['price']?.toInt() ?? 0} FCFA',
              style: const TextStyle(color: primaryBlue),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => provider.removeFromWishlist(item['id']),
            ),
            onTap: () => context.push('/market/product/${item['product_id']}'),
          ),
        );
      },
    );
  }

  // ============================================================
  // ÉTATS VIDE
  // ============================================================
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
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
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(title == 'Wishlist vide' ? 'Créer ma wishlist' : 'Explorer'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIALOGUES
  // ============================================================
  void _showAdvancedFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

// ============================================================
// WIDGETS ANNEXES
// ============================================================
class AdvancedFiltersSheet extends StatelessWidget {
  const AdvancedFiltersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔧 Variables d'état locales (si on veut les rendre interactives)
    // Ici on les simule avec des valeurs statiques pour l'exemple.
    RangeValues _priceRange = const RangeValues(0, 1000000);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres avancés',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('Prix (FCFA)', style: TextStyle(fontWeight: FontWeight.w500)),
          // ✅ Correction : ajout de onChanged et suppression du const
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1000000,
            divisions: 10,
            onChanged: (newValues) {
              // Ici on mettrait à jour l'état si le widget était Stateful
              // Pour l'instant, on ne fait rien (exemple non interactif)
              // Mais on peut afficher les valeurs dans un Text par exemple.
            },
          ),
          const SizedBox(height: 20),
          const Text('Catégories', style: TextStyle(fontWeight: FontWeight.w500)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Mode', 'Électronique', 'Maison', 'Services', 'Véhicules'].map((cat) {
              return FilterChip(
                label: Text(cat),
                selected: false,
                onSelected: (_) {},
              );
            }).toList(),
          ),
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
                    backgroundColor: const Color(0xFF1A73E8),
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
            backgroundColor: const Color(0xFF1A73E8),
          ),
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
