// Contient les widgets partagés : ThixIdentityBadge, NotificationItem, ContentCard, etc.
import 'package:flutter/material.dart';

class ThixIdentityBadge extends StatelessWidget {
  const ThixIdentityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text('THIX ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
        ],
      ),
    );
  }
}

class NotificationItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;
  const NotificationItem({super.key, required this.title, required this.subtitle, required this.time, this.isRead = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: isRead ? Colors.white : Colors.blue.shade50,
      child: Row(
        children: [
          const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.notifications, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ContentCard : un widget générique pour afficher des éléments divers (event, podcast, masterclass, mentor, group, survey, portfolio)
class ContentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final IconData? icon;
  final VoidCallback onTap;
  const ContentCard({super.key, required this.title, required this.subtitle, this.imageUrl, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl!, width: 60, height: 60, fit: BoxFit.cover),
              )
            else if (icon != null)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 30, color: Colors.grey.shade600),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Autres widgets fusionnés (translation_overlay, focus_mode_indicator, live_reaction_animation)
class TranslationOverlay extends StatelessWidget {
  final String text;
  const TranslationOverlay({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    color: Colors.black.withOpacity(0.7),
    child: Text(text, style: const TextStyle(color: Colors.white)),
  );
}

class FocusModeIndicator extends StatelessWidget {
  const FocusModeIndicator({super.key});
  @override
  Widget build(BuildContext context) => const Chip(label: Text('🔕 Mode Focus'), backgroundColor: Colors.grey);
}

class LiveReactionAnimation extends StatelessWidget {
  final String emoji;
  const LiveReactionAnimation({super.key, this.emoji = '❤️'});
  @override
  Widget build(BuildContext context) => Text(emoji, style: const TextStyle(fontSize: 40));
}
