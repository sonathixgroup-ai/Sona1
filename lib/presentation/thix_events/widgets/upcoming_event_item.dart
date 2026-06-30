// lib/presentation/thix_event/widgets/upcoming_event_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/event_model.dart';

class UpcomingEventItem extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const UpcomingEventItem({
    super.key,
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(event.startDate),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                  ),
                  Text(
                    DateFormat('MMM').format(event.startDate).toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
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
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(
                        '${DateFormat('HH:mm').format(event.startDate)} • ${event.location}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                event.formattedPrice,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
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
