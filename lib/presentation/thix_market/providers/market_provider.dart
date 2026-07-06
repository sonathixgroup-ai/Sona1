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
  bool _isRefreshing = false;
  String? _error;
  DateTime? _lastLoadedAt;

  // ✅ Shop de l'utilisateur connecté
  String? _myShopId;
  bool _isLoadingMyShop = false;

  // Getters
  List<Map<String, dynamic>> get liveSessions => _liveSessions;
  List<Map<String, dynamic>> get flashSales => _flashSales;
  List<Map<String, dynamic>> get promoBanners => _promoBanners;
  List<Map<String, dynamic>> get recommendedProducts => _recommendedProducts;
  List<Map<String, dynamic>> get featuredShops => _featuredShops;
  List<Map<String, dynamic>> get forYouProducts => _forYouProducts;
  int get unreadNotifications => _unreadNotifications;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  String? get myShopId => _myShopId;
  bool get hasShop => _myShopId != null;
  bool get isLoadingMyShop => _isLoadingMyShop;

  bool get hasData =>
      _liveSessions.isNotEmpty ||
      _flashSales.isNotEmpty ||
      _promoBanners.isNotEmpty ||
      _recommendedProducts.isNotEmpty ||
      _featuredShops.isNotEmpty ||
      _forYouProducts.isNotEmpty;

  /// Nom affiché dans le message de bienvenue ("Bonjour, {name}")
  String get userDisplayName {
    final user = _supabase.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }
    final email = user?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'Utilisateur';
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> loadHomeData({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _loadLiveSessions(),
        _loadFlashSales(),
        _loadPromoBanners(),
        _loadRecommendedProducts(),
        _loadFeaturedShops(),
        _loadForYouProducts(),
        _loadUnreadNotifications(),
      ]);

      _liveSessions = results[0] as List<Map<String, dynamic>>;
      _flashSales = results[1] as List<Map<String, dynamic>>;
      _promoBanners = results[2] as List<Map<String, dynamic>>;
      _recommendedProducts = results[3] as List<Map<String, dynamic>>;
      _featuredShops = results[4] as List<Map<String, dynamic>>;
      _forYouProducts = results[5] as List<Map<String, dynamic>>;
      _unreadNotifications = results[6] as int;
      _lastLoadedAt = DateTime.now();

      // Charge le shop de l'utilisateur en parallèle (n'impacte pas home data si absent)
      unawaited(loadMyShop());
    } catch (e) {
      debugPrint('Error loading home data from Supabase: $e');
      _error = 'Impossible de charger les données. Vérifiez votre connexion.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// ✅ Récupère l'ID du shop appartenant à l'utilisateur connecté (s'il existe)
  Future<void> loadMyShop() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _myShopId = null;
      notifyListeners();
      return;
    }

    _isLoadingMyShop = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('shops')
          .select('id')
          .eq('owner_id', userId)
          .limit(1)
          .maybeSingle();

      _myShopId = response?['id'] as String?;
    } catch (e) {
      debugPrint('Error loading my shop: $e');
      _myShopId = null;
    } finally {
      _isLoadingMyShop = false;
      notifyListeners();
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
          .limit(8);
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
          .limit(10);
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
          .limit(20);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading "for you" products: $e');
      return [];
    }
  }

  Future<int> _loadUnreadNotifications() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      debugPrint('Error loading unread notifications: $e');
      return 0;
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  Future<void> refresh() async {
    await loadHomeData(isRefresh: true);
  }

  Future<void> loadIfStale({Duration maxAge = const Duration(minutes: 3)}) async {
    if (_lastLoadedAt == null ||
        DateTime.now().difference(_lastLoadedAt!) > maxAge) {
      await loadHomeData();
    }
  }
}

// Petit helper pour ignorer un Future sans bloquer (évite d'importer dart:async juste pour ça)
void unawaited(Future<void> future) {}
