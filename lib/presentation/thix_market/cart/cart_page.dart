import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; // suppose l'existence
import 'cart_provider.dart';
import 'cart_item_tile.dart';
import 'cart_summary_widget.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mon panier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              if (cart.itemCount > 0) {
                return TextButton(
                  onPressed: () => _showClearCartDialog(context),
                  child: const Text(
                    'Vider',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (cart.cartItems.isEmpty) {
            return _buildEmptyCart(context);
          }
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.cartItems.length,
                  itemBuilder: (context, index) {
                    return CartItemTile(
                      cartItem: cart.cartItems[index],
                      onQuantityChanged: (newQuantity) {
                        final itemId = cart.cartItems[index]['id'];
                        cart.updateQuantity(itemId, newQuantity);
                      },
                      onRemove: () {
                        final itemId = cart.cartItems[index]['id'];
                        cart.removeFromCart(itemId);
                      },
                    );
                  },
                ),
              ),
              CartSummaryWidget(
                subtotal: cart.subtotal,
                shippingCost: cart.shippingCost,
                total: cart.total,
                itemCount: cart.totalQuantity,
                onCheckout: () => _proceedToCheckout(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Votre panier est vide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits à votre panier pour continuer',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5592F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Découvrir les produits'),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le panier'),
        content: const Text('Êtes-vous sûr de vouloir supprimer tous les articles ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartProvider>().clearCart();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(BuildContext context) {
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn; // à adapter
    if (!isLoggedIn) {
      Navigator.pushNamed(context, '/login', arguments: {'redirect': '/checkout'});
    } else {
      Navigator.pushNamed(context, '/checkout');
    }
  }
}
