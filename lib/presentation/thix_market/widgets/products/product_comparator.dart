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
          .in_filter('id', _selectedProductIds);
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comparateur de produits'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_products.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Effacer tout'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // En-tête des produits
                    SizedBox(
                      height: 300,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colonne des attributs
                            Container(
                              width: 120,
                              padding: const EdgeInsets.all(12),
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
                                child: Column(
                                  children: [
                                    const SizedBox(height: 100),
                                    InkWell(
                                      onTap: _addProduct,
                                      child: Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 40),
                                            SizedBox(height: 8),
                                            Text('Ajouter un produit'),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _shareComparison(),
                                icon: const Icon(Icons.share),
                                label: const Text('Partager la comparaison'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE5592F),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
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
      margin: const EdgeInsets.only(right: 1),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image et suppression
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: product['image_url'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => _removeProduct(index),
                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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
                  product['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['shop']['name'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Prix
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${product['price'].toInt()} FCFA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE5592F),
              ),
            ),
          ),
          
          // Marque
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(product['brand'] ?? 'Non spécifiée'),
          ),
          
          // Note
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${product['rating']?.toStringAsFixed(1) ?? 0}'),
              ],
            ),
          ),
          
          // Stock
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              (product['stock'] ?? 0) > 0 ? '${product['stock']} unités' : 'Épuisé',
              style: TextStyle(
                color: (product['stock'] ?? 0) > 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
          
          // Livraison
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              product['free_shipping'] == true ? 'Gratuite' : 'Payante',
              style: TextStyle(
                color: product['free_shipping'] == true ? Colors.green : Colors.grey,
              ),
            ),
          ),
          
          // Garantie
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('${product['warranty_months'] ?? 0} mois'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez jusqu\'à $_maxCompareProducts produits',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addProduct,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _shareComparison() {
    // Logique de partage
  }
}

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
      appBar: AppBar(
        title: const Text('Sélectionner des produits'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedIds.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedIds);
              },
              child: Text('Ajouter (${_selectedIds.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadProducts();
              },
            ),
          ),
          
          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final isSelected = _selectedIds.contains(product['id']);
                      return CheckboxListTile(
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
                        title: Text(product['title']),
                        subtitle: Text(product['shop']['name']),
                        secondary: Text(
                          '${product['price'].toInt()} FCFA',
                          style: const TextStyle(color: Color(0xFFE5592F)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
