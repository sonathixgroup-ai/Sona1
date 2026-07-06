// lib/presentation/thix_market/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../cart/cart_provider.dart';
import '../widgets/products/product_card.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic> _product = {};
  List<Map<String, dynamic>> _similarProducts = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  int _selectedQuantity = 1;
  String? _selectedVariant;
  String? _selectedColor;
  bool _isAddingToCart = false;

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Couleurs harmonisées avec la page d'accueil
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color lightBlue = Color(0xFFE8F4FD);
  static const Color softBlue = Color(0xFFF0F7FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color gold = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── CHARGEMENT DU PRODUIT ───
  Future<void> _loadProductDetail() async {
    setState(() => _isLoading = true);
    try {
      final productResponse = await Supabase.instance.client
          .from('products')
          .select('*')
          .eq('id', widget.productId)
          .maybeSingle();

      if (productResponse == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit introuvable')),
        );
        return;
      }

      Map<String, dynamic>? shopData;
      if (productResponse['shop_id'] != null) {
        shopData = await Supabase.instance.client
            .from('shops')
            .select('*')
            .eq('id', productResponse['shop_id'])
            .maybeSingle();
      }

      List<Map<String, dynamic>> reviews = [];
      try {
        final reviewsResponse = await Supabase.instance.client
            .from('reviews')
            .select('*, user:users(name, avatar)')
            .eq('product_id', widget.productId)
            .order('created_at', ascending: false);
        reviews = List<Map<String, dynamic>>.from(reviewsResponse);
      } catch (e) {
        debugPrint('Reviews loading failed: $e');
      }

      final product = {...productResponse};
      if (shopData != null) product['shop'] = shopData;
      product['reviews'] = reviews;
      product['reviews_count'] = reviews.length;
      if (reviews.isNotEmpty) {
        final avgRating = reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num).toDouble()) / reviews.length;
        product['rating'] = avgRating;
      } else {
        product['rating'] = 0;
      }

      setState(() {
        _product = product;
        _reviews = reviews;
        _isLoading = false;
      });

      await Future.wait([
        _loadSimilarProducts(),
        _checkIfFavorite(),
      ]);
    } catch (e) {
      debugPrint('Error loading product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSimilarProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, shop:shops(name, city)')
          .eq('category', _product['category'])
          .neq('id', widget.productId)
          .limit(10);
      setState(() {
        _similarProducts = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading similar products: $e');
    }
  }

  Future<void> _checkIfFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('wishlist')
          .select()
          .match({
            'user_id': userId,
            'product_id': widget.productId,
          })
          .maybeSingle();
      setState(() => _isFavorite = response != null);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }
    setState(() => _isFavorite = !_isFavorite);
    try {
      if (_isFavorite) {
        await Supabase.instance.client.from('wishlist').insert({
          'user_id': userId,
          'product_id': widget.productId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .match({
              'user_id': userId,
              'product_id': widget.productId,
            });
      }
    } catch (e) {
      setState(() => _isFavorite = !_isFavorite);
      debugPrint('Error toggling favorite: $e');
    }
  }

  void _openChatWithSeller() {
    final shopId = _product['shop_id'];
    final shopName = _product['shop']?['name'] ?? 'Vendeur';
    final shopAvatar = _product['shop']?['logo_url'];
    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendeur non disponible')),
      );
      return;
    }
    context.push('/market/chat/$shopId', extra: {
      'title': shopName,
      'userName': shopName,
      'userAvatar': shopAvatar,
    });
  }

  Future<void> _addToCart() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }
    setState(() => _isAddingToCart = true);
    try {
      final existing = await Supabase.instance.client
          .from('cart')
          .select()
          .match({
            'user_id': userId,
            'product_id': widget.productId,
          })
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('cart')
            .update({
              'quantity': (existing['quantity'] as int) + _selectedQuantity,
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('cart')
            .insert({
              'user_id': userId,
              'product_id': widget.productId,
              'quantity': _selectedQuantity,
              'variant': _selectedVariant,
              'color': _selectedColor,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté au panier'), duration: Duration(seconds: 1)),
        );
        final cartProvider = context.read<CartProvider>();
        await cartProvider.loadCart();
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  // ✅ Correction : ajout des vérifications pour éviter l'erreur "Produit introuvable"
  void _buyNow() async {
    if (_product.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le produit n’est pas encore chargé.')),
      );
      return;
    }
    if ((_product['stock'] ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit en rupture de stock.')),
      );
      return;
    }
    await _addToCart();
    if (mounted) {
      context.push('/market/checkout');
    }
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: pureWhite,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: pureWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Produit introuvable', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      );
    }

    final hasDiscount = _product['discount_price'] != null &&
        _product['discount_price'] < _product['price'];
    final images = (_product['images'] as List?)?.cast<String>() ?? [_product['image_url'] ?? ''];
    final variants = _product['variants'] as List? ?? [];
    final colors = _product['colors'] as List? ?? [];
    final currency = _product['currency'] ?? 'CDF';
    final currencySymbol = currency == 'USD' ? '\$' : 'FC';

    final shippingCost = _product['shipping_cost'] as double?;
    final warrantyMonths = _product['warranty_months'] as int?;

    // ✅ Indique si le produit est disponible et chargé
    final isProductAvailable = !_product.isEmpty && (_product['stock'] ?? 0) > 0;

    return Scaffold(
      backgroundColor: pureWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: pureWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.black,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 300,
                      viewportFraction: 1,
                      onPageChanged: (index, _) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    items: images.map<Widget>((image) {
                      return CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(color: softBlue),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                      );
                    }).toList(),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentImageIndex + 1}/${images.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/market/shop/${_product['shop_id']}'),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: _product['shop']?['logo_url'] != null
                                  ? CachedNetworkImageProvider(_product['shop']['logo_url'])
                                  : null,
                              child: _product['shop']?['logo_url'] == null
                                  ? const Icon(Icons.store, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _product['shop']?['name'] ?? 'Boutique',
                                style: const TextStyle(fontWeight: FontWeight.w500, color: darkText),
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20, color: mutedText),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _product['title'] ?? '',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          RatingBar.builder(
                            initialRating: (_product['rating'] ?? 0).toDouble(),
                            minRating: 1,
                            direction: Axis.horizontal,
                            allowHalfRating: true,
                            itemCount: 5,
                            itemSize: 16,
                            ignoreGestures: true,
                            itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                            onRatingUpdate: (_) {},
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_product['reviews_count'] ?? 0} avis',
                            style: TextStyle(color: mutedText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            '${(hasDiscount ? _product['discount_price'] : _product['price']).toInt()} $currencySymbol',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          if (hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                '${_product['price'].toInt()} $currencySymbol',
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: mutedText,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if ((_product['stock'] ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Stock: ${_product['stock']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: (_product['stock'] ?? 0) < 10 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.grey[200]),
                if (variants.isNotEmpty) _buildVariantsSection(variants),
                if (colors.isNotEmpty) _buildColorsSection(colors),
                const Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _product['description'] ?? '',
                        style: TextStyle(height: 1.5, color: darkText),
                      ),
                      const SizedBox(height: 8),
                      if (_product['category'] != null)
                        Text('Catégorie : ${_product['category']}', style: TextStyle(color: mutedText)),
                      if (_product['condition'] != null)
                        Text('État : ${_product['condition']}', style: TextStyle(color: mutedText)),
                      if (_product['brand'] != null)
                        Text('Marque : ${_product['brand']}', style: TextStyle(color: mutedText)),
                      if (_product['free_shipping'] == true)
                        const Text('Livraison : Gratuite', style: TextStyle(color: Colors.green)),
                      if (_product['shipping_type'] != null)
                        Text('Type de livraison : ${_product['shipping_type']}', style: TextStyle(color: mutedText)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations de livraison',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.local_shipping,
                        'Frais de livraison',
                        shippingCost != null ? '${shippingCost.toInt()} $currencySymbol' : 'Non spécifié',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.verified,
                        'Garantie',
                        warrantyMonths != null ? '$warrantyMonths mois' : 'Non spécifiée',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.store,
                        'Retrait en magasin',
                        _product['shipping_type'] == 'pickup' || _product['shipping_type'] == 'both'
                            ? 'Disponible'
                            : 'Non disponible',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Avis clients',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                          ),
                          if (_reviews.isNotEmpty)
                            TextButton(
                              onPressed: _showAllReviews,
                              child: const Text('Voir tout', style: TextStyle(color: primaryBlue)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._reviews.take(3).map((review) => _buildReviewCard(review)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.grey[200]),
                if (_similarProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Produits similaires',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _similarProducts.length,
                            itemBuilder: (context, index) {
                              final product = _similarProducts[index];
                              return Container(
                                width: 150,
                                margin: const EdgeInsets.only(right: 12),
                                child: ProductCard(
                                  product: product,
                                  onTap: (_) {
                                    context.pushReplacement(
                                      '/market/product/${product['id']}',
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pureWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_selectedQuantity > 1) setState(() => _selectedQuantity--);
                      },
                      icon: const Icon(Icons.remove, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$_selectedQuantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_selectedQuantity < (_product['stock'] ?? 0)) {
                          setState(() => _selectedQuantity++);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ✅ Panier – désactivé si produit indisponible
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProductAvailable && !_isAddingToCart ? _addToCart : null,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart),
                  label: const Text('Panier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Chat
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openChatWithSeller,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    foregroundColor: mutedText,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // ✅ Acheter – désactivé si produit indisponible
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProductAvailable && !_isAddingToCart ? _buyNow : null,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Acheter'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryBlue),
                    foregroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── WIDGETS SECONDAIRES ───

  Widget _buildVariantsSection(List variants) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Variantes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: variants.map((variant) {
              final label = variant is String ? variant : variant['name']?.toString() ?? '';
              final isSelected = _selectedVariant == label;
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedVariant = selected ? label : null;
                  });
                },
                selectedColor: primaryBlue.withOpacity(0.1),
                checkmarkColor: primaryBlue,
                side: BorderSide(color: isSelected ? primaryBlue : Colors.grey[300]!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorsSection(List colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Couleurs',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final label = color is String ? color : color['name']?.toString() ?? '';
              final isSelected = _selectedColor == label;
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedColor = selected ? label : null;
                  });
                },
                selectedColor: primaryBlue.withOpacity(0.1),
                checkmarkColor: primaryBlue,
                side: BorderSide(color: isSelected ? primaryBlue : Colors.grey[300]!),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: mutedText),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: darkText)),
        const Spacer(),
        Text(value, style: TextStyle(color: mutedText)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map?;
    final avatar = user?['avatar'] as String?;
    final name = user?['name'] as String? ?? 'Utilisateur';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['created_at'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: avatar != null
                      ? CachedNetworkImageProvider(avatar)
                      : null,
                  child: avatar == null ? const Icon(Icons.person, size: 16) : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w500, color: darkText),
                      ),
                      RatingBar.builder(
                        initialRating: rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 12,
                        ignoreGestures: true,
                        itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
                        onRatingUpdate: (_) {},
                      ),
                    ],
                  ),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(createdAt)),
                    style: TextStyle(fontSize: 11, color: mutedText),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comment, style: const TextStyle(color: darkText)),
          ],
        ),
      ),
    );
  }

  void _showAllReviews() {
    if (_reviews.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Tous les avis',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    return _buildReviewCard(_reviews[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
