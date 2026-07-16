// lib/presentation/thix_market/providers/sell_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // États
  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _myLives = [];
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = false;
  bool _isLoadingOrders = false;
  bool _isLoadingLives = false;

  // Getters
  List<Map<String, dynamic>> get announcements => _announcements;
  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get myLives => _myLives;
  
  bool get isLoading => _isLoading;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isLoadingLives => _isLoadingLives;

  // ============================================================
  // 1. CHARGEMENT DES ANNONCES
  // ============================================================
  Future<void> loadMyAnnouncements() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final shopResponse = await _supabase.from('shops').select('id').eq('owner_id', userId);
      final shopIds = shopResponse.map((e) => e['id']).toList();

      if (shopIds.isEmpty) {
        _announcements = [];
      } else {
        final response = await _supabase
            .from('products')
            .select('*, shop:shops(name, logo_url)')
            .inFilter('shop_id', shopIds)
            .order('created_at', ascending: false);
        _announcements = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint('🚨 Erreur Annonces: $e');
      _announcements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 2. CHARGEMENT DES COMMANDES (ROBUSTE)
  // ============================================================
  Future<void> loadOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    _isLoadingOrders = true;
    notifyListeners();

    try {
      final shopResponse = await _supabase.from('shops').select('id').eq('owner_id', userId);
      final shopIds = shopResponse.map((e) => e['id']).toList();

      if (shopIds.isEmpty) {
        _orders = [];
        _stats = {};
        _isLoadingOrders = false;
        notifyListeners();
        return;
      }

      // Requête sécurisée sans jointure risquée
      final response = await _supabase
          .from('orders')
          .select('id, status, total, created_at, customer_name, customer_phone, shipping_address')
          .inFilter('shop_id', shopIds)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      final fullOrders = [];

      // Boucle de récupération des articles sécurisée
      for (var order in list) {
        int itemsCount = 0;
        List items = [];
        try {
          items = await _supabase.from('order_items').select('*').eq('order_id', order['id']);
          itemsCount = items.length;
        } catch (_) {}

        fullOrders.add({
          ...order,
          'date': (order['created_at'] ?? '').toString().split('T').first,
          'items_count': itemsCount,
          'items': items, // Nécessaire pour l'affichage de ta tile
        });
      }

      _orders = List<Map<String, dynamic>>.from(fullOrders);

      // Calcul stats
      final totalSales = _orders.length;
      final revenue = _orders.fold<num>(0, (sum, o) => sum + ((o['total'] ?? 0) as num));
      
      _stats = {
        'total_sales': totalSales,
        'revenue': revenue,
        'total_views': _announcements.fold<num>(0, (sum, i) => sum + ((i['views'] ?? 0) as num)),
        'sales_data': _generateSalesData(),
      };

    } catch (e) {
      debugPrint('🚨 Erreur Commandes: $e');
      _orders = [];
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 3. CHARGEMENT DES LIVES
  // ============================================================
  Future<void> loadMyLives() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingLives = true;
    notifyListeners();

    try {
      final shopResponse = await _supabase.from('shops').select('id').eq('owner_id', userId).maybeSingle();
      if (shopResponse != null) {
        final response = await _supabase
            .from('lives')
            .select()
            .eq('shop_id', shopResponse['id'])
            .order('created_at', ascending: false);
        _myLives = List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint('🚨 Erreur Lives: $e');
      _myLives = [];
    } finally {
      _isLoadingLives = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================
  List<Map<String, dynamic>> _generateSalesData() {
    return List.generate(6, (i) => {
      'label': 'M-${5 - i}',
      'value': (100.0 + i * 50.0),
    });
  }
}
