// lib/presentation/thix_market/providers/market_provider.dart
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

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> loadHomeData() async {
    _setLoading(true);
    try {
      // Exécuter toutes les requêtes en parallèle (sans les notifications)
      final results = await Future.wait([
        _loadLiveSessions(),
        _loadFlashSales(),
        _loadPromoBanners(),
        _loadRecommendedProducts(),
        _loadFeaturedShops(),
        _loadForYouProducts(),
      ]);

      // Affectation avec cast explicite
      _liveSessions = results[0] as List<Map<String, dynamic>>;
      _flashSales = results[1] as List<Map<String, dynamic>>;
      _promoBanners = results[2] as List<Map<String, dynamic>>;
      _recommendedProducts = results[3] as List<Map<String, dynamic>>;
      _featuredShops = results[4] as List<Map<String, dynamic>>;
      _forYouProducts = results[5] as List<Map<String, dynamic>>;
      // Les notifications ne sont pas chargées pour l'instant
      _unreadNotifications = 0;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading home data from Supabase: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REQUÊTES SUPABASE INDIVIDUELLES
  // ============================================================

  Future<List<Map<String, dynamic>>> _loadLiveSessions() async {
    try {
      final response = await _supabase
          .from('lives')
          .select('*, shop:shops(name, logo_url, city)')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading live sessions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadFlashSales() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(name, city)')
          .eq('status', 'active')
          .eq('is_flash_sale', true)
          .order('created_at', ascending: false)
          .limit(8);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading flash sales: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadPromoBanners() async {
    try {
      final response = await _supabase
          .from('promo_banners')
          .select('*')
          .eq('active', true)
          .order('display_order', ascending: true)
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading promo banners: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecommendedProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(name, city)')
          .eq('status', 'active')
          .order('rating', ascending: false)
          .limit(8);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading recommended products: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadFeaturedShops() async {
    try {
      final response = await _supabase
          .from('shops')
          .select('*, city')
          .eq('is_featured', true)
          .order('followers_count', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading featured shops: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadForYouProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(name, city)')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(12);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading "for you" products: $e');
      return [];
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadHomeData();
  }
}
