import 'package:flutter/material.dart';
import 'package:thix_id/theme.dart';

/// Compact category pill used in the horizontal categories row.
class CategoryItem extends StatelessWidget {
  const CategoryItem({super.key, required this.title, this.selected = false, this.onTap});

  final String title;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? MarketColors.orange.withValues(alpha: 0.14) : Colors.white;
    final stroke = selected ? MarketColors.orange.withValues(alpha: 0.25) : MarketColors.stroke;
    final fg = selected ? MarketColors.orangeDeep : MarketColors.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: stroke)),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
