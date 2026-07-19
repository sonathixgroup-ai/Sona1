// lib/presentation/thix_event/widgets/event_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final bool isCompact;
  final VoidCallback? onShare;
  final VoidCallback? onFavoriteTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isCompact = false,
    this.onShare,
    this.onFavoriteTap,
  });

  // Palette violette THIX EVENEMENT — variations par catégorie,
  // toutes dans la même famille pour rester cohérent avec le violet global.
  static const Map<String, Color> _categoryColors = {
    'musique': Color(0xFF6B3BFF),      // violet principal
    'concert': Color(0xFF6B3BFF),      // violet principal
    'conference': Color(0xFFF59E0B),   // ambre (contraste chaud)
    'culture': Color(0xFF3B82F6),      // bleu
    'sport': Color(0xFF10B981),        // vert
    'match': Color(0xFF10B981),        // vert
    'festival': Color(0xFFEC4899),     // rose
    'spectacle': Color(0xFF7C3AED),    // violet secondaire
    'exposition': Color(0xFF3B82F6),   // bleu
  };

  static const Color _defaultColor = Color(0xFF6B3BFF); // violet THIX par défaut

  Color get _accentColor => _categoryColors[event.category.toLowerCase()] ?? _defaultColor;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }
    return _buildGridCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final accent = _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Image.network(
                          event.imageUrl!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 110,
                              color: const Color(0xFFF3F0FF),
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 110,
                            color: const Color(0xFFF3F0FF),
                            child: Icon(Icons.broken_image_rounded, size: 26, color: accent.withOpacity(0.5)),
                          ),
                        )
                      : Container(
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withOpacity(0.85), accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.event_rounded, size: 28, color: Colors.white70),
                        ),
                ),
                // Dégradé bas pour lisibilité si besoin futur (titre overlay, etc.)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.0), Colors.black.withOpacity(0.0)],
                      ),
                    ),
                  ),
                ),
                // Badge catégorie — coloré selon la catégorie, cohérent violet
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getCategoryLabel(event.category),
                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                    ),
                  ),
                ),
                // Bouton favori
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Icon(
                        event.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14,
                        color: event.isLiked ? const Color(0xFFEC4899) : const Color(0xFF8B8BA7),
                      ),
                    ),
                  ),
                ),
                if (event.isFree)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'GRATUIT',
                        style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, height: 1.2, color: Color(0xFF1E1B4B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(event.shortDate, style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, size: 10, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          event.formattedPrice,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: accent),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onShare != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: IconButton(
                            icon: const Icon(Icons.share_rounded, size: 14, color: Colors.grey),
                            onPressed: onShare,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 0),
                      ),
                      child: const Text('Réserver', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
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

  Widget _buildCompactCard(BuildContext context) {
    final accent = _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: event.imageUrl != null && event.imageUrl!.isNotEmpty
                      ? Image.network(
                          event.imageUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(width: 72, height: 72, color: const Color(0xFFF3F0FF));
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.85), accent])),
                            child: const Icon(Icons.event_rounded, size: 24, color: Colors.white70),
                          ),
                        )
                      : Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [accent.withOpacity(0.85), accent])),
                          child: const Icon(Icons.event_rounded, size: 24, color: Colors.white70),
                        ),
                ),
                if (onFavoriteTap != null)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle),
                        child: Icon(
                          event.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 10,
                          color: event.isLiked ? const Color(0xFFEC4899) : const Color(0xFF8B8BA7),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _getCategoryLabel(event.category),
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: accent),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E1B4B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 9, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(event.shortDate, style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                      const SizedBox(width: 8),
                      Icon(Icons.location_on_rounded, size: 9, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: accent),
                      ),
                      if (onShare != null)
                        IconButton(
                          icon: const Icon(Icons.share_rounded, size: 14, color: Colors.grey),
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
      'musique': 'MUSIQUE',
      'concert': 'CONCERT',
      'conference': 'CONFÉRENCE',
      'culture': 'CULTURE',
      'sport': 'SPORT',
      'match': 'MATCH',
      'festival': 'FESTIVAL',
      'spectacle': 'SPECTACLE',
      'exposition': 'EXPOSITION',
    };
    return labels[slug.toLowerCase()] ?? slug.toUpperCase();
  }
}
