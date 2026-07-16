// lib/presentation/thix_market/pages/product_comparator.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CHARTE GRAPHIQUE THIX MARKET
// ============================================================
class _MarketColors {
  static const Color red = Color(0xFFD81E2C);
  static const Color gold = Color(0xFFF0A93B);
  static const Color lightBg = Color(0xFFF7F7FA);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color mutedText = Color(0xFF8A8A8F);
  static const Color cardBorder = Color(0xFFF0F0F0);
  static const Color successGreen = Color(0xFF00B074);
  static const Color creamBg = Color(0xFFFCEFDA);
}

class ProductComparatorPage extends StatefulWidget {
  // ✅ CORRECTION DU CRASH : Rétablissement du paramètre initialProductIds attendu par le routeur
  final List<String>? initialProductIds;

  const ProductComparatorPage({super.key, this.initialProductIds});

  @override
  State<ProductComparatorPage> createState() => _ProductComparatorPageState();
}

class _ProductComparatorPageState extends State<ProductComparatorPage> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _productsToCompare = [];
  List<String> _productIdsToCompare = [];
  final int _maxCompareProducts = 4;

  @override
  void initState() {
    super.initState();
    // Chargement initial si des produits sont envoyés via la navigation
    if (widget.initialProductIds != null && widget.initialProductIds!.isNotEmpty) {
      _productIdsToCompare = widget.initialProductIds!.take(_maxCompareProducts).toList();
      _loadComparisonData();
    }
  }

  // ============================================================
  // LOGIQUE DE DONNÉES (100% SUPABASE)
  // ============================================================
  Future<void> _loadComparisonData() async {
    if (_productIdsToCompare.isEmpty) {
      setState(() {
        _productsToCompare = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, shop:shops(name)')
          .inFilter('id', _productIdsToCompare);

      setState(() {
        // On s'assure de garder l'ordre de sélection
        _productsToCompare = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur Supabase (Comparateur) : $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des produits'), backgroundColor: _MarketColors.red),
        );
      }
    }
  }

  void _removeProduct(String id) {
    setState(() {
      _productIdsToCompare.remove(id);
      _productsToCompare.removeWhere((p) => p['id'] == id);
    });
  }

  Future<void> _openProductSelector() async {
    // ✅ CORRECTION : Ouvre la page de sélection (qui avait été supprimée)
    final selectedIds = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelector(
          excludeIds: _productIdsToCompare,
          maxSelect: _maxCompareProducts - _productIdsToCompare.length,
        ),
      ),
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      setState(() {
        _productIdsToCompare.addAll(selectedIds);
      });
      _loadComparisonData();
    }
  }

  // ============================================================
  // INTERFACE UTILISATEUR
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        backgroundColor: _MarketColors.pureWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _MarketColors.darkText),
        title: const Text(
          'Comparateur B2B',
          style: TextStyle(color: _MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          if (_productsToCompare.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: _MarketColors.red),
              onPressed: () {
                setState(() {
                  _productIdsToCompare.clear();
                  _productsToCompare.clear();
                });
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _MarketColors.cardBorder, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _MarketColors.red));
    }

    if (_productsToCompare.isEmpty) {
      return _buildEmptyState();
    }

    return _buildComparisonTable();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: _MarketColors.creamBg, shape: BoxShape.circle),
              child: const Icon(Icons.compare_arrows_rounded, size: 64, color: _MarketColors.gold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Comparateur vide',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _MarketColors.darkText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez jusqu\'à 4 produits sur le marché pour comparer leurs caractéristiques en détail.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _MarketColors.mutedText, height: 1.4),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openProductSelector,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Ajouter des produits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _MarketColors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final features = [
      {'label': 'Prix', 'key': 'price'},
      {'label': 'Marque', 'key': 'brand'},
      {'label': 'Stock', 'key': 'stock'},
      {'label': 'Garantie', 'key': 'warranty'},
      {'label': 'Boutique', 'key': 'shop_name'},
    ];

    // Utilisation d'un SingleChildScrollView horizontal pour éviter les débordements (Overflow)
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LIGNE DES EN-TÊTES (IMAGES ET TITRES)
            Container(
              color: _MarketColors.pureWhite,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 100), // Espace vide pour la colonne des labels
                  ..._productsToCompare.map((product) => _buildProductHeader(product)),
                  if (_productsToCompare.length < _maxCompareProducts) _buildAddProductButton(),
                ],
              ),
            ),
            Container(height: 1, width: MediaQuery.of(context).size.width * 2, color: _MarketColors.cardBorder),
            
            // LIGNES DES CARACTÉRISTIQUES
            ...features.map((feature) => _buildFeatureRow(feature)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    return Container(
      width: 140, // Largeur fixe pour chaque colonne produit
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  color: _MarketColors.lightBg,
                  child: CachedNetworkImage(
                    imageUrl: product['image_url'] ?? '',
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _MarketColors.red)),
                    errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _removeProduct(product['id']),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: const Icon(Icons.close_rounded, size: 14, color: _MarketColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product['title'] ?? 'Produit',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _MarketColors.darkText, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildAddProductButton() {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          InkWell(
            onTap: _openProductSelector,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: _MarketColors.lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _MarketColors.cardBorder, style: BorderStyle.solid),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: _MarketColors.mutedText, size: 32),
                  SizedBox(height: 8),
                  Text('Ajouter', style: TextStyle(color: _MarketColors.mutedText, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(Map<String, String> feature) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _MarketColors.cardBorder))),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Colonne Label
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                feature['label']!, 
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _MarketColors.mutedText)
              ),
            ),
          ),
          // Colonnes Valeurs
          ..._productsToCompare.map((product) {
            final key = feature['key']!;
            String displayValue = '';

            if (key == 'price') {
              displayValue = '${(product['price'] as num?)?.toInt() ?? 0} ${product['currency'] ?? 'FC'}';
            } else if (key == 'shop_name') {
              displayValue = product['shop']?['name'] ?? '-';
            } else if (key == 'stock') {
              final stock = int.tryParse(product['stock'].toString()) ?? 0;
              displayValue = stock > 0 ? '$stock dispo' : 'Épuisé';
            } else {
              displayValue = product[key]?.toString() ?? '-';
            }

            final isPrice = key == 'price';
            final isOutOfStock = key == 'stock' && displayValue == 'Épuisé';

            return SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  displayValue,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isPrice ? FontWeight.w900 : FontWeight.w600,
                    color: isPrice ? _MarketColors.red : (isOutOfStock ? _MarketColors.red : _MarketColors.darkText),
                  ),
                ),
              ),
            );
          }),
          // Espace vide si on a moins de 4 produits pour s'aligner avec le bouton "Ajouter"
          if (_productsToCompare.length < _maxCompareProducts)
            const SizedBox(width: 140),
        ],
      ),
    );
  }
}

