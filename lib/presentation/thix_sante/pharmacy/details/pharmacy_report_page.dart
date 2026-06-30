// presentation/thix_sante/pharmacy/details/pharmacy_report_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmacyReportPage extends StatefulWidget {
  final String? reportId;
  const PharmacyReportPage({super.key, this.reportId});

  @override
  State<PharmacyReportPage> createState() => _PharmacyReportPageState();
}

class _PharmacyReportPageState extends State<PharmacyReportPage>
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
        title: const Text('Rapports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'CA'),
            Tab(text: 'Commandes'),
            Tab(text: 'Prescriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportCard('Chiffre d\'affaires', '1 250 €', 'En hausse de 12%'),
          _buildReportCard('Commandes', '45', 'Dont 5 en attente'),
          _buildReportCard('Médicaments prescrits', '120', 'Top : Paracétamol'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rapport généré (simulé)')),
          );
        },
        child: const Icon(Icons.generating_tokens),
      ),
    );
  }

  Widget _buildReportCard(String title, String value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
