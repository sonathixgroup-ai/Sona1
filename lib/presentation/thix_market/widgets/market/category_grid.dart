// lib/presentation/thix_market/widgets/market/category_grid.dart
import 'package:flutter/material.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  final List<Map<String, dynamic>> categories = const [
    {'icon': Icons.checkroom, 'name': 'Mode', 'color': 0xFFE5592F},
    {'icon': Icons.phone_android, 'name': 'Électronique', 'color': 0xFF2196F3},
    {'icon': Icons.home, 'name': 'Maison & Jardin', 'color': 0xFF4CAF50},
    {'icon': Icons.build, 'name': 'Services', 'color': 0xFFFF9800},
    {'icon': Icons.directions_car, 'name': 'Véhicules', 'color': 0xFF9C27B0},
    {'icon': Icons.house, 'name': 'Immobilier', 'color': 0xFF795548},
    {'icon': Icons.sports_soccer, 'name': 'Sport & Loisirs', 'color': 0xFF00BCD4},
    {'icon': Icons.spa, 'name': 'Beauté & Bien-être', 'color': 0xFFE91E63},
    {'icon': Icons.child_care, 'name': 'Enfants & Bébés', 'color': 0xFFFF6B35},
    {'icon': Icons.pets, 'name': 'Animaux', 'color': 0xFF8BC34A},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 95,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              // Navigation vers la catégorie (à implémenter)
            },
            child: Container(
              width: 68,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(cat['color']).withOpacity(0.15),
                          Color(cat['color']).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      cat['icon'],
                      color: Color(cat['color']),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cat['name'],
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
