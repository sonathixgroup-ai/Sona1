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
  // GETTERS DE BASE
  // ============================================================
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  int get itemCount => _cartItems.length;
  int get totalQuantity => _cartItems.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?)?? 0));

  // ============================================================
  // LOGIQUE PRIX UNIQUE - CORRIGE LE DEPHASAGE
  // ============================================================
  double _getRealPrice(Map<String, dynamic> product) {
    final raw = (product['price'] as num?)?.toDouble()?? 0;
    final sale = (product['sale_price'] as num?)?.toDouble()?? (product['discount_price'] as num?)?.toDouble();
    final percent = (product['discount_percent'] as num?)?.toDouble()?? 0;
    final original = (product['original_price'] as num?)?.toDouble()?? raw;

    if (sale!= null && sale > 0 && sale < raw) return sale;
    if (sale!= null && sale > 0 && original > 0 && sale < original) return sale;
    if (percent > 0) return raw * (1 - percent / 100);
    return raw;
  }

  double _getOldPrice(Map<String, dynamic> product) {
    final raw = (product['price'] as num?)?.toDouble()?? 0;
    final original = (product['original_price'] as num?)?.toDouble()?? raw;
    final sale = (product['sale_price'] as num?)?.toDouble();
    if (sale!= null && sale < raw) return raw;
    return original;
  }

  // ============================================================
  // DEVISE = CELLE DU PRODUIT - PAS DE CONVERSION FORCÉE
  // ============================================================
  String get currency {
    if (_cartItems.isEmpty) return 'FC';
    final p = _cartItems.first['product'] as Map?;
    // Nettoie : CDF -> FC, XOF -> FC, USD reste USD
    final raw = (p?['currency']?? 'FC').toString().toUpperCase();
    if (raw == 'CDF' || raw == 'XOF' || raw == 'FC') return 'FC';
    if (raw == 'USD' || raw == '\$') return 'USD';
    return 'FC'; // par défaut franc congolais
  }

  String get currencySymbol => currency == 'USD'? '\$' : 'FC';

  // Pour chaque item, sa devise réelle (si panier mixte USD + FC)
  String currencyForItem(Map<String, dynamic> item) {
    final p = item['product'] as Map?;
    final raw = (p?['currency']?? currency).toString().toUpperCase();
    if (raw == 'USD' || raw == '\$') return 'USD';
    return 'FC';
  }

  // ============================================================
  // CALCULS - CORRIGÉS
  // ============================================================
  // CORRECTION : Remplace les ??? par ??
