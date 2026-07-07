// lib/presentation/thix_market/cart/cart_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'cart_item_tile.dart';
import 'cart_summary_widget.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFF),
      appBar: AppBar(
        title: const Text(
          'Mon panier',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10192E)),
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
                    style: TextStyle(color: Color(0xFFFF5B3D), fontWeight: FontWeight.w700),
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6CDF)));
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              shape: BoxShape.circle,
            ),
            // ✅ Correction : Icons.shopping_cart_outlined_rounded → Icons.shopping_cart_outlined
            child: Icon(Icons.shopping_cart_outlined, size: 80, color: const Color(0xFF7386A8)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Votre panier est vide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF10192E)),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits à votre panier pour continuer',
            style: TextStyle(color: Color(0xFF7386A8), fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/market/buy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D6CDF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Découvrir les produits', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vider le panier', style: TextStyle(color: Color(0xFF10192E))),
        content: const Text('Êtes-vous sûr de vouloir supprimer tous les articles ?', style: TextStyle(color: Color(0xFF7386A8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Color(0xFF7386A8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CartProvider>().clearCart();
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF5B3D)),
            child: const Text('Vider', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout(BuildContext context) {
    final isLoggedIn = context.read<AuthController>().isAuthenticated;
    if (!isLoggedIn) {
      context.go('/login');
    } else {
      context.push('/market/checkout');
    }
  }
}
