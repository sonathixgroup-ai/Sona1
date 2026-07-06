// lib/presentation/thix_market/pages/product_comparator.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductComparator extends StatefulWidget {
  final List<String>? initialProductIds;

  const ProductComparator({super.key, this.initialProductIds});

  @override
  State<ProductComparator> createState() => _ProductComparatorState();
}

class _ProductComparatorState extends State<ProductComparator> {
  List<Map<String, dynamic>> _products = [];
  List<String> _selectedProductIds = [];
  bool _isLoading = false;
  final int _maxCompareProducts = 4;

  static const Color navy = Color(0xFF1B2A4A);
  static const Color gold = Color(0xFFC9962C);
  static const Color danger = Color(0xFFE53935);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color bgApp = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    if (widget.initialProductIds != null && widget.initialProductIds!.isNotEmpty) {
      _selectedProductIds = widget.initialProductIds!.take(_maxCompareProducts).toList();
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    if (_selectedProductIds.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('''
            *,
            shop:shops(name, rating, is_verified)
          ''')
          .inFilter('id', _selectedProductIds);

      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addProduct() async {
    final productIds = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelector(
          excludeIds: _selectedProductIds,
          maxSelect: _maxCompareProducts - _selectedProductIds.length,
        ),
      ),
    );
    if (productIds != null && productIds.isNotEmpty) {
      setState(() {
        _selectedProductIds.addAll(productIds);
      });
      await _loadProducts();
    }
  }

  void _removeProduct(int index) {
    setState(() {
      _selectedProductIds.removeAt(index);
      _products.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedProductIds.clear();
      _products.clear();
    });
  }

