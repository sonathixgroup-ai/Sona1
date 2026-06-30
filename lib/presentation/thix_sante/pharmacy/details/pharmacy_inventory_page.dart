// presentation/thix_sante/pharmacy/details/pharmacy_inventory_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PharmacyInventoryPage extends StatefulWidget {
  final String? itemId;
  final bool isEditing;
  const PharmacyInventoryPage({super.key, this.itemId, this.isEditing = false});

  @override
  State<PharmacyInventoryPage> createState() => _PharmacyInventoryPageState();
}

class _PharmacyInventoryPageState extends State<PharmacyInventoryPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _thresholdController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.itemId != null) {
      _nameController.text = 'Paracétamol';
      _quantityController.text = '150';
      _thresholdController.text = '50';
      _priceController.text = '5.5';
    }
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article enregistré (simulé)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.itemId == null;
    final title = isNew ? 'Ajouter article' : (widget.isEditing ? 'Modifier' : 'Détail article');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
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
                  child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
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
        const Text('Nom : Paracétamol'),
        const Text('Quantité : 150'),
        const Text('Seuil : 50'),
        const Text('Prix : 5.50 €'),
        const Text('Statut : Stock OK'),
      ],
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom du produit'),
        ),
        TextField(
          controller: _quantityController,
          decoration: const InputDecoration(labelText: 'Quantité'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _thresholdController,
          decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(labelText: 'Prix unitaire'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }
}
