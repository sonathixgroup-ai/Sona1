// lib/presentation/thix_event/widgets/category_chip.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _ThixColors {
  static const Color primary = Color(0xFF6B3CE2);
  static const Color darkText = Color(0xFF1E1B4B);
  static const Color mutedText = Color(0xFF8B8BA7);
  static const Color border = Color(0xFFEEE9FF);
}

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? _ThixColors.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _ThixColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _ThixColors.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? _ThixColors.primary : _ThixColors.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? _ThixColors.primary : _ThixColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChipsList extends StatelessWidget {
  final String? selectedSlug;
  final Function(String slug)? onCategorySelected;

  const CategoryChipsList({
    super.key,
    this.selectedSlug,
    this.onCategorySelected,
  });

  // Liste des catégories dynamiques
  static const List<Map<String, dynamic>> _categories = [
    {'slug': 'musique', 'label': 'Musique', 'icon': Icons.music_note_rounded},
    {'slug': 'conference', 'label': 'Conférences', 'icon': Icons.mic_rounded},
    {'slug': 'culture', 'label': 'Culture', 'icon': Icons.palette_rounded},
    {'slug': 'sport', 'label': 'Sport', 'icon': Icons.sports_soccer_rounded},
    {'slug': 'festival', 'label': 'Festivals', 'icon': Icons.celebration_rounded},
    {'slug': 'spectacle', 'label': 'Spectacles', 'icon': Icons.theater_comedy_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: _categories.map((cat) {
          final slug = cat['slug'] as String;
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = selectedSlug == slug;

          return CategoryChip(
            label: label,
            slug: slug,
            icon: icon,
            isSelected: isSelected,
            onTap: () {
              // Si un callback personnalisé est fourni, on l'utilise, sinon navigation par défaut GoRouter
              if (onCategorySelected != null) {
                onCategorySelected!(slug);
              } else {
                context.push('/thix-event/category/$slug');
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
