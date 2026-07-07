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

  // ─── Palette Élite ──────────────────────────────────────────────
  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);
  static const Color danger = Color(0xFFFF5B3D);

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
      final currency = product['currency'] ?? 'CDF';
      final symbol = currency == 'USD' ? '\$' : 'FC';
      buffer.writeln('📦 ${product['title']}');
      buffer.writeln('   Prix : ${(product['price'] as num).toInt()} $symbol');
      buffer.writeln('   Marque : ${product['brand'] ?? 'Non spécifiée'}');
      buffer.writeln('   Note : ${product['rating']?.toStringAsFixed(1) ?? '0'} ⭐');
      buffer.writeln('   Stock : ${product['stock'] ?? 0} unités');
      buffer.writeln('   Livraison : ${product['free_shipping'] == true ? 'Gratuite' : 'Payante'}');
      buffer.writeln('   Garantie : ${product['warranty_months'] ?? 0} mois');
      buffer.writeln('');
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Partager la comparaison', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: SelectableText(buffer.toString(), style: const TextStyle(fontSize: 14, color: darkText)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Partage copié dans le presse-papiers')),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: pureWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Comparateur de produits', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        backgroundColor: pureWhite,
        elevation: 0,
        actions: [
          if (_products.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.delete_outline_rounded, color: danger),
              label: const Text('Effacer tout', style: TextStyle(color: danger)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
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
                              color: pureWhite,
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
                                color: pureWhite,
                                child: Column(
                                  children: [
                                    const SizedBox(height: 100),
                                    InkWell(
                                      onTap: _addProduct,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: softBlue,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_rounded, size: 40, color: mutedText),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Ajouter un produit',
                                              style: TextStyle(color: mutedText, fontWeight: FontWeight.w500),
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
                        color: pureWhite,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareComparison,
                                icon: const Icon(Icons.share_rounded),
                                label: const Text('Partager la comparaison'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: pureWhite,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
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
    final currency = product['currency'] ?? 'CDF';
    final symbol = currency == 'USD' ? '\$' : 'FC';

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: pureWhite,
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
                  color: softBlue,
                  child: const Icon(Icons.image_rounded, color: mutedText),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => _removeProduct(index),
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(28, 28),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, color: darkText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['shop']?['name'] ?? 'Boutique',
                  style: TextStyle(fontSize: 12, color: mutedText),
                ),
              ],
            ),
          ),

          // Prix
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${(product['price'] as num).toInt()} $symbol',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),

          // Marque
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              product['brand'] ?? 'Non spécifiée',
              style: const TextStyle(color: darkText),
            ),
          ),

          // Note
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 14, color: gold),
                const SizedBox(width: 4),
                Text(
                  '${product['rating']?.toStringAsFixed(1) ?? 0}',
                  style: const TextStyle(color: darkText),
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
                color: product['free_shipping'] == true ? Colors.green : mutedText,
              ),
            ),
          ),

          // Garantie
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${product['warranty_months'] ?? 0} mois',
              style: const TextStyle(color: darkText),
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
        fontWeight: FontWeight.w700,
        color: darkText,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: softBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.compare_arrows_rounded, size: 64, color: mutedText),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun produit à comparer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez jusqu\'à $_maxCompareProducts produits',
            style: TextStyle(color: mutedText),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addProduct,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter un produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: pureWhite,
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

  static const Color navyDeep = Color(0xFF0A1F44);
  static const Color navy = Color(0xFF123B7A);
  static const Color primaryBlue = Color(0xFF2D6CDF);
  static const Color softBlue = Color(0xFFEFF5FF);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF10192E);
  static const Color mutedText = Color(0xFF7386A8);
  static const Color gold = Color(0xFFE3B23C);

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
          .select('id, title, price, currency, image_url, shop:shops(name)');

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
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text('Sélectionner des produits', style: TextStyle(color: darkText, fontWeight: FontWeight.bold)),
        backgroundColor: pureWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: darkText),
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
                style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
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
                hintStyle: TextStyle(color: mutedText),
                prefixIcon: const Icon(Icons.search_rounded, color: mutedText),
                filled: true,
                fillColor: pureWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: primaryBlue, width: 2),
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
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun produit disponible',
                              style: TextStyle(color: mutedText),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isSelected = _selectedIds.contains(product['id']);
                          final currency = product['currency'] ?? 'CDF';
                          final symbol = currency == 'USD' ? '\$' : 'FC';

                          return CheckboxListTile(
                            activeColor: primaryBlue,
                            checkColor: pureWhite,
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
                              style: const TextStyle(fontWeight: FontWeight.w600, color: darkText),
                            ),
                            subtitle: Text(
                              product['shop']?['name'] ?? 'Boutique',
                              style: TextStyle(color: mutedText),
                            ),
                            secondary: Text(
                              '${(product['price'] as num).toInt()} $symbol',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          );
                        },
                      ),
          ),

          // Message de limite
          if (_selectedIds.length >= widget.maxSelect)
            Container(
              padding: const EdgeInsets.all(12),
              color: softBlue,
              child: Center(
                child: Text(
                  'Maximum ${widget.maxSelect} produit(s) sélectionné(s)',
                  style: TextStyle(color: darkText, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
