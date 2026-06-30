// lib/presentation/thix_event/widgets/event_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool isCompact;
  final VoidCallback? onShare;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isCompact = false,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Image.network(
                          event.imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 120,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(Icons.event, size: 30, color: Colors.grey),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.shortDate,
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (event.isFree)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GRATUIT',
                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCategoryLabel(event.category),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 10, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.formattedPrice,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      ),
                      Row(
                        children: [
                          if (onShare != null)
                            IconButton(
                              icon: const Icon(Icons.share, size: 14, color: Colors.grey),
                              onPressed: onShare,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Réserver',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                            ),
                          ),
                        ],
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

  Widget _buildCompactCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                  ? Image.network(
                      event.imageUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(width: 70, height: 70, color: Colors.grey[200]);
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[200],
                        child: const Icon(Icons.event, size: 30, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.event, size: 30, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getCategoryLabel(event.category),
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 9, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(event.shortDate, style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on, size: 9, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.formattedPrice,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                      ),
                      if (onShare != null)
                        IconButton(
                          icon: const Icon(Icons.share, size: 14, color: Colors.grey),
                          onPressed: onShare,
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

  String _getCategoryLabel(String slug) {
    const labels = {
      'musique': '🎵 MUSIQUE',
      'conference': '🎤 CONFÉRENCE',
      'culture': '🎨 CULTURE',
      'sport': '⚽ SPORT',
      'festival': '🎪 FESTIVAL',
      'spectacle': '🎭 SPECTACLE',
      'exposition': '🖼️ EXPOSITION',
    };
    return labels[slug]?.toUpperCase() ?? slug.toUpperCase();
  }
}
