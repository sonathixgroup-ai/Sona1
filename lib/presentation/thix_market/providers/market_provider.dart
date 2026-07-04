import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _liveSessions = [];
  List<Map<String, dynamic>> _flashSales = [];
  List<Map<String, dynamic>> _promoBanners = [];
  List<Map<String, dynamic>> _recommendedProducts = [];
  List<Map<String, dynamic>> _featuredShops = [];
  List<Map<String, dynamic>> _forYouProducts = [];
  int _unreadNotifications = 0;
  bool _isLoading = false;

  // Getters
  List<Map<String, dynamic>> get liveSessions => _liveSessions;
  List<Map<String, dynamic>> get flashSales => _flashSales;
  List<Map<String, dynamic>> get promoBanners => _promoBanners;
  List<Map<String, dynamic>> get recommendedProducts => _recommendedProducts;
  List<Map<String, dynamic>> get featuredShops => _featuredShops;
  List<Map<String, dynamic>> get forYouProducts => _forYouProducts;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;

  Future<void> loadHomeData() async {
    _setLoading(true);
    try {
      await Future.wait([
        _loadLiveSessions(),
        _loadFlashSales(),
        _loadPromoBanners(),
        _loadRecommendedProducts(),
        _loadFeaturedShops(),
        _loadForYouProducts(),
        _loadUnreadNotifications(),
      ]);
    } catch (e) {
      debugPrint('Error loading home data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadLiveSessions() async {
    try {
      final response = await _supabase
          .from('lives')
          .select('*, shop:shops(name, logo_url)')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(5);
      _liveSessions = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading live sessions: $e');
    }
  }

  Future<void> _loadFlashSales() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(name)')
          .eq('is_flash_sale', true)
          .gt('flash_sale_end', DateTime.now().toIso8601String())
          .order('flash_sale_price', ascending: true)
          .limit(10);
      _flashSales = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading flash sales: $e');
    }
  }

  Future<void> _loadPromoBanners() async {
    try {
      final response = await _supabase
          .from('promo_banners')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);
      _promoBanners = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading promo banners: $e');
    }
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await _supabase
            .rpc('get_recommended_products', params: {'user_id': userId, 'limit': 10});
        _recommendedProducts = List<Map<String, dynamic>>.from(response);
      } else {
        final response = await _supabase
            .from('products')
            .select('*, shop:shops(name)')
            .eq('status', 'active')
            .order('rating', ascending: false)
            .limit(10);
        _recommendedProducts = List<Map<String, dynamic>>.from(response);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recommended products: $e');
    }
  }

  Future<void> _loadFeaturedShops() async {
    try {
      final response = await _supabase
          .from('shops')
          .select()
          .eq('is_featured', true)
          .eq('status', 'active')
          .limit(10);
      _featuredShops = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured shops: $e');
    }
  }

  Future<void> _loadForYouProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(name)')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(20);
      _forYouProducts = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading for you products: $e');
    }
  }

  Future<void> _loadUnreadNotifications() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final response = await _supabase
          .from('notifications')
          .select('id', count: CountOption.exact)
          .eq('user_id', userId)
          .eq('is_read', false);
      _unreadNotifications = response.count ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading unread notifications: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
