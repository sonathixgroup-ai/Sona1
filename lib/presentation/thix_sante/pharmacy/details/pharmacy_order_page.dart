// presentation/thix_sante/pharmacy/details/pharmacy_order_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_id/presentation/thix_sante/shared/models/health_models.dart';

class PharmacyOrderPage extends StatefulWidget {
  final String? orderId;
  final bool isEditing;
  const PharmacyOrderPage({super.key, this.orderId, this.isEditing = false});

  @override
  State<PharmacyOrderPage> createState() => _PharmacyOrderPageState();
}

class _PharmacyOrderPageState extends State<PharmacyOrderPage> {
  final List<OrderItem> _items = [];
  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  OrderStatus _status = OrderStatus.pending;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _loadOrder();
    } else {
      _patientController.text = 'Patient';
    }
  }

  void _loadOrder() {
    // Simuler chargement
    _patientController.text = 'Michel L.';
    _noteController.text = 'Commande urgente';
    _status = OrderStatus.pending;
    _items.add(OrderItem(id: 'i1', productName: 'Paracétamol', quantity: 2, unitPrice: 5.5));
    _items.add(OrderItem(id: 'i2', productName: 'Amoxicilline', quantity: 1, unitPrice: 8.0));
  }

  void _addItem() {
    // Simuler ajout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ajouter un article (simulé)')),
    );
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande enregistrée (simulé)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.orderId == null;
    final title = isNew ? 'Nouvelle commande' : (widget.isEditing ? 'Modifier' : 'Détail commande');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isNew && !widget.isEditing) ...[
                _buildDetailView(),
              ] else ...[
                _buildFormView(),
              ],
              const SizedBox(height: 16),
              if (widget.isEditing || isNew)
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isNew ? 'Créer' : 'Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Commande #1234'),
        Text('Patient : ${_patientController.text}'),
        Text('Statut : ${_status.name}'),
        const SizedBox(height: 16),
        const Text('Articles :', style: TextStyle(fontWeight: FontWeight.bold)),
        ..._items.map((item) => ListTile(
              title: Text(item.productName),
              subtitle: Text('Qté: ${item.quantity} • ${item.unitPrice}€'),
            )),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _patientController,
          decoration: const InputDecoration(labelText: 'Patient'),
        ),
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
        ..._items.map((item) => Card(
              child: ListTile(
                title: Text(item.productName),
                subtitle: Text('Qté: ${item.quantity} • ${item.unitPrice}€'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _items.remove(item);
                    });
                  },
                ),
              ),
            )),
      ],
    );
  }
}
