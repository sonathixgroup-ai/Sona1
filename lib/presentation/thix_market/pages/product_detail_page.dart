// lib/presentation/thix_market/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

import '../providers/market_providers.dart';
import '../checkout/checkout_page.dart';
import '../cart/cart_provider.dart';

class _MarketColors {
  static const redDark = Color(0xFF5C0E12);
  static const red = Color(0xFFD81E2C);
  static const gold = Color(0xFFF0A93B);
  static const lightBg = Color(0xFFF7F7FA);
  static const pureWhite = Color(0xFFFFFFFF);
  static const darkText = Color(0xFF1A1A1A);
  static const mutedText = Color(0xFF8A8A8F);
  static const cardBorder = Color(0xFFE5E7EB);
  static const successGreen = Color(0xFF00B074);
}

final productDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, productId) async {
  final db = ref.read(supabaseClientProvider);
  final prod =
      await db.from('products').select().eq('id', productId).maybeSingle();

  if (prod == null) throw Exception('Produit introuvable');

  Map<String, dynamic> shop = {};
  if (prod['shop_id'] != null) {
    final s =
        await db.from('shops').select().eq('id', prod['shop_id']).maybeSingle();
    if (s != null) shop = s;
  }

  List<Map<String, dynamic>> reviews = [];
  try {
    final r = await db
        .from('reviews')
        .select('*, user:users(name, avatar)')
        .eq('product_id', productId)
        .order('created_at', ascending: false)
        .limit(20);
    reviews = List<Map<String, dynamic>>.from(r);
  } catch (_) {}

  double rating = 0;
  if (reviews.isNotEmpty) {
    double sum = 0;
    for (final rev in reviews) {
      sum += (rev['rating'] as num).toDouble();
    }
    rating = sum / reviews.length;
  }

  return {
    ...prod,
    'shop': shop,
    'reviews': reviews,
    'reviews_count': reviews.length,
    'rating': rating,
  };
});

final storeProductsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, shopId) async {
  final db = ref.read(supabaseClientProvider);
  final res =
      await db.from('products').select().eq('shop_id', shopId).limit(10);
  return List<Map<String, dynamic>>.from(res);
});

