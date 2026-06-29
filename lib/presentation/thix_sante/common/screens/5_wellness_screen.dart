// 📁 lib/presentation/thix_sante/common/screens/5_wellness_screen.dart

import 'package:flutter/material.dart';
import '_components/wellness_programs_content.dart';
import '_components/pregnancy_content.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({Key? key}) : super(key: key);

  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Bien-être'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Programmes'),
            Tab(icon: Icon(Icons.pregnant_woman), text: 'Grossesse'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WellnessProgramsContent(),
          PregnancyContent(),
        ],
      ),
    );
  }
}
