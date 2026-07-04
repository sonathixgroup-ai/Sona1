import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _currentUserId;
  Stream<List<Map<String, dynamic>>>? _cartStream;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  
  int get itemCount => _cartItems.length;
  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + (item['quantity'] ?? 0));
  
  double get subtotal => _cartItems.fold(0.0, (sum, item) {
    final price = (item['product']['price'] as num).toDouble();
    final quantity = (item['quantity'] ?? 0).toInt();
    return sum + (price * quantity);
  });
  
  double get shippingCost {
    // Calculer selon le poids ou valeur - simplifié ici
    return subtotal > 50000 ? 0 : 2500;
  }
  
  double get total => subtotal + shippingCost;

  CartProvider() {
    _init();
  }

  void _init() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      _setupRealtimeSubscription();
      loadCart();
    }
    
    // Écouter les changements d'authentification
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _currentUserId = session.user.id;
        _setupRealtimeSubscription();
        loadCart();
      } else {
        _currentUserId = null;
        _cartItems.clear();
        _cartStream = null;
        notifyListeners();
      }
    });
  }

  void _setupRealtimeSubscription() {
    if (_currentUserId == null) return;
    
    _cartStream = _supabase
        .from('cart')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
    
    _cartStream?.listen((updatedCart) async {
      // Recharger les détails des produits pour chaque article
      await _syncCartWithProducts(updatedCart);
    });
  }

  Future<void> _syncCartWithProducts(List<Map<String, dynamic>> cartRecords) async {
    if (cartRecords.isEmpty) {
      _cartItems = [];
      notifyListeners();
      return;
    }

    setState(() => _isSyncing = true);
    
    try {
      final List<Map<String, dynamic>> enrichedItems = [];
      for (var cartItem in cartRecords) {
        final productId = cartItem['product_id'];
        if (productId != null) {
          final productResponse = await _supabase
              .from('products')
              .select('*, shop:shops(name, logo_url)')
              .eq('id', productId)
              .maybeSingle();
          
          if (productResponse != null) {
            enrichedItems.add({
              ...cartItem,
              'product': productResponse,
            });
          } else {
            // Produit supprimé, retirer du panier
            await removeFromCart(cartItem['id']);
          }
        }
      }
      _cartItems = enrichedItems;
    } catch (e) {
      debugPrint('Error syncing cart: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> loadCart() async {
    if (_currentUserId == null) {
      _cartItems = [];
      notifyListeners();
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final response = await _supabase
          .from('cart')
          .select()
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false);
      
      await _syncCartWithProducts(List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Error loading cart: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> addToCart({
    required String productId,
    int quantity = 1,
    String? variant,
    String? color,
  }) async {
    if (_currentUserId == null) {
      throw Exception('Veuillez vous connecter');
    }
    
    try {
      // Vérifier si le produit existe déjà dans le panier
      final existingItem = _cartItems.firstWhere(
        (item) => item['product_id'] == productId && 
                 item['variant'] == variant && 
                 item['color'] == color,
        orElse: () => {},
      );
      
      if (existingItem.isNotEmpty) {
        // Mettre à jour la quantité
        final newQuantity = (existingItem['quantity'] ?? 0) + quantity;
        await updateQuantity(existingItem['id'], newQuantity);
      } else {
        // Ajouter nouvel article
        await _supabase.from('cart').insert({
          'user_id': _currentUserId,
          'product_id': productId,
          'quantity': quantity,
          'variant': variant,
          'color': color,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      
      await loadCart(); // Recharger pour mettre à jour l'UI
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }
    
    try {
      await _supabase
          .from('cart')
          .update({'quantity': newQuantity})
          .eq('id', cartItemId);
      
      // Mise à jour locale optimiste
      final index = _cartItems.indexWhere((item) => item['id'] == cartItemId);
      if (index != -1) {
        _cartItems[index]['quantity'] = newQuantity;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _supabase
          .from('cart')
          .delete()
          .eq('id', cartItemId);
      
      _cartItems.removeWhere((item) => item['id'] == cartItemId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    if (_currentUserId == null) return;
    
    try {
      await _supabase
          .from('cart')
          .delete()
          .eq('user_id', _currentUserId!);
      
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }
}
