import 'package:flutter/material.dart';

class CategoryGrid extends StatelessWidget {
  final Function(String)? onCategoryTap;
  
  const CategoryGrid({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': Icons.checkroom, 'name': 'Mode', 'color': 0xFFE5592F},
      {'icon': Icons.phone_android, 'name': 'Électronique', 'color': 0xFF2196F3},
      {'icon': Icons.home, 'name': 'Maison', 'color': 0xFF4CAF50},
      {'icon': Icons.build, 'name': 'Services', 'color': 0xFFFF9800},
      {'icon': Icons.directions_car, 'name': 'Véhicules', 'color': 0xFF9C27B0},
      {'icon': Icons.house, 'name': 'Immobilier', 'color': 0xFF795548},
      {'icon': Icons.sports_soccer, 'name': 'Sport', 'color': 0xFF00BCD4},
      {'icon': Icons.spa, 'name': 'Beauté', 'color': 0xFFE91E63},
      {'icon': Icons.child_care, 'name': 'Enfants', 'color': 0xFFFF6B35},
      {'icon': Icons.pets, 'name': 'Animaux', 'color': 0xFF8BC34A},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Catégories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            crossAxisCount: 5,
            childAspectRatio: 0.9,
            children: categories.map((category) {
              return _buildCategoryItem(
                icon: category['icon'] as IconData,
                name: category['name'] as String,
                color: Color(category['color'] as int),
                onTap: () => onCategoryTap?.call(category['name'] as String),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String name,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.8), color],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
