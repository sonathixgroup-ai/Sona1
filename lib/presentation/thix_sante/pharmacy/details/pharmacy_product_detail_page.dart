// presentation/thix_sante/pharmacy/details/pharmacy_product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PharmacyProductDetailPage extends StatefulWidget {
  final String productId;
  const PharmacyProductDetailPage({super.key, required this.productId});

  @override
  State<PharmacyProductDetailPage> createState() => _PharmacyProductDetailPageState();
}

class _PharmacyProductDetailPageState extends State<PharmacyProductDetailPage> {
  // Simuler la récupération du produit – dans la vraie vie, on viendrait de Supabase
  Map<String, dynamic>? _product;
  int _quantity = 1;

  final Map<String, Map<String, dynamic>> _productsData = {
    'p1': {'name': 'Paracétamol 500mg', 'price': 5.50, 'category': 'Analgésiques', 'dosage': '500 mg', 'inStock': true, 'image': '💊', 'description': 'Antalgique et antipyrétique. Utilisé contre les douleurs et la fièvre.', 'indications': 'Douleurs légères à modérées, fièvre.', 'contraindications': 'Insuffisance hépatique sévère, allergie au paracétamol.'},
    'p2': {'name': 'Amoxicilline 250mg', 'price': 8.00, 'category': 'Antibiotiques', 'dosage': '250 mg', 'inStock': true, 'image': '💊', 'description': 'Antibiotique à large spectre pour infections bactériennes.', 'indications': 'Infections respiratoires, ORL, urinaires.', 'contraindications': 'Allergie aux pénicillines.'},
    'p3': {'name': 'Ibuprofène 400mg', 'price': 4.50, 'category': 'Analgésiques', 'dosage': '400 mg', 'inStock': false, 'image': '💊', 'description': 'Anti-inflammatoire non stéroïdien.', 'indications': 'Douleurs, inflammations, fièvre.', 'contraindications': 'Ulcère gastro-duodénal, insuffisance rénale.'},
    'p4': {'name': 'Oméprazole 20mg', 'price': 6.00, 'category': 'Cardiologie', 'dosage': '20 mg', 'inStock': true, 'image': '💊', 'description': 'Inhibiteur de la pompe à protons pour le reflux gastrique.', 'indications': 'Reflux gastro-œsophagien, ulcère gastrique.', 'contraindications': 'Allergie à l\'oméprazole.'},
    'p5': {'name': 'Céfuroxime 500mg', 'price': 12.50, 'category': 'Antibiotiques', 'dosage': '500 mg', 'inStock': true, 'image': '💊', 'description': 'Antibiotique céphalosporine de 2e génération.', 'indications': 'Infections respiratoires, ORL, cutanées.', 'contraindications': 'Allergie aux céphalosporines.'},
    'p6': {'name': 'Loratadine 10mg', 'price': 3.20, 'category': 'Antihistaminiques', 'dosage': '10 mg', 'inStock': true, 'image': '💊', 'description': 'Antihistaminique non sédatif pour allergies.', 'indications': 'Rhinite allergique, urticaire.', 'contraindications': 'Allergie à la loratadine.'},
    'p7': {'name': 'Atorvastatine 20mg', 'price': 9.90, 'category': 'Cardiologie', 'dosage': '20 mg', 'inStock': false, 'image': '💊', 'description': 'Statine pour réguler le cholestérol.', 'indications': 'Hypercholestérolémie, prévention cardiovasculaire.', 'contraindications': 'Insuffisance hépatique, grossesse.'},
    'p8': {'name': 'Hydrocortisone 1%', 'price': 7.30, 'category': 'Dermatologie', 'dosage': '1%', 'inStock': true, 'image': '🧴', 'description': 'Corticostéroïde topique pour inflammations cutanées.', 'indications': 'Eczéma, dermatite, piqûres d\'insectes.', 'contraindications': 'Infections cutanées non traitées.'},
  };

  @override
  void initState() {
    super.initState();
    _product = _productsData[widget.productId];
  }

  void _addToCart() {
    if (_product == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_product!['name']} x$_quantity ajouté au panier'),
        backgroundColor: Colors.green,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produit'), backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('Produit introuvable.')),
      );
    }

    final p = _product!;
    final isInStock = p['inStock'] as bool;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(p['name']),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.orange.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/sante/pharmacy/cart'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Text(p['image'] as String, style: const TextStyle(fontSize: 48)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Nom et dosage
            Text(
              p['name'] as String,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${p['dosage']} • ${p['category']}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            // Disponibilité
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isInStock ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isInStock ? '✅ En stock' : '❌ Rupture de stock',
                style: TextStyle(
                  color: isInStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Prix
            Text(
              '${p['price']} €',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            // Description
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              p['description'] as String,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            // Indications
            const Text(
              'Indications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              p['indications'] as String? ?? 'Non renseigné',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            // Contre-indications
            const Text(
              'Contre-indications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              p['contraindications'] as String? ?? 'Aucune signalée',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.red.shade700),
            ),
            const SizedBox(height: 24),
            // Quantité et ajout au panier
            if (isInStock) ...[
              Row(
                children: [
                  const Text('Quantité : '),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                  ),
                  Text(
                    '$_quantity',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _quantity++),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text('Ajouter au panier (${_quantity * (p['price'] as double)} €)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
