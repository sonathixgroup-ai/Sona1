import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/market_colors.dart';
import 'wishlist_button.dart';

class ProductCard extends ConsumerWidget {
  final Map<String, dynamic> product;
  final bool isFlashSale;
  final bool showFavoriteButton;
  final bool isFavorite;
  final Function(Map<String, dynamic>)? onTap;
  final Function(String)? onFavoriteTap;

  const ProductCard({
    super.key,
    required this.product,
    this.isFlashSale = false,
    this.showFavoriteButton = true,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
  });

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString()?? '')?? 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawPrice = product['price'];
    final rawDiscount = product['discount_price'];

    final originalPrice = _toDouble(rawPrice);
    final discountPrice = rawDiscount!=null? _toDouble(rawDiscount) : null;

    final hasDiscount = discountPrice!=null && discountPrice>0 && discountPrice < originalPrice;
    final price = hasDiscount? discountPrice! : originalPrice;

    final discountPercent = originalPrice>0 && hasDiscount
      ? ((originalPrice - price)/originalPrice*100).round()
        : 0;

    final currency = product['currency']?? 'CDF';
    final symbol = currency=='USD'? '\$' : 'FC';

    final stock = int.tryParse(product['stock']?.toString()?? '1')?? 1;
    final isOut = stock<=0;

    final img = product['image_url'] as String?;
    final title = (product['title']?? product['name']?? 'Produit').toString();
    final city = (product['city']?? product['location']?? 'Kinshasa').toString();
    final id = product['id']?.toString()?? '';

    return GestureDetector(
      onTap: () {
        if(onTap!=null) { onTap!(product); }
        else { context.push('/market/product/$id'); }
      },
      child: Container(
        decoration: BoxDecoration(
          color: MarketColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isOut? const Color(0xFFE5E5E5) : MarketColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: img==null || img.isEmpty
                        ? Container(color: MarketColors.lightBg, child: const Icon(Icons.image_outlined, color: MarketColors.mutedText))
                          : Image.network(img, fit: BoxFit.cover, cacheWidth: 400, errorBuilder: (_,__,___)=> Container(color: MarketColors.lightBg, child: const Icon(Icons.broken_image_outlined))),
                    ),
                  ),
                  if(isOut)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.4), borderRadius: const BorderRadius.vertical(top: Radius.circular(15))),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),
                            decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(6)),
                            child: const Text('ÉPUISÉ', style: TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  if(isFlashSale &&!isOut)
                    Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(6)), child: const Text('FLASH', style: TextStyle(color: Colors.white, fontSize:9, fontWeight: FontWeight.w900)))),
                  if(hasDiscount &&!isFlashSale &&!isOut)
                    Positioned(top:8,left:8, child: Container(padding: const EdgeInsets.symmetric(horizontal:7,vertical:3), decoration: BoxDecoration(color: MarketColors.red, borderRadius: BorderRadius.circular(6)), child: Text('-$discountPercent%', style: const TextStyle(color: Colors.white, fontSize:9, fontWeight: FontWeight.w900)))),

                  if(showFavoriteButton)
                    Positioned(
                      top:8,right:8,
                      child: WishlistButton(productId: id, size: 18),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize:13, color: Color(0xFF10192E))),
                  const SizedBox(height:4),
                  Row(children: [const Icon(Icons.location_on_outlined, size:11, color: MarketColors.mutedText), const SizedBox(width:2), Expanded(child: Text(city, maxLines:1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:11, color: MarketColors.mutedText)))]),
                  const SizedBox(height:6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if(hasDiscount &&!isOut) Text('${originalPrice.toInt()} $symbol', style: TextStyle(decoration: TextDecoration.lineThrough, fontSize:10, color: Colors.grey.shade400)),
                        Text(isOut? 'Non dispo' : '${price.toInt()} $symbol', style: TextStyle(fontWeight: FontWeight.w900, fontSize:14, color: isOut? Colors.grey : MarketColors.red)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal:6,vertical:3),
                        decoration: BoxDecoration(color: isOut? const Color(0xFFFFF0F0) : const Color(0xFFE8FFF1), borderRadius: BorderRadius.circular(6)),
                        child: Text(isOut? 'Épuisé' : '$stock dispo', style: TextStyle(fontSize:9, fontWeight: FontWeight.w800, color: isOut? MarketColors.red : const Color(0xFF00B074))),
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
  }
}
