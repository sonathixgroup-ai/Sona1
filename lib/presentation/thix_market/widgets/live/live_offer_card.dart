import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class LiveOfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final VoidCallback? onTap;
  final VoidCallback? onClaim;

  const LiveOfferCard({
    super.key,
    required this.offer,
    this.onTap,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final timeLeft = offer['expires_at'] != null
        ? DateTime.parse(offer['expires_at']).difference(DateTime.now())
        : null;
    final isExpired = timeLeft != null && timeLeft.isNegative;
    
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: offer['image_url'] ?? '',
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (offer['discount_percentage'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${offer['discount_percentage'].toInt()}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (timeLeft != null && !isExpired)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(timeLeft),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer['title'] ?? 'Offre flash',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${offer['price'].toInt()} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE5592F),
                        ),
                      ),
                      if (offer['original_price'] != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${offer['original_price'].toInt()} FCFA',
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (offer['stock'] != null)
                    LinearProgressIndicator(
                      value: ((offer['stock_initial'] - offer['stock']) / offer['stock_initial']),
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE5592F)),
                    ),
                  if (offer['stock'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Plus que ${offer['stock']} disponibles',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (onClaim != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isExpired ? null : onClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5592F),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(isExpired ? 'Expirée' : 'Profiter'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '00:00';
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
