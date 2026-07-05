// lib/presentation/thix_market/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Map<String, dynamic>? _product;
  bool _isLoading = true;
  bool _isFavorite = false;
  int _quantity = 1;
  String? _selectedVariant;
  String? _selectedColor;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _checkFavorite();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select('''
            *,
            shop:shops(name, logo_url, rating)
          ''')
          .eq('id', widget.productId)
          .single();
      setState(() {
        _product = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit introuvable')),
        );
      }
    }
  }

  Future<void> _checkFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('wishlist')
          .select()
          .match({
            'user_id': userId,
            'product_id': widget.productId,
          })
          .maybeSingle();
      setState(() => _isFavorite = response != null);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }
    try {
      if (_isFavorite) {
        await Supabase.instance.client
            .from('wishlist')
            .delete()
            .match({
              'user_id': userId,
              'product_id': widget.productId,
            });
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Retiré des favoris'), duration: Duration(seconds: 1)),
        );
      } else {
        await Supabase.instance.client
            .from('wishlist')
            .insert({
              'user_id': userId,
              'product_id': widget.productId,
              'created_at': DateTime.now().toIso8601String(),
            });
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajouté aux favoris'), duration: Duration(seconds: 1)),
        );
      }
    } catch (_) {}
  }

  Future<void> _addToCart() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez vous connecter')),
      );
      return;
    }
    setState(() => _isAddingToCart = true);
    try {
      // Vérifier si le produit est déjà dans le panier
      final existing = await Supabase.instance.client
          .from('cart')
          .select()
          .match({
            'user_id': userId,
            'product_id': widget.productId,
          })
          .maybeSingle();

      if (existing != null) {
        await Supabase.instance.client
            .from('cart')
            .update({
              'quantity': (existing['quantity'] as int) + _quantity,
            })
            .eq('id', existing['id']);
      } else {
        await Supabase.instance.client
            .from('cart')
            .insert({
              'user_id': userId,
              'product_id': widget.productId,
              'quantity': _quantity,
              'variant': _selectedVariant,
              'color': _selectedColor,
              'created_at': DateTime.now().toIso8601String(),
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajouté au panier'), duration: Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _buyNow() async {
    await _addToCart();
    if (mounted) {
      context.push('/market/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Produit introuvable'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final product = _product!;
    final hasDiscount = product['discount_price'] != null &&
        product['discount_price'] < product['price'];
    final price = (hasDiscount ? product['discount_price'] : product['price']).toDouble();
    final originalPrice = product['price'].toDouble();
    final images = product['images'] as List? ?? [product['image_url']];

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carousel d'images
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: images[index] ?? '',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      GestureDetector(
                        onTap: () => context.push('/market/shop/${product['shop_id']}'),
                        child: Row(
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Prix
                      Row(
                        children: [
                          Text(
                            '${price.toInt()} FCFA',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A73E8),
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
                      const SizedBox(height: 8),

                      // Stock
                      if ((product['stock'] ?? 0) > 0)
                        Text(
                          'Stock disponible: ${product['stock']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: (product['stock'] ?? 0) < 10 ? Colors.orange : Colors.green,
                          ),
                        )
                      else
                        const Text(
                          'Épuisé',
                          style: TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      const SizedBox(height: 16),

                      // Variantes
                      if (product['variants'] != null && (product['variants'] as List).isNotEmpty)
                        _buildVariants(product['variants']),
                      if (product['colors'] != null && (product['colors'] as List).isNotEmpty)
                        _buildColors(product['colors']),

                      // Quantité
                      _buildQuantitySelector(),
                      const SizedBox(height: 16),

                      // Description
                      if (product['description'] != null) ...[
                        const Text(
                          'Description',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['description'],
                          style: const TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Infos supplémentaires
                      _buildInfoRow('Catégorie', product['category'] ?? 'Non spécifié'),
                      _buildInfoRow('État', product['condition'] ?? 'Non spécifié'),
                      if (product['brand'] != null)
                        _buildInfoRow('Marque', product['brand']),
                      _buildInfoRow('Livraison', product['free_shipping'] == true ? 'Gratuite' : 'Payante'),
                      if (product['shipping_type'] != null)
                        _buildInfoRow('Type de livraison', product['shipping_type']),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Bar (Ajouter au panier + Acheter)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (product['stock'] ?? 0) > 0 && !_isAddingToCart
                      ? _addToCart
                      : null,
                  icon: _isAddingToCart
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_cart),
                  label: const Text('Ajouter au panier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A73E8),
                    side: const BorderSide(color: Color(0xFF1A73E8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (product['stock'] ?? 0) > 0 && !_isAddingToCart
                      ? _buyNow
                      : null,
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Acheter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A73E8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }

  Widget _buildVariants(List variants) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variantes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            final name = variant['name'] ?? variant.toString();
            final isSelected = _selectedVariant == name;
            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedVariant = selected ? name : null;
                });
              },
              selectedColor: const Color(0xFF1A73E8).withOpacity(0.1),
              checkmarkColor: const Color(0xFF1A73E8),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildColors(List colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Couleurs',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final name = color['name'] ?? color.toString();
            final isSelected = _selectedColor == name;
            return FilterChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedColor = selected ? name : null;
                });
              },
              selectedColor: const Color(0xFF1A73E8).withOpacity(0.1),
              checkmarkColor: const Color(0xFF1A73E8),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      children: [
        const Text(
          'Quantité',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_quantity > 1) setState(() => _quantity--);
                },
                icon: const Icon(Icons.remove, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () {
                  final stock = _product?['stock'] ?? 0;
                  if (_quantity < stock) setState(() => _quantity++);
                },
                icon: const Icon(Icons.add, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32),
              ),
            ],
          ),
        ),
      ],
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
