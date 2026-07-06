import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../providers/shop_provider.dart';

class ShopDetailPage extends StatefulWidget {
  final String shopId;
  const ShopDetailPage({super.key, required this.shopId});

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _shop;
  List<Map<String, dynamic>> _products = [];

  static const Color navy = Color(0xFF1B2A4A);
  static const Color navyDeep = Color(0xFF10192E);
  static const Color gold = Color(0xFFC9962C);
  static const Color bgApp = Color(0xFFF6F7FB);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color textDark = Color(0xFF1A1D29);
  static const Color danger = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final shopProvider = context.read<ShopProvider>();
      await shopProvider.loadShopDetails(widget.shopId);
      final shop = shopProvider.currentShop;
      setState(() {
        _shop = shop;
        _products = List<Map<String, dynamic>>.from(shop?['products'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgApp,
        appBar: AppBar(
          title: const Text('Boutique'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    if (_shop == null) {
      return Scaffold(
        backgroundColor: bgApp,
        appBar: AppBar(
          title: const Text('Boutique'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: 72, color: Colors.grey[300]), // ✅ icône valide
              const SizedBox(height: 16),
              const Text(
                'Boutique introuvable',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Cette boutique n\'existe pas ou a été supprimée',
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: navyDeep,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
                child: const Text(
                  'Retour',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shop = _shop!;
    final isActive = shop['status'] == 'active';
    final isVerified = shop['is_verified'] == true;
    final isLive = shop['is_live'] == true || shop['live_status'] == 'live';
    final isFollowed = shop['is_followed'] ?? false;

    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: Text(
          shop['name'] ?? 'Boutique',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              isFollowed ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFollowed ? danger : textMuted,
            ),
            onPressed: () => _toggleFollow(shop['id']),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: textMuted),
            onPressed: () => _shareShop(shop['id']),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // EN-TÊTE DE LA BOUTIQUE
            // ============================================================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isLive ? Border.all(color: danger.withOpacity(0.4), width: 1.4) : null,
                boxShadow: [
                  BoxShadow(color: navy.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLive) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'EN DIRECT MAINTENANT',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: bgApp,
                              border: Border.all(color: isLive ? danger.withOpacity(0.5) : Colors.grey[200]!, width: isLive ? 1.5 : 1),
                              image: (shop['logo_url'] != null && (shop['logo_url'] as String).isNotEmpty)
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(shop['logo_url']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: (shop['logo_url'] == null || (shop['logo_url'] as String).isEmpty)
                                ? Icon(Icons.store_rounded, size: 32, color: textMuted)
                                : null,
                          ),
                          if (isVerified)
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.verified_rounded, size: 18, color: navy),
                              ),
                            ),
                          if (!isActive)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(color: danger, borderRadius: BorderRadius.circular(6)),
                                child: const Text(
                                  'Inactif',
                                  style: TextStyle(color: Colors.white, fontSize: 8.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    shop['name'] ?? 'Boutique',
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified)
                                  const Icon(Icons.verified_rounded, size: 18, color: navy),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (shop['city'] != null)
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 14, color: textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    shop['city'],
                                    style: TextStyle(color: textMuted, fontSize: 13),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 14, color: textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  '${_products.length} produits',
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.favorite_rounded, size: 14, color: textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  _formatNumber(shop['followers'] ?? 0),
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (shop['description'] != null && (shop['description'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      shop['description'],
                      style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ============================================================
            // PRODUITS DE LA BOUTIQUE
            // ============================================================
            Row(
              children: [
                const Text(
                  'Produits de la boutique',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: textDark),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/market/search?shop=${shop['id']}'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Row(
                    children: [
                      Text('Voir tout', style: TextStyle(color: gold, fontWeight: FontWeight.w700, fontSize: 11.5)),
                      Icon(Icons.chevron_right_rounded, size: 15, color: gold),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_products.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: navy.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_rounded, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun produit disponible',
                      style: TextStyle(color: textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: _products.length > 6 ? 6 : _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final imageUrl = product['image_url'] ??
                      (product['images'] != null && product['images'].isNotEmpty
                          ? product['images'][0]
                          : null);
                  final currency = product['currency'] ?? 'FC';
                  final hasDiscount = product['discount_price'] != null &&
                      product['discount_price'] < product['price'];
                  final price = (hasDiscount
                          ? product['discount_price']
                          : product['price'])
                      .toDouble();

                  return GestureDetector(
                    onTap: () => context.push('/market/product/${product['id']}'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorWidget: (_, __, ___) => Container(
                                        color: bgApp,
                                        child: const Icon(Icons.image_rounded, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      color: bgApp,
                                      child: const Icon(Icons.image_rounded, color: Colors.grey),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      '${price.toInt()} $currency',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: navy,
                                      ),
                                    ),
                                    if (hasDiscount)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Text(
                                          '${(product['price']).toInt()} $currency',
                                          style: TextStyle(
                                            decoration: TextDecoration.lineThrough,
                                            fontSize: 9,
                                            color: textMuted,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            if (_products.length > 6) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/market/search?shop=${shop['id']}'),
                  child: Text(
                    'Voir les ${_products.length} produits',
                    style: TextStyle(color: gold, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _toggleFollow(String shopId) {
    context.read<ShopProvider>().toggleFollowShop(shopId);
    setState(() {
      _shop?['is_followed'] = !(_shop?['is_followed'] ?? false);
    });
  }

  void _shareShop(String shopId) {
    // À implémenter plus tard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage à venir')),
    );
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }
}
