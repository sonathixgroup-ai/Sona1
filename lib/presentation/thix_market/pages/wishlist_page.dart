import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CHARTE GRAPHIQUE THIX MARKET
// ============================================================
class _MarketColors {
  static const Color red = Color(0xFFD81E2C);
  static const Color gold = Color(0xFFF0A93B);
  static const Color lightBg = Color(0xFFF7F7FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF8A8A8F);
  static const Color cardBorder = Color(0xFFF0F0F0);
  static const Color successGreen = Color(0xFF00B074);
  static const Color creamBg = Color(0xFFFCEFDA);
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _wishlistItems = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  // ============================================================
  // LOGIQUE DE DONNÉES (100% SUPABASE)
  // ============================================================
  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      if (userId == null) {
        setState(() {
          _wishlistItems = [];
          _isLoading = false;
        });
        return;
      }

      // Récupération des favoris avec jointure sur la table produits
      final response = await Supabase.instance.client
          .from('wishlist')
          .select('''
            id,
            product_id,
            products (
              title,
              image_url,
              price,
              currency,
              stock
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> formattedItems = (response as List).map((item) {
        final product = item['products'] as Map<String, dynamic>? ?? {};
        
        return {
          'wishlist_id': item['id'].toString(),
          'product_id': item['product_id'].toString(),
          'title': product['title'] ?? 'Produit indisponible',
          'image_url': product['image_url'] ?? '',
          'price': product['price'] ?? 0,
          'currency': product['currency'] ?? 'FC',
          'stock': product['stock'] ?? 0,
        };
      }).toList();

      setState(() {
        _wishlistItems = formattedItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur Supabase (Wishlist) : $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger vos favoris'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeFromWishlist(String wishlistId) async {
    try {
      await Supabase.instance.client
          .from('wishlist')
          .delete()
          .eq('id', wishlistId);
          
      setState(() {
        _wishlistItems.removeWhere((item) => item['wishlist_id'] == wishlistId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit retiré des favoris'), backgroundColor: _MarketColors.successGreen),
        );
      }
    } catch (e) {
      debugPrint('Erreur suppression favori : $e');
    }
  }

  Future<void> _addToCart(String productId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Vérifier si le produit est déjà dans le panier
      final existing = await Supabase.instance.client
          .from('cart')
          .select()
          .match({'user_id': userId, 'product_id': productId})
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('cart')
            .update({'quantity': (existing['quantity'] as int) + 1})
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('cart')
            .insert({
              'user_id': userId,
              'product_id': productId,
              'quantity': 1,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté au panier !'), backgroundColor: _MarketColors.successGreen),
        );
      }
    } catch (e) {
      debugPrint('Erreur ajout panier : $e');
    }
  }

  // ============================================================
  // INTERFACE UTILISATEUR
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        backgroundColor: _MarketColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _MarketColors.darkText),
        title: const Text(
          'Mes Favoris',
          style: TextStyle(color: _MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _MarketColors.cardBorder, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _MarketColors.red));
    }

    if (_wishlistItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: _MarketColors.red,
      onRefresh: _loadWishlist,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _wishlistItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildWishlistCard(_wishlistItems[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: _MarketColors.creamBg, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border_rounded, size: 64, color: _MarketColors.red),
            ),
            const SizedBox(height: 24),
            const Text('Votre liste est vide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _MarketColors.darkText)),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas encore ajouté de produits à vos favoris. Explorez le marché pour trouver ce qu\'il vous faut.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _MarketColors.mutedText, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/market/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _MarketColors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text('Explorer le marché', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> item) {
    final price = (item['price'] as num).toDouble();
    final currency = item['currency'] as String;
    final stock = item['stock'] as int;
    final isAvailable = stock > 0;

    return Dismissible(
      key: Key(item['wishlist_id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (direction) => _removeFromWishlist(item['wishlist_id']),
      child: GestureDetector(
        onTap: () => context.push('/market/product/${item['product_id']}'),
        child: Container(
          decoration: BoxDecoration(
            color: _MarketColors.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _MarketColors.cardBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: _MarketColors.lightBg,
                    child: CachedNetworkImage(
                      imageUrl: item['image_url'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _MarketColors.red)),
                      errorWidget: (context, url, error) => const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Détails
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'], 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _MarketColors.darkText, height: 1.2)
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${price.toInt()} $currency', 
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: _MarketColors.red)
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAvailable ? 'En stock' : 'Rupture de stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAvailable ? _MarketColors.successGreen : _MarketColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bouton Panier
                if (isAvailable)
                  IconButton(
                    onPressed: () => _addToCart(item['product_id']),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _MarketColors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shopping_cart_outlined, color: _MarketColors.red, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
