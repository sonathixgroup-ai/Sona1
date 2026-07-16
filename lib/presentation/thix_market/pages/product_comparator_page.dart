import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  const ProductComparatorPage({super.key});

  @override
  State<ProductComparatorPage> createState() => _ProductComparatorPageState();
}

class _ProductComparatorPageState extends State<ProductComparatorPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _productsToCompare = [];

  @override
  void initState() {
    super.initState();
    _loadComparisonData();
  }

   // ============================================================
  // LOGIQUE DE DONNÉES (100% SUPABASE)
  // ============================================================
  
  // Dans le futur, tu pourras passer cette liste d'IDs depuis un Provider
  // Exemple: final idsToCompare = context.read<ComparatorProvider>().productIds;
  final List<String> _productIdsToCompare = []; // Laisse vide si aucun produit n'est sélectionné
  
  Future<void> _loadComparisonData() async {
    setState(() => _isLoading = true);
    
    if (_productIdsToCompare.isEmpty) {
      setState(() {
        _productsToCompare = [];
        _isLoading = false;
      });
      return;
    }

    try {
      // Requête Supabase : on récupère uniquement les produits dont l'ID est dans notre liste
      final response = await Supabase.instance.client
          .from('products')
          .select('*, shop:shops(name)')
          .inFilter('id', _productIdsToCompare); // "inFilter" cherche plusieurs IDs d'un coup

      setState(() {
        _productsToCompare = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur Supabase (Comparateur) : $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du chargement des produits'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _removeProduct(String id) {
    setState(() {
      _productIdsToCompare.remove(id); // On retire l'ID de notre liste locale
      _productsToCompare.removeWhere((p) => p['id'] == id);
    });
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
          style: TextStyle(
            color: _MarketColors.darkText,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
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
      return const Center(
        child: CircularProgressIndicator(color: _MarketColors.red),
      );
    }

    if (_productsToCompare.isEmpty || _productsToCompare.length < 2) {
      return _buildEmptyState();
    }

    return _buildComparisonTable();
  }

  // ============================================================
  // ÉTAT VIDE (Moins de 2 produits)
  // ============================================================
  Widget _buildEmptyState() {
    final hasOneProduct = _productsToCompare.length == 1;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _MarketColors.creamBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.compare_arrows_rounded,
                size: 64,
                color: _MarketColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasOneProduct ? 'Ajoutez un autre produit' : 'Comparateur vide',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: _MarketColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasOneProduct 
                  ? 'Il vous faut au moins 2 produits pour lancer une comparaison.' 
                  : 'Sélectionnez des produits sur le marché et cliquez sur l\'icône de comparaison pour les analyser ici.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _MarketColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/market/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _MarketColors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Explorer le marché',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLEAU DE COMPARAISON
  // ============================================================
  Widget _buildComparisonTable() {
    // Les caractéristiques que l'on veut comparer
    final features = [
      {'label': 'Prix', 'key': 'price'},
      {'label': 'Marque', 'key': 'brand'},
      {'label': 'Évaluation', 'key': 'rating'},
      {'label': 'État', 'key': 'condition'},
      {'label': 'Livraison', 'key': 'delivery'},
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête : Images et Titres
          Container(
            color: _MarketColors.pureWhite,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                // Colonne vide pour l'espacement des labels
                const SizedBox(width: 80),
                // Les produits
                ..._productsToCompare.map((product) => Expanded(
                      child: _buildProductHeader(product),
                    )),
              ],
            ),
          ),
          
          const Divider(height: 1, color: _MarketColors.cardBorder),

          // Lignes de caractéristiques
          ...features.map((feature) => _buildFeatureRow(feature)),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> product) {
    return Padding(
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
                  height: 100,
                  color: _MarketColors.lightBg,
                  child: CachedNetworkImage(
                    imageUrl: product['image_url'],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: _MarketColors.mutedText),
                  ),
                ),
              ),
              // Bouton supprimer
              GestureDetector(
                onTap: () => _removeProduct(product['id']),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: _MarketColors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product['title'],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: _MarketColors.darkText,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Bouton Ajouter au panier
          ElevatedButton(
            onPressed: () {
              // TODO: Logique d'ajout au panier
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajouté au panier !')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _MarketColors.red,
              minimumSize: const Size(double.infinity, 32),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(Map<String, String> feature) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _MarketColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          // Colonne Label
          SizedBox(
            width: 80,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                feature['label']!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _MarketColors.mutedText,
                ),
              ),
            ),
          ),
          // Valeurs pour chaque produit
          ..._productsToCompare.map((product) {
            final key = feature['key']!;
            String displayValue = '';

            // Formatage spécial selon le type de donnée
            if (key == 'price') {
              displayValue = '${product[key]} ${product['currency']}';
            } else if (key == 'rating') {
              displayValue = '⭐ ${product[key]}';
            } else {
              displayValue = product[key].toString();
            }

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  displayValue,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: key == 'price' ? FontWeight.w900 : FontWeight.w600,
                    color: key == 'price' ? _MarketColors.red : _MarketColors.darkText,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
