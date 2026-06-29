// 📁 lib/presentation/thix_sante/common/screens/6_family_care_screen.dart

import 'package:flutter/material.dart';
import '_components/family_content.dart';
import '_components/teleexpertise_content.dart';

class FamilyCareScreen extends StatefulWidget {
  const FamilyCareScreen({Key? key}) : super(key: key);

  @override
  State<FamilyCareScreen> createState() => _FamilyCareScreenState();
}

class _FamilyCareScreenState extends State<FamilyCareScreen>
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
        title: const Text('Famille & Entraide'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.family_restroom), text: 'Famille'),
            Tab(icon: Icon(Icons.medical_services), text: 'Téléexpertise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FamilyContent(),
          TeleexpertiseContent(),
        ],
      ),
    );
  }
}
