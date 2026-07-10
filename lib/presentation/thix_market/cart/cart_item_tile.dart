// lib/presentation/thix_market/cart/cart_item_tile.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartItemTile extends StatelessWidget {
  final Map<String, dynamic> cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color danger = Color(0xFFFF5B3D);

  @override
  Widget build(BuildContext context) {
    final product = cartItem['product'] as Map<String, dynamic>;
    final quantity = cartItem['quantity'] as int;
    final price = (product['price'] as num).toDouble();
    final discountPrice = product['discount_price'] as num?;
    final finalPrice = discountPrice != null && discountPrice < price ? discountPrice.toDouble() : price;
    final hasDiscount = discountPrice != null && discountPrice < price;
    final totalPrice = finalPrice * quantity;
    final images = product['images'];
    final imageUrl = images is List && images.isNotEmpty ? images.first : product['image_url'];

    final currency = product['currency'] ?? 'CDF';
    final symbol = currency == 'USD' ? '\$' : 'FC';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: imageUrl ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 80,
                  height: 80,
                  color: softBlue,
                  child: const Icon(Icons.image_rounded, color: mutedText),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: softBlue,
                  child: const Icon(Icons.broken_image_rounded, color: mutedText),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? 'Produit',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: darkText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product['shop']?['name'] ?? 'Boutique',
                    style: TextStyle(fontSize: 12, color: mutedText),
                  ),
                  if (cartItem['variant'] != null || cartItem['color'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${cartItem['variant'] ?? ''} ${cartItem['color'] ?? ''}'.trim(),
                        style: TextStyle(fontSize: 11, color: mutedText),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${finalPrice.toInt()} $symbol',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: primaryBlue,
                        ),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${price.toInt()} $symbol',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              color: mutedText,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) onQuantityChanged(quantity - 1);
                              },
                              icon: const Icon(Icons.remove_rounded, size: 16, color: darkText),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32),
                            ),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: darkText),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                final stock = product['stock'] ?? 0;
                                if (quantity < stock) onQuantityChanged(quantity + 1);
                              },
                              icon: const Icon(Icons.add_rounded, size: 16, color: darkText),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${totalPrice.toInt()} $symbol',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: navyDeep),
                      ),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        color: danger,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
