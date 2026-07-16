import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_summary_widget.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_item_tile.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  static const navy = Color(0xFF0A1931);
  static const bg = Color(0xFFF7F8FC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: navy),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.push('/market/buy');
            }
          },
        ),
        title: Consumer<CartProvider>(
          builder: (_, cart, __) => Text(
            'Mon panier (${cart.totalQuantity})',
            style: const TextStyle(fontWeight: FontWeight.w900, color: navy, fontSize: 18),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => cart.cartItems.isEmpty 
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Vider le panier ?', style: TextStyle(fontWeight: FontWeight.w800)),
                          content: const Text('Tous les articles seront supprimés.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81E2C)),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Vider', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) cart.clearCart();
                    },
                    child: const Text('Vider', style: TextStyle(color: Color(0xFFD81E2C), fontWeight: FontWeight.w700)),
                  ),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator(color: navy));
          }
          if (cart.cartItems.isEmpty) { 
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  itemCount: cart.cartItems.length, 
                  itemBuilder: (context, index) {
                    final cartItem = cart.cartItems[index]; 
                    final product = cartItem['product'] as Map<String, dynamic>? ?? {};
                    
                    final realPrice = cart.getItemRealPrice(cartItem);
                    final oldPrice = cart.getItemOldPrice(cartItem);
                    final discount = cart.getItemDiscountPercent(cartItem);
                    final cur = cart.currencyForItem(cartItem);
                    
                    final cartRowId = cartItem['id']; 

                    return CartItemTile(
                      cartItem: cartItem,
                      realPrice: realPrice,
                      oldPrice: oldPrice,
                      discountPercent: discount,
                      currency: cur,
                      onQuantityChanged: (newQty) {
                        if (newQty <= 0) {
                          cart.removeFromCart(cartRowId); 
                        } else {
                          final stock = (product['stock'] as num?)?.toInt() ?? 9999;
                          if (newQty > stock) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock limité à $stock')));
                            return;
                          }
                          cart.updateQuantity(cartRowId, newQty); 
                        }
                      },
                      onRemove: () => cart.removeFromCart(cartRowId), 
                    );
                  },
                ),
              ),
              CartSummaryWidget(
                subtotal: cart.subtotal,
                originalSubtotal: cart.originalSubtotal,
                discount: cart.totalDiscount,
                shippingCost: cart.shippingCost,
                total: cart.total,
                itemCount: cart.totalQuantity,
                currency: cart.currency == 'XOF' ? 'FC' : cart.currency,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: const Color(0xFFEFF5FF), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16)]),
              child: const Icon(Icons.shopping_cart_outlined, size: 56, color: Color(0xFF7386A8)),
            ),
            const SizedBox(height: 20),
            const Text('Votre panier est vide', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: navy)),
            const SizedBox(height: 8),
            const Text('Ajoutez des produits pour continuer', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ CORRECTION DU ROUTAGE : On retourne au produit s'il y en a un, sinon on push vers market/buy
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.push('/market/buy');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81E2C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  elevation: 0,
                ),
                child: const Text('Découvrir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
