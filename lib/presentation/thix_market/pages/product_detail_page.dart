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

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color goldSoft = Color(0xFFF6E9C9);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color success = Color(0xFF1FA971);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

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
          const SnackBar(content: Text('Ajouté au panier avec succès !'), backgroundColor: success),
        );
        final cartProvider = context.read<CartProvider>();
        await cartProvider.loadCart();
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: danger),
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
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    if (_product.isEmpty) {
      return Scaffold(
        backgroundColor: ivory,
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
              Icon(Icons.error_outline_rounded, size: 64, color: mutedText),
              SizedBox(height: 16),
              Text('Produit introuvable', style: TextStyle(fontSize: 18, color: darkText, fontWeight: FontWeight.w700)),
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
      backgroundColor: ivory,
      body: CustomScrollView(
        slivers: [
          // ============================================================
          // CAROUSEL D'IMAGES — cadre navy, indicateurs or
          // ============================================================
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: navyDeep,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: _circleGlassButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => context.pop(),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: _circleGlassButton(
                  icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  iconColor: _isFavorite ? danger : Colors.white,
                  onTap: _toggleFavorite,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                child: _circleGlassButton(
                  icon: Icons.share_rounded,
                  onTap: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(color: navyDeep),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 360,
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
                        placeholder: (_, __) => Container(color: navy.withOpacity(0.15)),
                        errorWidget: (_, __, ___) => Container(
                          color: navy.withOpacity(0.15),
                          child: const Icon(Icons.broken_image_rounded, size: 50, color: Colors.white54),
                        ),
                      );
                    }).toList(),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 90,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x990A1F44)],
                        ),
                      ),
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 18,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images.asMap().entries.map((entry) {
                          final active = _currentImageIndex == entry.key;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: active ? 20.0 : 6.0,
                            height: 6.0,
                            margin: const EdgeInsets.symmetric(horizontal: 3.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: active ? gold : Colors.white.withOpacity(0.55),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ============================================================
          // DÉTAILS DU PRODUIT
          // ============================================================
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: ivory,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _product['title'] ?? '',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: darkText, height: 1.3),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(hasDiscount ? _product['discount_price'] : _product['price']).toInt()} $currencySymbol',
                                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: navy),
                              ),
                              if (hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10, bottom: 4),
                                  child: Text(
                                    '${_product['price'].toInt()} $currencySymbol',
                                    style: const TextStyle(fontSize: 14, decoration: TextDecoration.lineThrough, color: mutedText, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              if (hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      '-${((1 - (_product['discount_price'] / _product['price'])) * 100).round()}%',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: navyDeep),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                    itemSize: 16,
                                    ignoreGestures: true,
                                    itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: gold),
                                    onRatingUpdate: (_) {},
                                  ),
                                  const SizedBox(width: 7),
                                  Text('${_product['reviews_count'] ?? 0} avis', style: const TextStyle(color: mutedText, fontWeight: FontWeight.w600, fontSize: 12.5)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: ((_product['stock'] ?? 0) > 0) ? success.withOpacity(0.10) : danger.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  ((_product['stock'] ?? 0) > 0) ? 'En stock (${_product['stock']})' : 'Rupture',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: ((_product['stock'] ?? 0) > 0) ? success : danger,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ============================================================
                    // QUANTITÉ — stepper navy avec icônes or
                    // ============================================================
                    _sectionCard(
                      child: Row(
                        children: [
                          const Text('Quantité', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: darkText)),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: navyDeep,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _quantityButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    if (_selectedQuantity > 1) setState(() => _selectedQuantity--);
                                  },
                                ),
                                Container(
                                  width: 38,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_selectedQuantity',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Colors.white),
                                  ),
                                ),
                                _quantityButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    if (_selectedQuantity < (_product['stock'] ?? 0)) {
                                      setState(() => _selectedQuantity++);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ============================================================
                    // VARIANTES ET COULEURS
                    // ============================================================
                    if (variants.isNotEmpty || colors.isNotEmpty)
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (variants.isNotEmpty) _buildVariantsSection(variants),
                            if (variants.isNotEmpty && colors.isNotEmpty) const SizedBox(height: 16),
                            if (colors.isNotEmpty) _buildColorsSection(colors),
                          ],
                        ),
                      ),

                    // ============================================================
                    // BOUTIQUE — cadre or
                    // ============================================================
                    _sectionCard(
                      child: GestureDetector(
                        onTap: () => context.push('/market/shop/${_product['shop_id']}'),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: gold, width: 1.6),
                                image: _product['shop']?['logo_url'] != null
                                    ? DecorationImage(image: CachedNetworkImageProvider(_product['shop']['logo_url']), fit: BoxFit.cover)
                                    : null,
                                color: navyDeep,
                              ),
                              child: _product['shop']?['logo_url'] == null
                                  ? const Icon(Icons.storefront_rounded, size: 22, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _product['shop']?['name'] ?? 'Boutique Partenaire',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: darkText),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text('Voir la boutique', style: TextStyle(color: navy, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                              child: const Icon(Icons.chevron_right_rounded, color: navy, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ============================================================
                    // DESCRIPTION & INFOS
                    // ============================================================
                    _sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText)),
                          const SizedBox(height: 10),
                          Text(
                            _product['description'] ?? '',
                            style: const TextStyle(height: 1.6, color: darkText, fontSize: 13.5),
                          ),
                          const SizedBox(height: 22),
                          const Text('Informations', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText)),
                          const SizedBox(height: 14),
                          if (_product['brand'] != null) _buildInfoRow(Icons.branding_watermark_rounded, 'Marque', _product['brand']),
                          if (_product['condition'] != null) _buildInfoRow(Icons.info_outline_rounded, 'État', _product['condition']),
                          _buildInfoRow(Icons.local_shipping_rounded, 'Livraison', shippingCost != null ? '${shippingCost.toInt()} $currencySymbol' : 'Fixé par le livreur'),
                          _buildInfoRow(Icons.verified_user_rounded, 'Garantie', warrantyMonths != null ? '$warrantyMonths mois' : 'Non spécifiée'),
                        ],
                      ),
                    ),

                    // ============================================================
                    // AVIS
                    // ============================================================
                    if (_reviews.isNotEmpty)
                      _sectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Avis clients', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText)),
                                TextButton(
                                  onPressed: _showAllReviews,
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                                  child: const Text('Voir tout', style: TextStyle(color: navy, fontWeight: FontWeight.w800, fontSize: 12.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._reviews.take(3).map((review) => _buildReviewCard(review)),
                          ],
                        ),
                      ),

                    // ============================================================
                    // PRODUITS SIMILAIRES
                    // ============================================================
                    if (_similarProducts.isNotEmpty)
                      Container(
                        color: pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('Produits similaires', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: darkText)),
                            ),
                            const SizedBox(height: 14),
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
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ============================================================
      // BARRE INFÉRIEURE — navy / or institutionnel
      // ============================================================
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: pureWhite,
          boxShadow: [BoxShadow(color: navyDeep.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -6))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Bouton Chat
              Container(
                decoration: BoxDecoration(
                  color: ivory,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: hairline),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: navy),
                  onPressed: _openChatWithSeller,
                  tooltip: 'Contacter le vendeur',
                ),
              ),
              const SizedBox(width: 10),

              // Bouton Panier
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: isProductAvailable && !_isAddingToCart ? _addToCart : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: navy, width: 1.8),
                    foregroundColor: navy,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isAddingToCart
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: navy, strokeWidth: 2))
                      : const Icon(Icons.add_shopping_cart_rounded),
                ),
              ),
              const SizedBox(width: 10),

              // Bouton Acheter
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [navyDeep, navy]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: isProductAvailable && !_isAddingToCart ? _buyNow : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: gold,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Acheter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
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

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hairline),
      ),
      child: child,
    );
  }

  Widget _circleGlassButton({required IconData icon, VoidCallback? onTap, Color iconColor = Colors.white}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }

  Widget _quantityButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: gold),
      ),
    );
  }

  Widget _buildVariantsSection(List variants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Variantes', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: darkText)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: variants.map((variant) {
            final label = variant is String ? variant : variant['name']?.toString() ?? '';
            final isSelected = _selectedVariant == label;
            return _selectableChip(
              label: label,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedVariant = isSelected ? null : label),
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
        const Text('Couleurs', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: darkText)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: colors.map((color) {
            final label = color is String ? color : color['name']?.toString() ?? '';
            final isSelected = _selectedColor == label;
            return _selectableChip(
              label: label,
              isSelected: isSelected,
              onTap: () => setState(() => _selectedColor = isSelected ? null : label),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _selectableChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? navyDeep : ivory,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? navyDeep : hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
            color: isSelected ? gold : darkText,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: ivory, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: navy),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: darkText, fontSize: 13.5)),
          const Spacer(),
          Text(value, style: const TextStyle(color: mutedText, fontSize: 13, fontWeight: FontWeight.w500)),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ivory,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: navyDeep,
                backgroundImage: avatar != null ? CachedNetworkImageProvider(avatar) : null,
                child: avatar == null ? const Icon(Icons.person_rounded, size: 19, color: Colors.white) : null,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: darkText, fontSize: 14)),
                    const SizedBox(height: 3),
                    RatingBar.builder(
                      initialRating: rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemSize: 13,
                      ignoreGestures: true,
                      itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: gold),
                      onRatingUpdate: (_) {},
                    ),
                  ],
                ),
              ),
              if (createdAt != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.parse(createdAt)),
                  style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment, style: const TextStyle(color: darkText, height: 1.4, fontSize: 13)),
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
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Text('Tous les avis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText)),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: ivory, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: navy, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
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
