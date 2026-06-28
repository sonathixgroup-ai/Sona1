import 'package:flutter/material.dart';
import 'package:thix_id/models/market_product.dart';
import 'package:thix_id/theme.dart';

class FlashCard extends StatelessWidget {
  const FlashCard({super.key, required this.product, this.onTap});

  final MarketProduct product;
  final VoidCallback? onTap;

  String _formatMoney(int amount, String currency) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final indexFromEnd = s.length - i;
      buf.write(s[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) buf.write(' ');
    }
    return '${buf.toString().trim()} $currency';
  }

  @override
  Widget build(BuildContext context) {
    final currency = product.currency ?? 'XOF';
    final price = _formatMoney(product.price, currency);
    final oldPrice = product.oldPrice == null ? null : _formatMoney(product.oldPrice!, currency);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        highlightColor: Colors.transparent,
        child: Container(
          width: 160,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.stroke)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          color: MarketColors.bg,
                          child: product.imageUrl == null || product.imageUrl!.trim().isEmpty
                              ? const Center(child: Icon(Icons.image_outlined, color: MarketColors.grayText))
                              : Image.network(product.imageUrl!, fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: MarketColors.ink, height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: MarketColors.orangeDeep),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${product.rating.toStringAsFixed(1)} (${product.ratingCount})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: MarketColors.grayText, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(price, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: MarketColors.ink)),
                    if (oldPrice != null)
                      Text(
                        oldPrice,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: MarketColors.grayText,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: MarketColors.grayText,
                            ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: MarketColors.orangeDeep, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    '-${product.discountPercent}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Positioned(top: 6, right: 6, child: Icon(Icons.favorite_border, size: 18, color: MarketColors.grayText)),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(color: MarketColors.orangeDeep, shape: BoxShape.circle),
                  child: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
