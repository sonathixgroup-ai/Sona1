import 'package:flutter/material.dart';
import 'package:thix_id/models/market_product.dart';
import 'package:thix_id/theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.onTap});

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.stroke)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: MarketColors.bg,
                    child: product.imageUrl == null || product.imageUrl!.trim().isEmpty
                        ? const Center(child: Icon(Icons.image_outlined, color: MarketColors.grayText))
                        : Image.network(product.imageUrl!, fit: BoxFit.cover),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(product.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.25, color: MarketColors.ink)),
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
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: MarketColors.grayText, fontWeight: FontWeight.w700),
                    ),
                  )
                ],
              ),
              const Spacer(),
              Text(price, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: MarketColors.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
