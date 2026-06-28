// lib/presentation/network/widgets/bottom_navbar.dart
import 'package:flutter/material.dart';

class NetworkBottomNavbar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const NetworkBottomNavbar({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Réseau'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Créer'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
