// 📁 lib/presentation/thix_sante/doctor/navigation/doctor_bottom_nav.dart

import 'package:flutter/material.dart';
import '../screens/doctor_dashboard_screen.dart';
import '../screens/doctor_patient_list_screen.dart';
import '../screens/doctor_schedule_screen.dart';
import '../screens/doctor_messages_screen.dart';
import '../screens/doctor_profile_screen.dart';

class DoctorBottomNav extends StatefulWidget {
  const DoctorBottomNav({Key? key}) : super(key: key);

  @override
  State<DoctorBottomNav> createState() => _DoctorBottomNavState();
}

class _DoctorBottomNavState extends State<DoctorBottomNav> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DoctorDashboardScreen(),
    const DoctorPatientListScreen(),
    const DoctorScheduleScreen(),
    const DoctorMessagesScreen(),
    const DoctorProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Agenda'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), activeIcon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
