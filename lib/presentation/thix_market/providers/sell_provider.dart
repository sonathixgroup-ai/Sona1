import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // ANNONCES
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
  // CHARGEMENT DES ANNONCES
  // ============================================================
  Future<void> loadMyAnnouncements() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _announcements = List<Map<String, dynamic>>.from(response);
    } catch (_) {
      _announcements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHARGEMENT DES COMMANDES ET STATISTIQUES
  // ============================================================
  Future<void> loadOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingOrders = true;
    notifyListeners();
    try {
      final shopIds = await _supabase.from('shops').select('id').eq('owner_id', userId);
      final ids = shopIds.map((e) => e['id']).whereType<String>().toList();
      if (ids.isEmpty) {
        _orders = [];
      } else {
        final response = await _supabase
            .from('orders')
            .select('id, status, total, created_at, order_items(count)')
            .inFilter('shop_id', ids)
            .order('created_at', ascending: false);
        _orders = List<Map<String, dynamic>>.from(response).map((order) => {
              ...order,
              'date': (order['created_at'] ?? '').toString().split('T').first,
              'items_count': ((order['order_items'] as List?)?.length ?? 0),
            }).toList();
      }
      _stats = {
        'total_sales': _orders.length,
        'revenue': _orders.fold<num>(0, (sum, order) => sum + ((order['total'] ?? 0) as num)),
        'total_views': _announcements.fold<num>(0, (sum, item) => sum + ((item['views'] ?? 0) as num)),
        'conversion_rate': _announcements.isEmpty ? 0 : ((_orders.length / _announcements.length) * 100).round(),
        'top_products': _announcements.take(3).map((item) => {
          'name': item['title'] ?? 'Annonce',
          'sales': item['sales_count'] ?? 0,
        }).toList(),
      };
    } catch (_) {
      _orders = [];
      _stats = {};
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CHARGEMENT DES LIVES (NOUVEAU)
  // ============================================================
  Future<void> loadMyLives() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    _isLoadingLives = true;
    notifyListeners();
    try {
      // Récupérer l'ID de la boutique du vendeur
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
      // Récupérer l'ID de la boutique
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

      // Recharger la liste
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
