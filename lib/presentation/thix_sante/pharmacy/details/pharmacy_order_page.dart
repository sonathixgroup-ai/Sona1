// presentation/thix_sante/pharmacy/details/pharmacy_order_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyOrderPage extends StatefulWidget {
  final String orderId;
  final bool isEditing;
  const PharmacyOrderPage({super.key, required this.orderId, this.isEditing = false});

  @override
  State<PharmacyOrderPage> createState() => _PharmacyOrderPageState();
}

class _PharmacyOrderPageState extends State<PharmacyOrderPage> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _noteController.text = 'Commande urgente';
  }

  Future<void> _save() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande mise à jour (simulé)'), backgroundColor: Colors.green),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Modifier commande' : 'Détail commande';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    _infoRow('Commande', '#1234'),
                    _infoRow('Patient', 'Michel L.'),
                    _infoRow('Statut', 'En attente'),
                    _infoRow('Date', '10/03/2024'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _itemRow('Paracétamol', '2', '11.00 €'),
                    _itemRow('Amoxicilline', '1', '8.00 €'),
                    const Divider(),
                    _itemRow('Total', '', '19.00 €', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              if (widget.isEditing)
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Enregistrer'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(String label, String qty, String price, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: bold ? GoogleFonts.poppins(fontWeight: FontWeight.bold) : null),
          ),
          if (qty.isNotEmpty) Text(qty, style: bold ? GoogleFonts.poppins(fontWeight: FontWeight.bold) : null),
          const SizedBox(width: 8),
          Text(price, style: bold ? GoogleFonts.poppins(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
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
