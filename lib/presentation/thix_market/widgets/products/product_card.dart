// lib/presentation/thix_market/widgets/products/product_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductCard extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    // ✅ 1. CONVERSION DE PRIX ULTRA-SÉCURISÉE (Évite les crashs si Null)
    final rawPrice = product['price'];
    final rawDiscount = product['discount_price'];

    final originalPrice = (rawPrice as num?)?.toDouble() ?? 0.0;
    final discountPrice = (rawDiscount as num?)?.toDouble();

    final hasDiscount = discountPrice != null && discountPrice < originalPrice;
    final price = hasDiscount ? discountPrice : originalPrice;

    final discountPercent = originalPrice > 0 && hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;

    // ✅ Devise dynamique
    final currency = product['currency'] ?? 'CDF';
    final currencySymbol = currency == 'USD' ? '\$' : 'FC';

    // ✅ Gestion robuste du stock
    final stock = int.tryParse(product['stock']?.toString() ?? '0') ?? 0;
    final isOutOfStock = stock <= 0;

    return GestureDetector(
      // On autorise le clic pour voir les détails même si épuisé, c'est meilleur pour l'engagement
      onTap: () => onTap?.call(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // Coins un peu plus arrondis et modernes
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), 
              blurRadius: 8, 
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isOutOfStock ? Colors.grey.shade200 : const Color(0xFFF0F0F0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // ZONE IMAGE + BADGES (PROMO / ÉPUISÉ / COEUR)
            // ==========================================
            Expanded(
              child: Stack(
                children: [
                  // Image du produit
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: CachedNetworkImage(
                        imageUrl: product['image_url'] ?? '',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[50],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.image_outlined, color: Colors.grey, size: 28),
                        ),
                      ),
                    ),
                  ),

                  // Overlay "ÉPUISÉ" si le stock est à 0
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD81E2C),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ÉPUISÉ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Badge Vente Flash (si disponible et non épuisé)
                  if (isFlashSale && !isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD81E2C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'FLASH',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),

                  // Badge Réduction (si disponible et non épuisé)
                  if (hasDiscount && !isFlashSale && !isOutOfStock)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD81E2C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),

                  // ✅ AJOUT : Bouton Favoris fonctionnel et interactif
                  if (showFavoriteButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          final id = product['id']?.toString();
                          if (id != null) onFavoriteTap?.call(id);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 16,
                            color: isFavorite ? const Color(0xFFD81E2C) : const Color(0xFF8A8A8F),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ==========================================
            // DETAILS ET INFOS DU PRODUIT
            // ==========================================
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? product['name'] ?? 'Produit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800, 
                      fontSize: 13,
                      color: Color(0xFF10192E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined, 
                        size: 11, 
                        color: Color(0xFF8A8A8F),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['city'] ?? 'Kinshasa',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A8F)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Prix et indicateur de stock côte à côte
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDiscount && !isOutOfStock)
                            Text(
                              '${originalPrice.toInt()} $currencySymbol',
                              style: TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          Text(
                            isOutOfStock ? 'Non disponible' : '${price.toInt()} $currencySymbol',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isOutOfStock ? Colors.grey : const Color(0xFFE5592F),
                            ),
                          ),
                        ],
                      ),
                      
                      // Indicateur de stock stylisé
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOutOfStock 
                              ? const Color(0xFFFFF0F0) 
                              : const Color(0xFFE8FFF1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOutOfStock ? 'Épuisé' : '$stock dispo',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isOutOfStock 
                                ? const Color(0xFFD81E2C) 
                                : const Color(0xFF00B074),
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
  }
}