// ============================================================
// ProductSelector (Sélecteur de produits remis à neuf)
// ============================================================
class ProductSelector extends StatefulWidget {
  final List<String> excludeIds;
  final int maxSelect;

  const ProductSelector({super.key, required this.excludeIds, required this.maxSelect});

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  List<Map<String, dynamic>> _products = [];
  final List<String> _selectedIds = [];
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
          .select('id, title, price, currency, image_url, shop:shops(name)');

      if (widget.excludeIds.isNotEmpty) {
        query = query.not('id', 'in', widget.excludeIds);
      }
      if (_searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$_searchQuery%');
      }
      
      final response = await query.limit(30);
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
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        title: const Text('Ajouter au comparateur', style: TextStyle(color: _MarketColors.darkText, fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: _MarketColors.pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: _MarketColors.darkText),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context, _selectedIds),
                style: TextButton.styleFrom(backgroundColor: _MarketColors.red.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text('Ajouter (${_selectedIds.length})', style: const TextStyle(color: _MarketColors.red, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _MarketColors.pureWhite,
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                hintStyle: const TextStyle(color: _MarketColors.mutedText, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: _MarketColors.mutedText),
                filled: true,
                fillColor: _MarketColors.lightBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadProducts();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _MarketColors.red))
                : _products.isEmpty
                    ? const Center(child: Text('Aucun produit trouvé', style: TextStyle(color: _MarketColors.mutedText)))
                    : ListView.separated(
                        itemCount: _products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: _MarketColors.cardBorder),
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          final isSelected = _selectedIds.contains(product['id']);

                          return ListTile(
                            tileColor: _MarketColors.pureWhite,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product['image_url'] ?? '',
                                width: 50, height: 50, fit: BoxFit.cover,
                                errorWidget: (_,__,___) => Container(color: _MarketColors.lightBg, width: 50, height: 50, child: const Icon(Icons.image_outlined, color: _MarketColors.mutedText)),
                              ),
                            ),
                            title: Text(product['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _MarketColors.darkText)),
                            subtitle: Text('${(product['price'] as num?)?.toInt() ?? 0} ${product['currency'] ?? 'FC'}', style: const TextStyle(color: _MarketColors.red, fontWeight: FontWeight.w800, fontSize: 13)),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: _MarketColors.red,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (selected) {
                                setState(() {
                                  if (selected == true && _selectedIds.length < widget.maxSelect) {
                                    _selectedIds.add(product['id']);
                                  } else if (selected == false) {
                                    _selectedIds.remove(product['id']);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vous ne pouvez ajouter que ${widget.maxSelect} produit(s) supplémentaires.'), backgroundColor: _MarketColors.gold));
                                  }
                                });
                              },
                            ),
                            onTap: () {
                               // Simule le clic sur la checkbox
                               final current = _selectedIds.contains(product['id']);
                               if (!current && _selectedIds.length < widget.maxSelect) {
                                 setState(() => _selectedIds.add(product['id']));
                               } else if (current) {
                                 setState(() => _selectedIds.remove(product['id']));
                               }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
