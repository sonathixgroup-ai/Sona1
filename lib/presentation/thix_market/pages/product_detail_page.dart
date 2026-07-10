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
import '../checkout/checkout_page.dart';

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

  // ─── Palette THIX ID ────────────────────────────────────────────
  static const Color thixOrange = Color(0xFFE5592F);
  static const Color softOrange = Color(0xFFFFF0EC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);

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
          const SnackBar(content: Text('Ajouté au panier avec succès !'), backgroundColor: Colors.green),
        );
        final cartProvider = context.read<CartProvider>();
        await cartProvider.loadCart();
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _buyNow() async {
    if (_product.isEmpty) return;
    if ((_product['stock'] ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit en rupture de stock.')),
      );
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      await _addToCart();
      final cartProvider = context.read<CartProvider>();
      await cartProvider.loadCart();

      if (cartProvider.cartItems.isEmpty) {
        throw Exception('Le panier est vide après ajout.');
      }

      if (mounted) {
        try {
          context.push('/market/checkout');
        } catch (e) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CheckoutPage()),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur dans _buyNow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: pureWhite,
        body: Center(child: CircularProgressIndicator(color: thixOrange)),
      );
    }

    if (_product.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: pureWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: darkText),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Produit introuvable', style: TextStyle(fontSize: 18, color: darkText)),
            ],
          ),
        ),
      );
    }

    final hasDiscount = _product['discount_price'] != null && _product['discount_price'] < _product['price'];
    final images = (_product['images'] as List?)?.cast<String>() ?? [_product['image_url'] ?? ''];
    final variants = _product['variants'] as List? ?? [];
    final colors = _product['colors'] as List? ?? [];
    final currency = _product['currency'] ?? 'CDF';
    final currencySymbol = currency == 'USD' ? '\$' : 'FC';

    final shippingCost = _product['shipping_cost'] as double?;
    final warrantyMonths = _product['warranty_months'] as int?;

    final isProductAvailable = !_product.isEmpty && (_product['stock'] ?? 0) > 0;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fond légèrement gris pour détacher les cartes
      body: CustomScrollView(
        slivers: [
          // ─── CAROUSEL D'IMAGES ───
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: pureWhite,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: darkText),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorite ? Colors.red : darkText,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0, top: 8.0, bottom: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: darkText),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 380,
                      viewportFraction: 1,
                      enableInfiniteScroll: images.length > 1,
                      onPageChanged: (index, _) {
                        setState(() => _currentImageIndex = index);
                      },
                    ),
                    items: images.map<Widget>((image) {
                      return CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => Container(color: Colors.grey[100]),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      );
                    }).toList(),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          return Container(
                            width: _currentImageIndex == entry.key ? 20.0 : 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentImageIndex == entry.key ? thixOrange : Colors.white.withOpacity(0.6),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // ─── DÉTAILS DU PRODUIT ───
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: pureWhite,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        _product['title'] ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: darkText, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      
                      // Prix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${(hasDiscount ? _product['discount_price'] : _product['price']).toInt()} $currencySymbol',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: thixOrange),
                          ),
                          if (hasDiscount)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 4),
                              child: Text(
                                '${_product['price'].toInt()} $currencySymbol',
                                style: TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: mutedText, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Avis et Stock
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              RatingBar.builder(
                                initialRating: (_product['rating'] ?? 0).toDouble(),
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: 18,
                                ignoreGestures: true,
                                itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                                onRatingUpdate: (_) {},
                              ),
                              const SizedBox(width: 8),
                              Text('${_product['reviews_count'] ?? 0} avis', style: TextStyle(color: mutedText, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ((_product['stock'] ?? 0) > 0) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ((_product['stock'] ?? 0) > 0) ? 'En stock (${_product['stock']})' : 'Rupture',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: ((_product['stock'] ?? 0) > 0) ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── SÉLECTION DE QUANTITÉ (Déplacé ici) ───
                Container(
                  color: pureWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      const Text('Quantité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_selectedQuantity > 1) setState(() => _selectedQuantity--);
                              },
                              icon: const Icon(Icons.remove_rounded, size: 20),
                              color: darkText,
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$_selectedQuantity',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_selectedQuantity < (_product['stock'] ?? 0)) {
                                  setState(() => _selectedQuantity++);
                                }
                              },
                              icon: const Icon(Icons.add_rounded, size: 20),
                              color: darkText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── VARIANTES ET COULEURS ───
                if (variants.isNotEmpty || colors.isNotEmpty)
                  Container(
                    color: pureWhite,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (variants.isNotEmpty) _buildVariantsSection(variants),
                        if (variants.isNotEmpty && colors.isNotEmpty) const SizedBox(height: 16),
                        if (colors.isNotEmpty) _buildColorsSection(colors),
                      ],
                    ),
                  ),
                if (variants.isNotEmpty || colors.isNotEmpty) const SizedBox(height: 8),

                // ─── BOUTIQUE ───
                Container(
                  color: pureWhite,
                  padding: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => context.push('/market/shop/${_product['shop_id']}'),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!),
                            image: _product['shop']?['logo_url'] != null
                                ? DecorationImage(image: CachedNetworkImageProvider(_product['shop']['logo_url']), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _product['shop']?['logo_url'] == null ? const Icon(Icons.storefront_rounded, size: 24, color: mutedText) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product['shop']?['name'] ?? 'Boutique Partenaire',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: darkText),
                              ),
                              const SizedBox(height: 4),
                              const Text('Voir la boutique', style: TextStyle(color: thixOrange, fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ─── DESCRIPTION & INFOS ───
                Container(
                  color: pureWhite,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                      const SizedBox(height: 12),
                      Text(
                        _product['description'] ?? '',
                        style: const TextStyle(height: 1.6, color: darkText, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      const Text('Informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                      const SizedBox(height: 16),
                      if (_product['brand'] != null) _buildInfoRow(Icons.branding_watermark_rounded, 'Marque', _product['brand']),
                      if (_product['condition'] != null) _buildInfoRow(Icons.info_outline_rounded, 'État', _product['condition']),
                      _buildInfoRow(Icons.local_shipping_rounded, 'Livraison', shippingCost != null ? '${shippingCost.toInt()} $currencySymbol' : 'Fixé par le livreur'),
                      _buildInfoRow(Icons.verified_user_rounded, 'Garantie', warrantyMonths != null ? '$warrantyMonths mois' : 'Non spécifiée'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── AVIS ───
                if (_reviews.isNotEmpty)
                  Container(
                    color: pureWhite,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Avis clients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                            TextButton(
                              onPressed: _showAllReviews,
                              child: const Text('Voir tout', style: TextStyle(color: thixOrange, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._reviews.take(3).map((review) => _buildReviewCard(review)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // ─── PRODUITS SIMILAIRES ───
                if (_similarProducts.isNotEmpty)
                  Container(
                    color: pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text('Produits similaires', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _similarProducts.length,
                            itemBuilder: (context, index) {
                              final product = _similarProducts[index];
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 12),
                                child: ProductCard(
                                  product: product,
                                  onTap: (_) {
                                    // ✅ Correction : Utilisation de push au lieu de pushReplacement
                                    context.push('/market/product/${product['id']}');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 100), // Espace pour la bottom bar
              ],
            ),
          ),
        ],
      ),
      
      // ─── BARRE DE NAVIGATION INFÉRIEURE (ÉPURÉE) ───
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: pureWhite,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Bouton Chat
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: darkText),
                  onPressed: _openChatWithSeller,
                  tooltip: 'Contacter le vendeur',
                ),
              ),
              const SizedBox(width: 12),
              
              // Bouton Panier
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: isProductAvailable && !_isAddingToCart ? _addToCart : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: thixOrange, width: 2),
                    foregroundColor: thixOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isAddingToCart 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: thixOrange, strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart_rounded),
                ),
              ),
              const SizedBox(width: 12),
              
              // Bouton Acheter
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: isProductAvailable && !_isAddingToCart ? _buyNow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: thixOrange,
                    foregroundColor: pureWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Acheter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Variantes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: variants.map((variant) {
            final label = variant is String ? variant : variant['name']?.toString() ?? '';
            final isSelected = _selectedVariant == label;
            return ChoiceChip(
              label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedVariant = selected ? label : null),
              selectedColor: softOrange,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(color: isSelected ? thixOrange : darkText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? thixOrange : Colors.transparent),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorsSection(List colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Couleurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: darkText)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final label = color is String ? color : color['name']?.toString() ?? '';
            final isSelected = _selectedColor == label;
            return ChoiceChip(
              label: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
              selected: isSelected,
              onSelected: (selected) => setState(() => _selectedColor = selected ? label : null),
              selectedColor: softOrange,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(color: isSelected ? thixOrange : darkText),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? thixOrange : Colors.transparent),
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 22, color: mutedText),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: darkText, fontSize: 15)),
          const Spacer(),
          Text(value, style: TextStyle(color: mutedText, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map?;
    final avatar = user?['avatar'] as String?;
    final name = user?['name'] as String? ?? 'Utilisateur';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['created_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
                child: avatar == null ? const Icon(Icons.person, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 15)),
                    const SizedBox(height: 4),
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 14,
                      ignoreGestures: true,
                      itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: Colors.amber),
                      onRatingUpdate: (_) {},
                    ),
                  ],
                ),
              ),
              if (createdAt != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(createdAt)),
                  style: TextStyle(fontSize: 12, color: mutedText, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(comment, style: const TextStyle(color: darkText, height: 1.4)),
          ]
        ],
      ),
    );
  }

  void _showAllReviews() {
    if (_reviews.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text('Tous les avis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: darkText)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
      ),
    );
  }
}
