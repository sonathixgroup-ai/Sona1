// 📁 lib/presentation/thix_sante/patient/navigation/patient_bottom_nav.dart

import 'package:flutter/material.dart';
import '../screens/patient_home_screen.dart';
import '../screens/patient_tracking_screen.dart';
import '../screens/patient_appointments_screen.dart';
import '../screens/patient_messages_screen.dart';
import '../screens/patient_profile_screen.dart';

class PatientBottomNav extends StatefulWidget {
  const PatientBottomNav({Key? key}) : super(key: key);

  @override
  State<PatientBottomNav> createState() => _PatientBottomNavState();
}

class _PatientBottomNavState extends State<PatientBottomNav> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const PatientHomeScreen(),
    const PatientTrackingScreen(),
    const PatientAppointmentsScreen(),
    const PatientMessagesScreen(),
    const PatientProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'Suivi'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'RDV'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
