import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _myShops = [];
  List<Map<String, dynamic>> _followedShops = [];
  Map<String, dynamic>? _currentShop;
  bool _isLoading = false;
  bool _isLoadingFollowed = false;

  // Getters
  List<Map<String, dynamic>> get myShops => _myShops;
  List<Map<String, dynamic>> get followedShops => _followedShops;
  Map<String, dynamic>? get currentShop => _currentShop;
  bool get isLoading => _isLoading;
  bool get isLoadingFollowed => _isLoadingFollowed;

  // ✅ Utiles pour MarketHomePage
  bool get hasShop => _myShops.isNotEmpty;
  String? get myShopId => _myShops.isNotEmpty ? _myShops.first['id'] : null;

  // ============================================================
  // CHARGEMENT DES BOUTIQUES
  // ============================================================

  Future<void> loadMyShops() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _setLoading(true);
    try {
      final response = await _supabase
          .from('shops')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      _myShops = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading my shops: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFollowedShops() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _setLoadingFollowed(true);
    try {
      final response = await _supabase
          .from('shop_followers')
          .select('shop:shops(*)')
          .eq('user_id', userId);
      _followedShops = response.map((e) => Map<String, dynamic>.from(e['shop'])).toList();
    } catch (e) {
      debugPrint('Error loading followed shops: $e');
    } finally {
      _setLoadingFollowed(false);
    }
  }

  // ============================================================
  // DÉTAIL D'UNE BOUTIQUE (avec produits et statut de suivi)
  // ============================================================

  Future<void> loadShopDetails(String shopId) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;

      // 1. Récupérer la boutique et ses produits
      final response = await _supabase
          .from('shops')
          .select('''
            *,
            products:products(*)
          ''')
          .eq('id', shopId)
          .single();

      // 2. Vérifier si l'utilisateur suit cette boutique
      bool isFollowed = false;
      if (userId != null) {
        final followCheck = await _supabase
            .from('shop_followers')
            .select('id')
            .match({'user_id': userId, 'shop_id': shopId})
            .maybeSingle();
        isFollowed = followCheck != null;
      }
      response['is_followed'] = isFollowed;

      _currentShop = response;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading shop details: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SUIVRE / NE PLUS SUIVRE
  // ============================================================

  Future<void> toggleFollowShop(String shopId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final existing = await _supabase
          .from('shop_followers')
          .select()
          .match({'user_id': userId, 'shop_id': shopId})
          .maybeSingle();

      if (existing != null) {
        // Désabonner
        await _supabase
            .from('shop_followers')
            .delete()
            .match({'user_id': userId, 'shop_id': shopId});
        await _supabase.rpc('decrement_shop_followers', params: {'shop_id': shopId});
        // Mettre à jour le statut dans _currentShop
        if (_currentShop != null && _currentShop!['id'] == shopId) {
          _currentShop!['is_followed'] = false;
          notifyListeners();
        }
      } else {
        // S'abonner
        await _supabase
            .from('shop_followers')
            .insert({
              'user_id': userId,
              'shop_id': shopId,
              'created_at': DateTime.now().toIso8601String(),
            });
        await _supabase.rpc('increment_shop_followers', params: {'shop_id': shopId});
        if (_currentShop != null && _currentShop!['id'] == shopId) {
          _currentShop!['is_followed'] = true;
          notifyListeners();
        }
      }
      await loadFollowedShops();
    } catch (e) {
      debugPrint('Error toggling follow: $e');
    }
  }

  // ============================================================
  // CRÉER / METTRE À JOUR UNE BOUTIQUE
  // ============================================================

  Future<void> createShop(Map<String, dynamic> shopData) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('shops')
          .insert({
            ...shopData,
            'owner_id': _supabase.auth.currentUser!.id,
            'created_at': DateTime.now().toIso8601String(),
            'status': 'pending',
          })
          .select()
          .single();
      _myShops.insert(0, response);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating shop: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateShop(String shopId, Map<String, dynamic> updates) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('shops')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', shopId)
          .select()
          .single();
      final index = _myShops.indexWhere((s) => s['id'] == shopId);
      if (index != -1) _myShops[index] = response;
      if (_currentShop?['id'] == shopId) _currentShop = response;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating shop: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingFollowed(bool loading) {
    _isLoadingFollowed = loading;
    notifyListeners();
  }
}
