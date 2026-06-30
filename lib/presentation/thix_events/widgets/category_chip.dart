// lib/presentation/thix_event/widgets/category_chip.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final String slug;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.slug,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChipsList extends StatelessWidget {
  const CategoryChipsList({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {'slug': 'musique', 'label': 'Musique', 'icon': Icons.music_note},
    {'slug': 'conference', 'label': 'Conférences', 'icon': Icons.mic},
    {'slug': 'culture', 'label': 'Culture', 'icon': Icons.art_track},
    {'slug': 'sport', 'label': 'Sport', 'icon': Icons.sports_soccer},
    {'slug': 'festival', 'label': 'Festivals', 'icon': Icons.celebration},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: _categories.map((cat) {
          return GestureDetector(
            onTap: () => context.push('/thix-event/category/${cat['slug']}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey[300]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat['icon'] as IconData, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
