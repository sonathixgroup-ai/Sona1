// 📁 lib/presentation/thix_sante/pharmacy/screens/pharmacy_inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/drug_inventory_item.dart';
import '../../../common/widgets/search_bar.dart';
import '../../../common/widgets/gradient_button.dart';
import '../../../common/widgets/empty_state.dart';

class PharmacyInventoryScreen extends ConsumerStatefulWidget {
  const PharmacyInventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PharmacyInventoryScreen> createState() => _PharmacyInventoryScreenState();
}

class _PharmacyInventoryScreenState extends ConsumerState<PharmacyInventoryScreen> {
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'Amoxicilline', 'dosage': '500mg', 'quantity': 45, 'threshold': 30, 'batch': 'B2024-01'},
    {'name': 'Paracétamol', 'dosage': '1000mg', 'quantity': 12, 'threshold': 20, 'batch': 'B2024-02'},
    {'name': 'Ibuprofène', 'dosage': '400mg', 'quantity': 78, 'threshold': 50, 'batch': 'B2024-03'},
    {'name': 'Loratadine', 'dosage': '10mg', 'quantity': 8, 'threshold': 15, 'batch': 'B2024-04'},
    {'name': 'Oméprazole', 'dosage': '20mg', 'quantity': 120, 'threshold': 40, 'batch': 'B2024-05'},
  ];

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = _inventory;
  }

  void _search(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _inventory;
      } else {
        _filtered = _inventory.where((d) =>
          d['name'].toLowerCase().contains(query.toLowerCase()) ||
          d['dosage'].toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaire'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDrugDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          CustomSearchBar(
            onSearch: _search,
            hintText: 'Rechercher un médicament...',
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyStateWidget(
                    title: 'Aucun médicament',
                    subtitle: 'Ajoutez des médicaments à l\'inventaire',
                    icon: Icons.medication_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final d = _filtered[index];
                      return DrugInventoryItem(
                        name: d['name']!,
                        dosage: d['dosage']!,
                        quantity: d['quantity']!,
                        threshold: d['threshold']!,
                        batchNumber: d['batch'],
                        onTap: () => _showDrugDetail(d),
                        onEdit: () => _showEditDrugDialog(d),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDrugDetail(Map<String, dynamic> drug) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(drug['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Dosage: ${drug['dosage']}', style: const TextStyle(fontSize: 13)),
            Text('Quantité: ${drug['quantity']} unités', style: const TextStyle(fontSize: 13)),
            Text('Seuil: ${drug['threshold']} unités', style: const TextStyle(fontSize: 13)),
            if (drug['batch'] != null) Text('Lot: ${drug['batch']}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'Modifier',
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDrugDialog(drug);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDrugDialog() {
    // Simule l'ajout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'ajout en développement'), backgroundColor: Colors.orange),
    );
  }

  void _showEditDrugDialog(Map<String, dynamic> drug) {
    // Simule l'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de modification en développement'), backgroundColor: Colors.orange),
    );
  }
}
