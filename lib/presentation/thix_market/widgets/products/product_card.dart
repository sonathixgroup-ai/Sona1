// lib/presentation/thix_market/widgets/products/product_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/market_colors.dart';
import '../../l10n/market_strings.dart';
import 'wishlist_button.dart';

enum ProductCardVariant { grid, horizontal }

class ProductCard extends ConsumerWidget {
  final Map<String, dynamic> product;
  final ProductCardVariant variant;
  final bool isFlashSale;
  final bool isFeatured;
  final bool showFavoriteButton;
  final bool isFavorite;
  final double? width;
  final Function(Map<String, dynamic>)? onTap;
  final Function(String)? onFavoriteTap;

  const ProductCard({
    super.key,
    required this.product,
    this.variant = ProductCardVariant.grid,
    this.isFlashSale = false,
    this.isFeatured = false,
    this.showFavoriteButton = true,
    this.isFavorite = false,
    this.width,
    this.onTap,
    this.onFavoriteTap,
  });

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  String? _extractImage(Map<String, dynamic> p) {
    if (p['image_url'] != null && p['image_url'].toString().isNotEmpty) return p['image_url'].toString();
    if (p['images'] is List && (p['images'] as List).isNotEmpty) return (p['images'] as List).first.toString();
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.mkt;
    final rawPrice = product['price'];
    final rawDiscount = product['discount_price'];

    final originalPrice = _toDouble(rawPrice);
    final discountPrice = rawDiscount != null ? _toDouble(rawDiscount) : null;
    final hasDiscount = discountPrice != null && discountPrice > 0 && discountPrice < originalPrice;
    final price = hasDiscount ? discountPrice : originalPrice;

    final discountPercent = originalPrice > 0 && hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    final currency = (product['currency'] ?? 'CDF').toString().toUpperCase();
    final symbol = currency == 'USD' ? '\$' : 'FC';

    final stock = int.tryParse(product['stock']?.toString() ?? '1') ?? 1;
    final isOut = stock <= 0;

    final img = _extractImage(product);
    final title = (product['title'] ?? product['name'] ?? '').toString();
    final city = (product['city'] ?? product['location'] ?? t.cityFallback).toString();
    final id = product['id']?.toString() ?? '';

    final imageFlex = variant == ProductCardVariant.horizontal ? 5 : 6;
    final infoFlex = variant == ProductCardVariant.horizontal ? 5 : 5;

    final card = Container(
      width: variant == ProductCardVariant.horizontal ? (width ?? 158) : null,
      decoration: BoxDecoration(
        color: MarketColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isOut ? const Color(0xFFE8E8E8) : MarketColors.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: imageFlex,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(fit: StackFit.expand, children: [
                Container(
                  color: MarketColors.lightBg,
                  child: img == null || img.isEmpty
                      ? const Center(child: Icon(Icons.shopping_bag_outlined, color: MarketColors.mutedText, size: 34))
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: MarketColors.red),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.shopping_bag_outlined, color: MarketColors.mutedText, size: 34)),
                        ),
                ),
                if (isOut)
                  Container(
                    decoration: const BoxDecoration(color: Color(0x66000000)),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(6)),
                        child: Text(t.outOfStock, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                if (!isOut && (isFlashSale || isFeatured || hasDiscount))
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: isFlashSale
                            ? [MarketColors.redDark, MarketColors.red]
                            : isFeatured
                                ? [const Color(0xFFC9862B), MarketColors.gold]
                                : [MarketColors.red, MarketColors.redDark]),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Text(
                        isFlashSale ? t.flashBadge : isFeatured ? t.featuredBadge.toUpperCase() : '-$discountPercent%',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                      ),
                    ),
                  ),
                if (showFavoriteButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: WishlistButton(productId: id, size: 18),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            flex: infoFlex,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: variant == ProductCardVariant.grid ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Color(0xFF10192E), height: 1.2)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 11, color: MarketColors.mutedText),
                    const SizedBox(width: 2),
                    Expanded(child: Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: MarketColors.mutedText))),
                  ]),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasDiscount && !isOut)
                              Text('${originalPrice.toInt()} $symbol',
                                  style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 10, color: Colors.grey.shade400)),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(colors: [MarketColors.red, MarketColors.redDark])
                                  .createShader(bounds),
                              child: Text(
                                isOut ? t.unavailable : '${price.toInt()} $symbol',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: isOut ? Colors.grey : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOut ? const Color(0xFFFFF0F0) : const Color(0xFFE8FFF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(isOut ? t.outOfStock : '$stock ${t.inStock}',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isOut ? MarketColors.red : const Color(0xFF00B074))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          if (onTap != null) {
            onTap!(product);
          } else {
            context.push('/market/product/$id');
          }
        },
        child: card,
      ),
    );
  }
}