double get subtotal => _cartItems.fold(0.0, (sum, item) {
    // Si item['product'] est null, on utilise un Map vide {}
    final product = Map<String, dynamic>.from(item['product'] as Map? ?? {});
    final qty = (item['quantity'] ?? 0).toInt();
    return sum + (_getRealPrice(product) * qty);
});


  double get originalSubtotal => _cartItems.fold(0.0, (sum, item) {
    final product = Map<String, dynamic>.from(item['product'] as Map??? {});
    final qty = (item['quantity']?? 0).toInt();
    return sum + (_getOldPrice(product) * qty);
  });

  double get totalDiscount => originalSubtotal - subtotal;

  // LIVRAISON = 0 au début, sera fixée par le vendeur qui reçoit la commande
  // Tu avais 2500 FC fixe, ça créait le 165000 vs 170000
  double get shippingCost => 0; // En attente du vendeur
  String get shippingSymbol => 'FC';

  double get total => subtotal + shippingCost;

  // Pour affichage détaillé
  double getItemRealPrice(Map<String, dynamic> item) => _getRealPrice(Map<String, dynamic>.from(item['product'] as Map??? {}));
  double getItemOldPrice(Map<String, dynamic> item) => _getOldPrice(Map<String, dynamic>.from(item['product'] as Map??? {}));
  int getItemDiscountPercent(Map<String, dynamic> item) {
    final oldP = getItemOldPrice(item);
    final real = getItemRealPrice(item);
    if (oldP <= 0 || real >= oldP) return 0;
    return ((1 - real / oldP) * 100).round();
  }

  // ============================================================
  // INIT / REALTIME (inchangé)
  // ============================================================
  CartProvider() { _init(); }

  void _init() {
    _currentUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId!= null) { _setupRealtimeSubscription(); loadCart(); }
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session!= null) { _currentUserId = session.user.id; _setupRealtimeSubscription(); loadCart(); }
      else { _currentUserId = null; _cartItems.clear(); _cartStream = null; notifyListeners(); }
    });
  }

  void _setupRealtimeSubscription() {
    if (_currentUserId == null) return;
    _cartStream = _supabase.from('cart').stream(primaryKey: ['id']).eq('user_id', _currentUserId!).order('created_at', ascending: false).map((d) => List<Map<String, dynamic>>.from(d));
    _cartStream?.listen((updated) async { await _syncCartWithProducts(updated); });
  }

  Future<void> _syncCartWithProducts(List<Map<String, dynamic>> cartRecords) async {
    if (cartRecords.isEmpty) { _cartItems = []; notifyListeners(); return; }
    _isSyncing = true; notifyListeners();
    try {
      final List<Map<String, dynamic>> enriched = [];
      for (var cartItem in cartRecords) {
        final productId = cartItem['product_id'];
        if (productId!= null) {
          final product = await _supabase.from('products').select('*, shop:shops(name, logo_url)').eq('id', productId).maybeSingle();
          if (product!= null) { enriched.add({...cartItem, 'product': product}); }
          else { await removeFromCart(cartItem['id']); }
        }
      }
      _cartItems = enriched;
    } catch (e) { debugPrint('Error syncing cart: $e'); }
    finally { _isSyncing = false; notifyListeners(); }
  }

  Future<void> loadCart() async {
    if (_currentUserId == null) { _cartItems = []; notifyListeners(); return; }
    _isLoading = true; notifyListeners();
    try {
      final res = await _supabase.from('cart').select().eq('user_id', _currentUserId!).order('created_at', ascending: false);
      await _syncCartWithProducts(List<Map<String, dynamic>>.from(res));
    } catch (e) { debugPrint('Error loading cart: $e'); }
    finally { _isLoading = false; notifyListeners(); }
  }

  Future<void> addToCart({required String productId, int quantity = 1, String? variant, String? color}) async {
    if (_currentUserId == null) throw Exception('Veuillez vous connecter');
    try {
      final existing = _cartItems.firstWhere((i) => i['product_id'] == productId && i['variant'] == variant && i['color'] == color, orElse: () => {});
      if (existing.isNotEmpty) { await updateQuantity(existing['id'], (existing['quantity']?? 0) + quantity); }
      else { await _supabase.from('cart').insert({'user_id': _currentUserId, 'product_id': productId, 'quantity': quantity, 'variant': variant, 'color': color, 'created_at': DateTime.now().toIso8601String()}); }
      await loadCart();
    } catch (e) { debugPrint('Error adding: $e'); rethrow; }
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) { await removeFromCart(cartItemId); return; }
    try {
      await _supabase.from('cart').update({'quantity': newQuantity}).eq('id', cartItemId);
      final idx = _cartItems.indexWhere((i) => i['id'] == cartItemId);
      if (idx!= -1) { _cartItems[idx]['quantity'] = newQuantity; notifyListeners(); }
    } catch (e) { debugPrint('Error update qty: $e'); rethrow; }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try { await _supabase.from('cart').delete().eq('id', cartItemId); _cartItems.removeWhere((i) => i['id'] == cartItemId); notifyListeners(); }
    catch (e) { debugPrint('Error remove: $e'); rethrow; }
  }

  Future<void> clearCart() async {
    if (_currentUserId == null) return;
    try { await _supabase.from('cart').delete().eq('user_id', _currentUserId!); _cartItems.clear(); notifyListeners(); }
    catch (e) { debugPrint('Error clear: $e'); rethrow; }
  }
}