  void _shareComparison() {
    if (_products.length < 2) return;
    final buffer = StringBuffer('Comparaison de produits :\n\n');
    for (final product in _products) {
      buffer.writeln('📦 ${product['title']}');
      buffer.writeln('   Prix : ${(product['price'] as num).toInt()} FCFA');
      buffer.writeln('   Marque : ${product['brand'] ?? 'Non spécifiée'}');
      buffer.writeln('   Note : ${product['rating']?.toStringAsFixed(1) ?? '0'} ⭐');
      buffer.writeln('   Stock : ${product['stock'] ?? 0} unités');
      buffer.writeln(
          '   Livraison : ${product['free_shipping'] == true ? 'Gratuite' : 'Payante'}');
      buffer.writeln('   Garantie : ${product['warranty_months'] ?? 0} mois');
      buffer.writeln('');
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Partager la comparaison', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: SelectableText(buffer.toString(), style: const TextStyle(fontSize: 14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              // Intégrer le package share ici pour un vrai partage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage copié dans le presse-papiers')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: navy,
            ),
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: const Text('Comparateur de produits', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_products.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline, color: danger),
              label: const Text('Effacer tout', style: TextStyle(color: danger)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : _products.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // En-tête des produits
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colonne des attributs
                            Container(
                              width: 120,
                              padding: const EdgeInsets.all(12),
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 200),
                                  _buildAttributeHeader('Prix'),
                                  const SizedBox(height: 20),
                                  _buildAttributeHeader('Marque'),
                                  const SizedBox(height: 20),
                                  _buildAttributeHeader('Note'),
                                  const SizedBox(height: 20),
                                  _buildAttributeHeader('Stock'),
                                  const SizedBox(height: 20),
                                  _buildAttributeHeader('Livraison'),
                                  const SizedBox(height: 20),
                                  _buildAttributeHeader('Garantie'),
                                ],
                              ),
                            ),

                            // Colonnes des produits
                            ...List.generate(_products.length, (index) {
                              return _buildProductColumn(_products[index], index);
                            }),

                            // Bouton ajouter
                            if (_selectedProductIds.length < _maxCompareProducts)
                              Container(
                                width: 200,
                                padding: const EdgeInsets.all(12),
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 100),
                                    InkWell(
                                      onTap: _addProduct,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: bgApp,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 40, color: textMuted),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Ajouter un produit',
                                              style: TextStyle(color: textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Boutons d'action
                    if (_products.length >= 2)
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareComparison,
                                icon: const Icon(Icons.share),
                                label: const Text('Partager la comparaison'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: navy,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildProductColumn(Map<String, dynamic> product, int index) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image et suppression
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: product['image_url'] ?? '',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  color: bgApp,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => _removeProduct(index),
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: navy),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['shop']?['name'] ?? 'Boutique',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),

          // Prix
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${(product['price'] as num).toInt()} FCFA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: gold,
              ),
            ),
          ),

          // Marque
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              product['brand'] ?? 'Non spécifiée',
              style: const TextStyle(color: navy),
            ),
          ),

          // Note
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${product['rating']?.toStringAsFixed(1) ?? 0}',
                  style: const TextStyle(color: navy),
                ),
              ],
            ),
          ),

          // Stock
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              (product['stock'] ?? 0) > 0 ? '${product['stock']} unités' : 'Épuisé',
              style: TextStyle(
                color: (product['stock'] ?? 0) > 0 ? Colors.green : danger,
              ),
            ),
          ),

          // Livraison
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              product['free_shipping'] == true ? 'Gratuite' : 'Payante',
              style: TextStyle(
                color: product['free_shipping'] == true ? Colors.green : textMuted,
              ),
            ),
          ),

          // Garantie
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${product['warranty_months'] ?? 0} mois',
              style: const TextStyle(color: navy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: navy,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aucun produit à comparer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navy),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez jusqu\'à $_maxCompareProducts produits',
            style: TextStyle(color: textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addProduct,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: navy,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ProductSelector (sélecteur de produits)
// ============================================================
class ProductSelector extends StatefulWidget {
  final List<String> excludeIds;
  final int maxSelect;

  const ProductSelector({
    super.key,
    required this.excludeIds,
    required this.maxSelect,
  });

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  List<Map<String, dynamic>> _products = [];
  List<String> _selectedIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  static const Color navy = Color(0xFF1B2A4A);
  static const Color gold = Color(0xFFC9962C);
  static const Color textMuted = Color(0xFF8A8FA3);
  static const Color bgApp = Color(0xFFF6F7FB);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      var query = Supabase.instance.client
          .from('products')
          .select('id, title, price, image_url, shop:shops(name)');

      if (widget.excludeIds.isNotEmpty) {
        query = query.not('id', 'in', widget.excludeIds);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$_searchQuery%');
      }
      final response = await query.limit(50);
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      appBar: AppBar(
        title: const Text('Sélectionner des produits', style: TextStyle(color: navy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: navy),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedIds);
              },
              child: Text(
                'Ajouter (${_selectedIds.length})',
                style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, color: textMuted),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: gold, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadProducts();
              },
            ),
          ),

          // Liste des produits
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: gold))
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun produit disponible',
                              style: TextStyle(color: textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isSelected = _selectedIds.contains(product['id']);
                          return CheckboxListTile(
                            activeColor: gold,
                            checkColor: Colors.white,
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true && _selectedIds.length < widget.maxSelect) {
                                  _selectedIds.add(product['id']);
                                } else if (selected == false) {
                                  _selectedIds.remove(product['id']);
                                }
                              });
                            },
                            title: Text(
                              product['title'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: navy),
                            ),
                            subtitle: Text(
                              product['shop']?['name'] ?? 'Boutique',
                              style: TextStyle(color: textMuted),
                            ),
                            secondary: Text(
                              '${(product['price'] as num).toInt()} FCFA',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: gold,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          );
                        },
                      ),
          ),

          // Message de limite
          if (_selectedIds.length >= widget.maxSelect)
            Container(
              padding: const EdgeInsets.all(12),
              color: gold.withOpacity(0.1),
              child: Center(
                child: Text(
                  'Maximum ${widget.maxSelect} produit(s) sélectionné(s)',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