final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  final db = ref.read(supabaseClientProvider);
  final uid = db.auth.currentUser?.id;
  if (uid == null) return false;
  final res = await db
      .from('wishlist')
      .select()
      .match({'user_id': uid, 'product_id': productId}).maybeSingle();
  return res != null;
});

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _qty = 1;
  String? _variant;
  String? _colorSel;
  bool _adding = false;
  int _imgIndex = 0;

  String _t(BuildContext context, String fr, String en) {
    final lang = Localizations.localeOf(context).languageCode;
    return lang == 'fr' ? fr : en;
  }

  Future<void> _toggleFav(bool currentlyFav) async {
    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(context, 'Veuillez vous connecter', 'Please log in')),
        ),
      );
      return;
    }
    try {
      if (!currentlyFav) {
        await db.from('wishlist').insert({
          'user_id': uid,
          'product_id': widget.productId,
        });
      } else {
        await db.from('wishlist').delete().match({
          'user_id': uid,
          'product_id': widget.productId,
        });
      }
      ref.invalidate(isFavoriteProvider(widget.productId));
    } catch (e) {
      debugPrint('fav error $e');
    }
  }

  Future<void> _addToCart({int maxStock = 0}) async {
    if (maxStock <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(context, 'Rupture de stock', 'Out of stock')),
            backgroundColor: _MarketColors.red,
          ),
        );
      }
      return;
    }

    final db = ref.read(supabaseClientProvider);
    final uid = db.auth.currentUser?.id;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(context, 'Veuillez vous connecter', 'Please log in')),
        ),
      );
      return;
    }

    setState(() => _adding = true);

    try {
      final existing = await db
          .from('cart')
          .select()
          .match({'user_id': uid, 'product_id': widget.productId})
          .maybeSingle();

      if (existing != null) {
        int cur =
            existing['quantity'] != null ? (existing['quantity'] as num).toInt() : 0;
        final newQty = cur + _qty;
        if (newQty > maxStock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _t(context, 'Stock limité à $maxStock', 'Stock limited to $maxStock'),
                ),
                backgroundColor: _MarketColors.red,
              ),
            );
          }
          return;
        }
        await db.from('cart').update({'quantity': newQty}).eq('id', existing['id']);
      } else {
        if (_qty > maxStock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _t(context, 'Stock limité à $maxStock', 'Stock limited to $maxStock'),
                ),
                backgroundColor: _MarketColors.red,
              ),
            );
          }
          return;
        }
        await db.from('cart').insert({
          'user_id': uid,
          'product_id': widget.productId,
          'quantity': _qty,
          'variant': _variant,
          'color': _colorSel,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(context, 'Ajouté au panier !', 'Added to cart!')),
            backgroundColor: _MarketColors.successGreen,
          ),
        );
      }
      ref.invalidate(cartProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _MarketColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _buyNow(int stock) async {
    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, 'Rupture de stock', 'Out of stock'))),
      );
      return;
    }
    await _addToCart(maxStock: stock);
    if (mounted) {
      try {
        context.push('/market/checkout');
      } catch (_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutPage()),
        );
      }
    }
  }

  void _openChat(Map<String, dynamic> product) {
    final shop = product['shop'] as Map<String, dynamic>?;
    final shopId = product['shop_id'];

    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(context, 'Boutique indisponible', 'Store unavailable')),
        ),
      );
      return;
    }

    String name = shop?['name']?.toString() ?? 'Vendeur';
    String? avatar = shop?['logo_url']?.toString();
    context.push(
      '/market/chat/$shopId',
      extra: {'title': name, 'userName': name, 'userAvatar': avatar},
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(productDetailProvider(widget.productId));
    final favAsync = ref.watch(isFavoriteProvider(widget.productId));

    return detailAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _MarketColors.pureWhite,
        body: Center(child: CircularProgressIndicator(color: _MarketColors.red)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(child: Text('Erreur $e')),
      ),
      data: (product) {
        final imagesRaw = product['images'] as List?;
        List<String> images = [];
        if (imagesRaw != null && imagesRaw.isNotEmpty) {
          images = imagesRaw.map((e) => e.toString()).toList();
        } else if (product['image_url'] != null) {
          images = [product['image_url'].toString()];
        } else {
          images = [''];
        }

        bool hasDiscount = product['discount_price'] != null &&
            (product['discount_price'] as num) < (product['price'] as num);

        String currency = product['currency']?.toString() ?? 'CDF';
        String symbol =
            currency == 'USD' ? '\$' : (currency == 'EUR' ? '€' : currency);

        int stock =
            product['stock'] != null ? (product['stock'] as num).toInt() : 0;
        bool available = stock > 0;

        List variants =
            product['variants'] is List ? product['variants'] as List : [];
        List colors =
            product['colors'] is List ? product['colors'] as List : [];
        List reviews =
            product['reviews'] is List ? product['reviews'] as List : [];
        bool isFav = favAsync.valueOrNull ?? false;
        final shopId = product['shop_id']?.toString();
        final shop = product['shop'] as Map<String, dynamic>?;

        return Scaffold(
          backgroundColor: _MarketColors.lightBg,
          body: CustomScrollView(
            slivers: [
              // ... (le reste du body reste identique à ton code)
              // Pour gagner de l'espace, je mets uniquement les parties modifiées ci-dessous.
              // Tu peux garder tout le reste de ton build() tel quel.
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: _MarketColors.pureWhite,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _circleBtn(Icons.arrow_back_rounded, () => context.pop()),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _circleBtn(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      () => _toggleFav(isFav),
                      color: isFav ? _MarketColors.red : _MarketColors.darkText,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Container(color: _MarketColors.pureWhite),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 400,
                          viewportFraction: 1,
                          enableInfiniteScroll: images.length > 1,
                          onPageChanged: (i, _) => setState(() => _imgIndex = i),
                        ),
                        items: images
                            .map(
                              (img) => Image.network(
                                img,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: _MarketColors.red,
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 50,
                                    color: _MarketColors.mutedText,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: images.asMap().entries.map((e) {
                              final active = _imgIndex == e.key;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: active ? 24 : 8,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: active
                                      ? _MarketColors.red
                                      : _MarketColors.cardBorder,
                                ),
                              );
                            }).toList(),
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
                    Container(
                      color: _MarketColors.pureWhite,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(hasDiscount ? product['discount_price'] : product['price']).toString()} $symbol',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: _MarketColors.darkText,
                                ),
                              ),
                              if (hasDiscount)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Text(
                                    '${product['price'].toString()} $symbol',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                      color: _MarketColors.mutedText,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product['title']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: _MarketColors.darkText,
                              height: 1.3,
                            ),
                          ),
                          // ===== BANDEAU RUPTURE DE STOCK =====
                          if (!available) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _MarketColors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.remove_shopping_cart_rounded,
                                    size: 16,
                                    color: _MarketColors.red,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _t(context, 'Rupture de stock', 'Out of stock'),
                                    style: const TextStyle(
                                      color: _MarketColors.red,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              RatingBar.builder(
                                initialRating: (product['rating'] as num).toDouble(),
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemSize: 14,
                                ignoreGestures: true,
                                itemBuilder: (_, __) =>
                                    const Icon(Icons.star_rounded, color: _MarketColors.gold),
                                onRatingUpdate: (_) {},
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${product['reviews_count']} ${_t(context, 'avis', 'reviews')}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: _MarketColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // ... le reste de ton contenu (variants, quantité, boutique, etc.) reste inchangé
                    // Seul le bottomNavigationBar change (voir ci-dessous)
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: _MarketColors.pureWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.push('/market/shop/$shopId'),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.storefront_rounded,
                            color: _MarketColors.darkText, size: 22),
                        SizedBox(height: 2),
                        Text('Store',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => _openChat(product),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: _MarketColors.darkText, width: 1.5),
                        foregroundColor: _MarketColors.darkText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Chat now',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed:
                          available && !_adding ? () => _buyNow(stock) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            available ? const Color(0xFFD0391A) : Colors.grey,
                        disabledBackgroundColor: Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: _adding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              available
                                  ? 'Buy now'
                                  : _t(context, 'Rupture de stock', 'Out of stock'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Garde toutes tes méthodes helper existantes :
  // _buildHorizontalTitle, _buildHorizontalList, _circleBtn, _qtyBtn,
  // _buildVariants, _buildColors, _chip, _reviewCard, _showAllReviews
  // elles n'ont pas besoin d'être modifiées.
}
