// 📁 lib/presentation/thix_sante/common/screens/4_medical_documents_screen.dart

import 'package:flutter/material.dart';
import '_components/vaccination_content.dart';
import '_components/documents_content.dart';
import '_components/share_content.dart';

class MedicalDocumentsScreen extends StatefulWidget {
  const MedicalDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<MedicalDocumentsScreen> createState() => _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState extends State<MedicalDocumentsScreen>
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
        title: const Text('Dossier médical'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.vaccines), text: 'Vaccins'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.share), text: 'Partage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VaccinationContent(),
          DocumentsContent(),
          ShareContent(),
        ],
      ),
    );
  }
}
