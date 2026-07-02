// presentation/thix_sante/pharmacy/details/pharmacy_products_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thix_id/auth/auth_controller.dart';

class PharmacyProductsPage extends StatefulWidget {
  const PharmacyProductsPage({super.key});

  @override
  State<PharmacyProductsPage> createState() => _PharmacyProductsPageState();
}

class _PharmacyProductsPageState extends State<PharmacyProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'Tous';
  final List<String> _categories = ['Tous', 'Analgésiques', 'Antibiotiques', 'Antihistaminiques', 'Cardiologie', 'Dermatologie'];

  // Catalogue de produits (simulé – à connecter à Supabase)
  final List<Map<String, dynamic>> _products = [
    {'id': 'p1', 'name': 'Paracétamol 500mg', 'price': 5.50, 'category': 'Analgésiques', 'dosage': '500 mg', 'inStock': true, 'image': '💊', 'description': 'Antalgique et antipyrétique. Utilisé contre les douleurs et la fièvre.'},
    {'id': 'p2', 'name': 'Amoxicilline 250mg', 'price': 8.00, 'category': 'Antibiotiques', 'dosage': '250 mg', 'inStock': true, 'image': '💊', 'description': 'Antibiotique à large spectre pour infections bactériennes.'},
    {'id': 'p3', 'name': 'Ibuprofène 400mg', 'price': 4.50, 'category': 'Analgésiques', 'dosage': '400 mg', 'inStock': false, 'image': '💊', 'description': 'Anti-inflammatoire non stéroïdien.'},
    {'id': 'p4', 'name': 'Oméprazole 20mg', 'price': 6.00, 'category': 'Cardiologie', 'dosage': '20 mg', 'inStock': true, 'image': '💊', 'description': 'Inhibiteur de la pompe à protons pour le reflux gastrique.'},
    {'id': 'p5', 'name': 'Céfuroxime 500mg', 'price': 12.50, 'category': 'Antibiotiques', 'dosage': '500 mg', 'inStock': true, 'image': '💊', 'description': 'Antibiotique céphalosporine de 2e génération.'},
    {'id': 'p6', 'name': 'Loratadine 10mg', 'price': 3.20, 'category': 'Antihistaminiques', 'dosage': '10 mg', 'inStock': true, 'image': '💊', 'description': 'Antihistaminique non sédatif pour allergies.'},
    {'id': 'p7', 'name': 'Atorvastatine 20mg', 'price': 9.90, 'category': 'Cardiologie', 'dosage': '20 mg', 'inStock': false, 'image': '💊', 'description': 'Statine pour réguler le cholestérol.'},
    {'id': 'p8', 'name': 'Hydrocortisone 1%', 'price': 7.30, 'category': 'Dermatologie', 'dosage': '1%', 'inStock': true, 'image': '🧴', 'description': 'Corticostéroïde topique pour inflammations cutanées.'},
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final matchesQuery = p['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p['category'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p['description'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _filterCategory == 'Tous' || p['category'] == _filterCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    // Simuler l'ajout au panier – dans une vraie app, on aurait un CartProvider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ajouté au panier'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Catalogue médicaments'),
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
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Filtres de catégories (défilables)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return FilterChip(
                  label: Text(cat),
                  selected: _filterCategory == cat,
                  onSelected: (_) => setState(() => _filterCategory = cat),
                  selectedColor: Colors.orange.shade100,
                  backgroundColor: Colors.white,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Résultats
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun produit trouvé.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isInStock = p['inStock'] as bool;
                      return GestureDetector(
                        onTap: () => context.push('/sante/pharmacy/product/${p['id']}'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p['image'] as String,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const Spacer(),
                                  if (!isInStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Rupture',
                                        style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p['name'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p['dosage'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text(
                                    '${p['price']} €',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isInStock)
                                    IconButton(
                                      icon: const Icon(Icons.add_shopping_cart, size: 18),
                                      color: Colors.orange,
                                      onPressed: () => _addToCart(p),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => context.push('/sante/pharmacy/cart'),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
    );
  }
}
