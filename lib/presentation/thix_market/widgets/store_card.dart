import 'package:flutter/material.dart';
import 'package:thix_id/models/market_store.dart';
import 'package:thix_id/theme.dart';

class StoreCard extends StatelessWidget {
  const StoreCard({super.key, required this.store, this.onTap});

  final MarketStore store;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        highlightColor: Colors.transparent,
        child: Container(
          width: 170,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: MarketColors.stroke)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: MarketColors.bg,
                      child: store.coverImageUrl == null || store.coverImageUrl!.trim().isEmpty
                          ? const Center(child: Icon(Icons.storefront_outlined, color: MarketColors.grayText))
                          : Image.network(store.coverImageUrl!, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(store.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: MarketColors.ink)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: MarketColors.orangeDeep),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${store.rating.toStringAsFixed(1)} (${store.ratingCount})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: MarketColors.grayText, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
