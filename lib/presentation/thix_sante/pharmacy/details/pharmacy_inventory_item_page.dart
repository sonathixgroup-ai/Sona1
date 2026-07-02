// presentation/thix_sante/pharmacy/details/pharmacy_inventory_item_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyInventoryItemPage extends StatefulWidget {
  final String? itemId;
  final bool isEditing;
  const PharmacyInventoryItemPage({super.key, this.itemId, this.isEditing = false});

  @override
  State<PharmacyInventoryItemPage> createState() => _PharmacyInventoryItemPageState();
}

class _PharmacyInventoryItemPageState extends State<PharmacyInventoryItemPage> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _thresholdController = TextEditingController();
  final _priceController = TextEditingController();

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
      const SnackBar(content: Text('Article enregistré (simulé)'), backgroundColor: Colors.green),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.itemId == null;
    final title = isNew ? 'Ajouter article' : (widget.isEditing ? 'Modifier article' : 'Détail article');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!isNew && !widget.isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _infoRow('Nom', 'Paracétamol'),
                      _infoRow('Quantité', '150'),
                      _infoRow('Seuil', '50'),
                      _infoRow('Prix unitaire', '5.50 €'),
                      _infoRow('Statut', 'Stock OK'),
                    ],
                  ),
                ),
              ] else ...[
                _buildForm(),
              ],
              const SizedBox(height: 16),
              if (widget.isEditing || isNew)
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(isNew ? 'Ajouter' : 'Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nom du produit'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _quantityController,
          decoration: const InputDecoration(labelText: 'Quantité'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _thresholdController,
          decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceController,
          decoration: const InputDecoration(labelText: 'Prix unitaire'),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
