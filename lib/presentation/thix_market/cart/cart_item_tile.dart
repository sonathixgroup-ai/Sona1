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

  // ============================================================
  // CHARTE THIX ID — Design Institutionnel Premium (Navy / Bleu / Or)
  // ============================================================
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color gold = Color(0xFFE3B23C);
  static const Color ivory = Color(0xFFF6F7FB);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10182B);
  static const Color mutedText = Color(0xFF6B7690);
  static const Color danger = Color(0xFFD64545);
  static const Color hairline = Color(0xFFE7EAF3);

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
    final stock = product['stock'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hairline),
        boxShadow: [
          BoxShadow(color: navyDeep.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // IMAGE PRODUIT — coin arrondi, cadre or si remise
            // ============================================================
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl ?? '',
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 84,
                      height: 84,
                      color: ivory,
                      child: const Icon(Icons.image_rounded, color: mutedText),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 84,
                      height: 84,
                      color: ivory,
                      child: const Icon(Icons.broken_image_rounded, color: mutedText),
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '-${((1 - finalPrice / price) * 100).round()}%',
                        style: const TextStyle(color: navyDeep, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 13),

            // ============================================================
            // DÉTAILS PRODUIT
            // ============================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? 'Produit',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: darkText),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.store_rounded, size: 11, color: navy),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          product['shop']?['name'] ?? 'Boutique',
                          style: const TextStyle(fontSize: 11, color: mutedText, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (cartItem['variant'] != null || cartItem['color'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ivory,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: hairline),
                        ),
                        child: Text(
                          '${cartItem['variant'] ?? ''} ${cartItem['color'] ?? ''}'.trim(),
                          style: const TextStyle(fontSize: 9.5, color: navy, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // ============================================================
                  // PRIX + STEPPER QUANTITÉ
                  // ============================================================
                  Row(
                    children: [
                      Text(
                        '${finalPrice.toInt()} $symbol',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: navy,
                        ),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${price.toInt()} $symbol',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 11,
                              color: mutedText,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: navyDeep,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _stepperButton(
                              icon: Icons.remove_rounded,
                              onTap: () {
                                if (quantity > 1) onQuantityChanged(quantity - 1);
                              },
                            ),
                            SizedBox(
                              width: 26,
                              child: Text(
                                '$quantity',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: Colors.white),
                              ),
                            ),
                            _stepperButton(
                              icon: Icons.add_rounded,
                              onTap: () {
                                if (quantity < stock) onQuantityChanged(quantity + 1);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(height: 1, color: hairline),
                  const SizedBox(height: 8),

                  // ============================================================
                  // TOTAL + SUPPRESSION
                  // ============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 13, color: gold),
                          const SizedBox(width: 4),
                          Text(
                            'Total : ${totalPrice.toInt()} $symbol',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: navyDeep),
                          ),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: danger.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded, size: 16, color: danger),
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
  }

  Widget _stepperButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: gold),
      ),
    );
  }
}
