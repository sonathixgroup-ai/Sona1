// lib/presentation/thix_market/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('*, shop:shops(name, logo_url)')
          .eq('id', widget.productId)
          .single();
      setState(() {
        _product = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Produit introuvable';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du produit'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _product == null
                  ? const Center(child: Text('Aucune information'))
                  : _buildProductContent(),
    );
  }

  Widget _buildProductContent() {
    final product = _product!;
    final hasDiscount = product['discount_price'] != null &&
        product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();
    final originalPrice = product['price'].toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: product['image_url'] ?? '',
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),

          // Titre
          Text(
            product['title'] ?? 'Sans titre',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Boutique
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: product['shop']?['logo_url'] != null
                    ? CachedNetworkImageProvider(product['shop']['logo_url'])
                    : null,
                child: product['shop']?['logo_url'] == null
                    ? const Icon(Icons.store, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                product['shop']?['name'] ?? 'Boutique',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Prix
          Row(
            children: [
              Text(
                '${price.toInt()} FCFA',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF146EB4),
                ),
              ),
              if (hasDiscount)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${originalPrice.toInt()} FCFA',
                    style: TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          if (product['description'] != null) ...[
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              product['description'],
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
          ],

          // Informations supplémentaires
          _buildInfoRow('Catégorie', product['category'] ?? 'Non spécifié'),
          _buildInfoRow('État', product['condition'] ?? 'Non spécifié'),
          _buildInfoRow('Stock', '${product['stock'] ?? 0} unités'),
          if (product['brand'] != null)
            _buildInfoRow('Marque', product['brand']),

          const SizedBox(height: 24),

          // Bouton Ajouter au panier
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Ajouter au panier (à implémenter)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ajouté au panier (simulé)')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9900),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Ajouter au panier',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
