import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1A73E8),
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24),
            activeIcon: Icon(Icons.home, size: 24),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined, size: 24),
            activeIcon: Icon(Icons.explore, size: 24),
            label: 'Découvrir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, size: 24),
            activeIcon: Icon(Icons.people, size: 24),
            label: 'Connexions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24),
            activeIcon: Icon(Icons.person, size: 24),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
