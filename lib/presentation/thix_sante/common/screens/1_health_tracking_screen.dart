// 📁 lib/presentation/thix_sante/common/screens/1_health_tracking_screen.dart

import 'package:flutter/material.dart';
import '_components/symptom_tracker_content.dart';
import '_components/constants_content.dart';
import '_components/medication_content.dart';

class HealthTrackingScreen extends StatefulWidget {
  const HealthTrackingScreen({Key? key}) : super(key: key);

  @override
  State<HealthTrackingScreen> createState() => _HealthTrackingScreenState();
}

class _HealthTrackingScreenState extends State<HealthTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi santé'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.sick), text: 'Symptômes'),
            Tab(icon: Icon(Icons.monitor_heart), text: 'Constantes'),
            Tab(icon: Icon(Icons.medication), text: 'Traitements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SymptomTrackerContent(),
          ConstantsContent(),
          MedicationContent(),
        ],
      ),
    );
  }
}
