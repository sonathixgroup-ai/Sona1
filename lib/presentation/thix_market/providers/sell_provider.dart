// lib/presentation/thix_market/providers/sell_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // ANNONCES (PRODUITS DU VENDEUR)
  // ============================================================
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = false;

  // ============================================================
  // COMMANDES
  // ============================================================
  List<Map<String, dynamic>> _orders = [];
  bool _isLoadingOrders = false;

  // ============================================================
  // STATISTIQUES
  // ============================================================
  Map<String, dynamic> _stats = {};

  // ============================================================
  // LIVES
  // ============================================================
  List<Map<String, dynamic>> _myLives = [];
  bool _isLoadingLives = false;

  // ============================================================
  // GETTERS
  // ============================================================
  List<Map<String, dynamic>> get announcements => _announcements;
  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingOrders => _isLoadingOrders;
  List<Map<String, dynamic>> get myLives => _myLives;
  bool get isLoadingLives => _isLoadingLives;

  // ============================================================
  // CHARGEMENT DES ANNONCES (PRODUITS DU VENDEUR)
  // ============================================================
  Future<void> loadMyAnnouncements() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Récupérer les shop_id du vendeur
      final shopResponse = await _supabase
          .from('shops')
          .select('id')
          .eq('owner_id', userId);

      final shopIds = shopResponse.map((e) => e['id'] as String).toList();

      if (shopIds.isEmpty) {
        _announcements = [];
        return;
      }

      // 2. Récupérer les produits de ces boutiques
      final response = await _supabase
          .from('products')
          .select('*, shop:shops(name, logo_url)')
          .inFilter('shop_id', shopIds)
          .order('created_at', ascending: false);

      _announcements = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading announcements: $e');
      _announcements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHARGEMENT DES COMMANDES
  // ============================================================
  Future<void> loadOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingOrders = true;
    notifyListeners();

    try {
      // Récupérer les shop_id du vendeur
      final shopResponse = await _supabase
          .from('shops')
          .select('id')
          .eq('owner_id', userId);

      final shopIds = shopResponse.map((e) => e['id'] as String).toList();

      if (shopIds.isEmpty) {
        _orders = [];
        _stats = {};
        return;
      }

      // Récupérer les commandes des boutiques
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            status,
            total,
            created_at,
            order_items(count)
          ''')
          .inFilter('shop_id', shopIds)
          .order('created_at', ascending: false);

      _orders = List<Map<String, dynamic>>.from(response).map((order) {
        return {
          ...order,
          'date': (order['created_at'] ?? '').toString().split('T').first,
          'items_count': ((order['order_items'] as List?)?.length ?? 0),
        };
      }).toList();

      // Calculer les statistiques
      final totalSales = _orders.length;
      final revenue = _orders.fold<num>(0, (sum, order) => sum + ((order['total'] ?? 0) as num));
      final totalViews = _announcements.fold<num>(0, (sum, item) => sum + ((item['views'] ?? 0) as num));
      final conversionRate = _announcements.isEmpty ? 0 : ((totalSales / _announcements.length) * 100).round();

      _stats = {
        'total_sales': totalSales,
        'revenue': revenue,
        'total_views': totalViews,
        'conversion_rate': conversionRate,
        'top_products': _announcements.take(3).map((item) {
          return {
            'name': item['title'] ?? 'Annonce',
            'sales': item['sales_count'] ?? 0,
            'image_url': item['image_url'],
          };
        }).toList(),
        'sales_data': _generateSalesData(),
      };
    } catch (e) {
      debugPrint('Error loading orders: $e');
      _orders = [];
      _stats = {};
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GÉNÉRATION DE DONNÉES DE VENTE (exemple)
  // ============================================================
  List<Map<String, dynamic>> _generateSalesData() {
    // Simuler des données de vente mensuelles (à remplacer par de vraies données)
    final now = DateTime.now();
    List<Map<String, dynamic>> data = [];
    for (int i = 0; i < 6; i++) {
      final month = now.month - i;
      final year = now.year;
      data.add({
        'label': '${month < 1 ? 12 + month : month}/${month < 1 ? year - 1 : year}',
        'value': (100 + i * 50 + (i % 3) * 30).toDouble(),
      });
    }
    return data.reversed.toList();
  }

  // ============================================================
  // CHARGEMENT DES LIVES
  // ============================================================
  Future<void> loadMyLives() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingLives = true;
    notifyListeners();

    try {
      final shopResponse = await _supabase
          .from('shops')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();

      if (shopResponse == null) {
        _myLives = [];
        return;
      }

      final shopId = shopResponse['id'];
      final response = await _supabase
          .from('lives')
          .select()
          .eq('shop_id', shopId)
          .order('created_at', ascending: false);

      _myLives = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading lives: $e');
      _myLives = [];
    } finally {
      _isLoadingLives = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CRÉER UN LIVE
  // ============================================================
  Future<void> createLive(Map<String, dynamic> liveData) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final shopResponse = await _supabase
          .from('shops')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();

      if (shopResponse == null) return;

      final shopId = shopResponse['id'];
      await _supabase.from('lives').insert({
        ...liveData,
        'shop_id': shopId,
        'status': 'scheduled',
        'created_at': DateTime.now().toIso8601String(),
      });

      await loadMyLives();
    } catch (e) {
      debugPrint('Error creating live: $e');
      rethrow;
    }
  }

  // ============================================================
  // SUPPRIMER UN LIVE
  // ============================================================
  Future<void> deleteLive(String liveId) async {
    try {
      await _supabase.from('lives').delete().eq('id', liveId);
      await loadMyLives();
    } catch (e) {
      debugPrint('Error deleting live: $e');
      rethrow;
    }
  }
}
