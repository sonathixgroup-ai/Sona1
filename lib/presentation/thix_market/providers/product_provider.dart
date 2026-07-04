import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _favorites = [];
  List<Map<String, dynamic>> _wishlist = [];
  Map<String, dynamic>? _currentProduct;
  bool _isLoading = false;
  bool _isLoadingFavorites = false;
  bool _isLoadingWishlist = false;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _currentCategory;
  String? _currentSearchQuery;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get favorites => _favorites;
  List<Map<String, dynamic>> get wishlist => _wishlist;
  Map<String, dynamic>? get currentProduct => _currentProduct;
  bool get isLoading => _isLoading;
  bool get isLoadingFavorites => _isLoadingFavorites;
  bool get isLoadingWishlist => _isLoadingWishlist;
  bool get hasMore => _hasMore;

  Future<void> loadProducts({String? category, String? query, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _products.clear();
      _hasMore = true;
    }
    if (!_hasMore) return;
    
    _setLoading(true);
    _currentCategory = category;
    _currentSearchQuery = query;
    
    try {
      var request = _supabase
          .from('products')
          .select('*, shop:shops(name, rating)')
          .eq('status', 'active')
          .range(_currentPage * 20, (_currentPage + 1) * 20 - 1)
          .order('created_at', ascending: false);
      
      if (category != null && category != 'all') {
        request = request.eq('category', category);
      }
      if (query != null && query.isNotEmpty) {
        request = request.ilike('title', '%$query%');
      }
      
      final response = await request;
      final newProducts = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        if (newProducts.length < 20) _hasMore = false;
        _products.addAll(newProducts);
        _currentPage++;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProductDetail(String productId) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(*), reviews:reviews(*, user:users(name, avatar))')
          .eq('id', productId)
          .single();
      _currentProduct = response;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading product detail: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    _setLoadingFavorites(true);
    try {
      final response = await _supabase
          .from('wishlist')
          .select('product:products(*, shop:shops(name))')
          .eq('user_id', userId);
      _favorites = response.map((e) => Map<String, dynamic>.from(e['product'])).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _setLoadingFavorites(false);
    }
  }

  Future<void> loadWishlist() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    _setLoadingWishlist(true);
    try {
      final response = await _supabase
          .from('wishlists')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _wishlist = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    } finally {
      _setLoadingWishlist(false);
    }
  }

  Future<void> toggleFavorite(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      final existing = await _supabase
          .from('wishlist')
          .select()
          .match({'user_id': userId, 'product_id': productId})
          .maybeSingle();
      
      if (existing != null) {
        await _supabase
            .from('wishlist')
            .delete()
            .match({'user_id': userId, 'product_id': productId});
        _favorites.removeWhere((p) => p['id'] == productId);
      } else {
        await _supabase
            .from('wishlist')
            .insert({'user_id': userId, 'product_id': productId, 'created_at': DateTime.now().toIso8601String()});
        final product = _products.firstWhere((p) => p['id'] == productId, orElse: () => {});
        if (product.isNotEmpty) _favorites.add(product);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> removeFromWishlist(String wishlistId) async {
    try {
      await _supabase.from('wishlists').delete().eq('id', wishlistId);
      _wishlist.removeWhere((w) => w['id'] == wishlistId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from wishlist: $e');
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingFavorites(bool loading) {
    _isLoadingFavorites = loading;
    notifyListeners();
  }

  void _setLoadingWishlist(bool loading) {
    _isLoadingWishlist = loading;
    notifyListeners();
  }

  void reset() {
    _products.clear();
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
  }
}
