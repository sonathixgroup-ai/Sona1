// lib/presentation/thix_market/cart/cart_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/presentation/thix_market/cart/cart_provider.dart';
import 'cart_item_tile.dart';
import 'cart_summary_widget.dart';

class _MarketColors {
  static const redDark = Color(0xFF5C0E12);
  static const red = Color(0xFFD81E2C);
  static const gold = Color(0xFFF0A93B);
  static const creamBg = Color(0xFFFCEFDA);
  static const lightBg = Color(0xFFF7FAFF);
  static const darkText = Color(0xFF10192E);
  static const mutedText = Color(0xFF7386A8);
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MarketColors.lightBg,
      appBar: AppBar(
        title: const Text('Mon panier', style: TextStyle(fontWeight: FontWeight.w900, color: _MarketColors.darkText)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: _MarketColors.darkText), onPressed: ()=> context.pop()),
        actions: [
          Consumer<CartProvider>(builder: (_, cart, __) => cart.itemCount>0
           ? TextButton(onPressed: ()=> _showClearDialog(context), child: const Text('Vider', style: TextStyle(color: Color(0xFFFF5B3D), fontWeight: FontWeight.w700)))
            : const SizedBox()),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, _) {
          if (cart.isLoading) return const Center(child: CircularProgressIndicator(color: _MarketColors.red));
          if (cart.cartItems.isEmpty) return _empty(context);
          return Column(children:[
            Expanded(child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: cart.cartItems.length, itemBuilder: (c,i){
              final item = cart.cartItems[i];
              return CartItemTile(
                cartItem: item,
                realPrice: cart.getItemRealPrice(item),
                oldPrice: cart.getItemOldPrice(item),
                discountPercent: cart.getItemDiscountPercent(item),
                currency: cart.currencyForItem(item),
                onQuantityChanged: (q)=> cart.updateQuantity(item['id'], q),
                onRemove: ()=> cart.removeFromCart(item['id']),
              );
            })),
            CartSummaryWidget(
              subtotal: cart.subtotal,
              originalSubtotal: cart.originalSubtotal,
              discount: cart.totalDiscount,
              shippingCost: cart.shippingCost,
              total: cart.total,
              itemCount: cart.totalQuantity,
              currency: cart.currency,
            ),
          ]);
        },
      ),
    );
  }

  Widget _empty(BuildContext context)=> Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children:[
    Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFEFF5FF), shape: BoxShape.circle), child: const Icon(Icons.shopping_cart_outlined, size: 72, color: _MarketColors.mutedText)),
    const SizedBox(height:16), const Text('Votre panier est vide', style: TextStyle(fontSize:18, fontWeight: FontWeight.w900, color: _MarketColors.darkText)),
    const SizedBox(height:8), const Text('Ajoutez des produits pour continuer', style: TextStyle(color: _MarketColors.mutedText)),
    const SizedBox(height:24),
    ElevatedButton(onPressed: ()=> context.go('/market'), style: ElevatedButton.styleFrom(backgroundColor: _MarketColors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(horizontal:32,vertical:14)), child: const Text('Découvrir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
  ]));

  void _showClearDialog(BuildContext context)=> showDialog(context: context, builder: (_)=> AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), title: const Text('Vider le panier'), content: const Text('Supprimer tous les articles?'), actions:[
    TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Annuler')), TextButton(onPressed: (){ Navigator.pop(context); context.read<CartProvider>().clearCart(); }, child: const Text('Vider', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
  ]));
}
