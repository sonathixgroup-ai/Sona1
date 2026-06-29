// 📁 lib/presentation/thix_sante/pharmacy/navigation/pharmacy_bottom_nav.dart

import 'package:flutter/material.dart';
import '../screens/pharmacy_dashboard_screen.dart';
import '../screens/pharmacy_orders_screen.dart';
import '../screens/pharmacy_inventory_screen.dart';
import '../screens/pharmacy_messages_screen.dart';
import '../screens/pharmacy_profile_screen.dart';

class PharmacyBottomNav extends StatefulWidget {
  const PharmacyBottomNav({Key? key}) : super(key: key);

  @override
  State<PharmacyBottomNav> createState() => _PharmacyBottomNavState();
}

class _PharmacyBottomNavState extends State<PharmacyBottomNav> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const PharmacyDashboardScreen(),
    const PharmacyOrdersScreen(),
    const PharmacyInventoryScreen(),
    const PharmacyMessagesScreen(),
    const PharmacyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_outlined), activeIcon: Icon(Icons.receipt), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_outlined), activeIcon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
