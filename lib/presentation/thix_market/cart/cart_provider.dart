// lib/presentation/thix_market/cart/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _currentUserId;
  Stream<List<Map<String, dynamic>>>? _cartStream;

  // ============================================================
  // GETTERS
  // ============================================================
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get itemCount => _cartItems.length;
  int get totalQuantity => _cartItems.fold<int>(
    0,
    (sum, item) => sum + ((item['quantity'] as int?) ?? 0),
  );

  /// Sous-total (devise du produit, peut être USD ou CDF)
  double get subtotal => _cartItems.fold(0.0, (sum, item) {
        final price = (item['product']?['price'] as num?)?.toDouble() ?? 0;
        final quantity = (item['quantity'] ?? 0).toInt();
        return sum + (price * quantity);
      });

  // ============================================================
  // GESTION DE LA DEVISES
  // ============================================================
  /// Devise dominante du panier (premier article)
  String get currency {
    if (_cartItems.isEmpty) return 'CDF';
    final product = _cartItems.first['product'] as Map?;
    return product?['currency'] ?? 'CDF';
  }

  /// Symbole de la devise ( $ ou FC )
  String get currencySymbol => currency == 'USD' ? '\$' : 'FC';

  // ============================================================
  // FRAIS DE LIVRAISON (toujours en CDF/FC)
  // ============================================================
  static const double _shippingCostFC = 2500;
  static const double _freeShippingThresholdFC = 50000;

  /// Convertit le sous-total en FC pour le calcul du seuil
  double get _subtotalInFC {
    if (currency == 'CDF') return subtotal;
    // Conversion approximative 1 USD = 2500 FC
    return subtotal * 2500;
  }

  double get shippingCost {
    return _subtotalInFC > _freeShippingThresholdFC ? 0 : _shippingCostFC;
  }

  /// Symbole de la livraison (toujours FC)
  String get shippingSymbol => 'FC';

  /// Total = sous-total + frais de livraison (affiché dans la devise du produit)
  double get total => subtotal + shippingCost;

  // ============================================================
  // INITIALISATION
  // ============================================================
  CartProvider() {
    _init();
  }

  void _init() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != null) {
      _setupRealtimeSubscription();
      loadCart();
    }

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

  // ============================================================
  // REAL-TIME SUBSCRIPTION
  // ============================================================
  void _setupRealtimeSubscription() {
    if (_currentUserId == null) return;

    _cartStream = _supabase
        .from('cart')
        .stream(primaryKey: ['id'])
        .eq('user_id', _currentUserId!)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));

    _cartStream?.listen((updatedCart) async {
      await _syncCartWithProducts(updatedCart);
    });
  }

  // ============================================================
  // SYNC CART WITH PRODUCTS
  // ============================================================
  Future<void> _syncCartWithProducts(List<Map<String, dynamic>> cartRecords) async {
    if (cartRecords.isEmpty) {
      _cartItems = [];
      notifyListeners();
      return;
    }

    _isSyncing = true;
    notifyListeners();

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
            await removeFromCart(cartItem['id']);
          }
        }
      }
      _cartItems = enrichedItems;
    } catch (e) {
      debugPrint('Error syncing cart: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHARGEMENT DU PANIER
  // ============================================================
  Future<void> loadCart() async {
    if (_currentUserId == null) {
      _cartItems = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

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
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // AJOUTER AU PANIER
  // ============================================================
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
      final existingItem = _cartItems.firstWhere(
        (item) =>
            item['product_id'] == productId &&
            item['variant'] == variant &&
            item['color'] == color,
        orElse: () => {},
      );

      if (existingItem.isNotEmpty) {
        final newQuantity = (existingItem['quantity'] ?? 0) + quantity;
        await updateQuantity(existingItem['id'], newQuantity);
      } else {
        await _supabase.from('cart').insert({
          'user_id': _currentUserId,
          'product_id': productId,
          'quantity': quantity,
          'variant': variant,
          'color': color,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await loadCart();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  // ============================================================
  // METTRE À JOUR LA QUANTITÉ
  // ============================================================
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

  // ============================================================
  // SUPPRIMER DU PANIER
  // ============================================================
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

  // ============================================================
  // VIDER LE PANIER
  // ============================================================
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
}
