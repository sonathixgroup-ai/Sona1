// presentation/thix_sante/pharmacy/details/pharmacy_order_create_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyOrderCreatePage extends StatefulWidget {
  const PharmacyOrderCreatePage({super.key});

  @override
  State<PharmacyOrderCreatePage> createState() => _PharmacyOrderCreatePageState();
}

class _PharmacyOrderCreatePageState extends State<PharmacyOrderCreatePage> {
  final _patientController = TextEditingController();
  final _noteController = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  double _total = 0;

  void _addItem() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Produit')),
            TextField(decoration: const InputDecoration(labelText: 'Quantité'), keyboardType: TextInputType.number),
            TextField(decoration: const InputDecoration(labelText: 'Prix unitaire'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.add({'product': 'Paracétamol', 'qty': 2, 'price': 5.5});
                _total += 11.0;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande créée (simulé)'), backgroundColor: Colors.green),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Nouvelle commande'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _patientController,
                decoration: const InputDecoration(labelText: 'Patient *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addItem,
                  ),
                ],
              ),
              ..._items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item['product']} x ${item['qty']}'),
                        ),
                        Text('${item['price'] * item['qty']} €'),
                      ],
                    ),
                  )),
              const Divider(),
              Row(
                children: [
                  const Text('Total : ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_total.toStringAsFixed(2)} €'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Créer la commande'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
