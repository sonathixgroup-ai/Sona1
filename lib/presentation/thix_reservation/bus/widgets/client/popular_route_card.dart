// lib/presentation/thix_reservation/bus/widgets/client/popular_route_card.dart
import 'package:flutter/material.dart';

class PopularRouteCard extends StatelessWidget {
  final String from;
  final String to;
  final String dateLabel;
  final String price;
  final String imageUrl;
  final VoidCallback onTap;
  const PopularRouteCard({super.key, required this.from, required this.to, required this.dateLabel, required this.price, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(width: 160, margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: Image.network(imageUrl, height: 90, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(height: 90, color: Colors.blue.shade50, child: const Icon(Icons.directions_bus)))),
      Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Row(children: [Icon(Icons.calendar_today, size: 10, color: Colors.grey.shade500), const SizedBox(width: 4), Text(dateLabel, style: TextStyle(fontSize: 10, color: Colors.grey.shade600))]),
        const SizedBox(height: 6),
        Text.rich(TextSpan(children: [const TextSpan(text: 'À partir de ', style: TextStyle(fontSize: 10, color: Colors.grey)), TextSpan(text: price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00A86B)))]))
      ]))
    ])));
  }
}
