import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isFlashSale;
  final bool showFavoriteButton;
  final bool isFavorite;
  final Function(Map<String, dynamic>)? onTap;
  final Function(String)? onFavoriteTap;
  final Function(Map<String, dynamic>)? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    this.isFlashSale = false,
    this.showFavoriteButton = true,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCart,
  });

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}k';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product['discount_price'] != null &&
        product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();
    final originalPrice = product['price'].toDouble();
    final discountPercent = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;
    final stock = product['stock'] ?? 0;
    final isOutOfStock = stock == 0;

    return GestureDetector(
      onTap: () => onTap?.call(product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: product['image_url'] ?? '',
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 160,
                      color: Colors.grey[100],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
                  ),
                ),
                
                // Flash sale badge
                if (isFlashSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE5592F), Color(0xFFFF6B35)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.flash_on, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'FLASH',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Discount badge
                if (hasDiscount && !isFlashSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Favorite button
                if (showFavoriteButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => onFavoriteTap?.call(product['id']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                
                // Stock badge
                if (!isOutOfStock && stock < 10)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Plus que $stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Sold out badge
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          'ÉPUISÉ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Product info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Shop name
                  Row(
                    children: [
                      Icon(Icons.store, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product['shop_name'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                      if (product['is_verified'] == true)
                        const Icon(Icons.verified, size: 10, color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Rating
                  Row(
                    children: [
                      RatingBar.builder(
                        initialRating: (product['rating'] ?? 0).toDouble(),
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 10,
                        ignoreGestures: true,
                        itemBuilder: (_, __) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (_) {},
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_formatNumber(product['reviews_count'] ?? 0)})',
                        style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Price
                  Row(
                    children: [
                      Text(
                        '${price.toInt()} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5592F),
                        ),
                      ),
                      if (hasDiscount)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            '${originalPrice.toInt()} FCFA',
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  // Free shipping badge
                  if (product['free_shipping'] == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.local_shipping, size: 10, color: Colors.green[600]),
                          const SizedBox(width: 2),
                          Text(
                            'Livraison gratuite',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Add to cart button
            if (onAddToCart != null && !isOutOfStock)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => onAddToCart?.call(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5592F).withOpacity(0.1),
                      foregroundColor: const Color(0xFFE5592F),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, size: 14),
                        SizedBox(width: 4),
                        Text('Ajouter', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
