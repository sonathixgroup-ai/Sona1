import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class AdminApiService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String baseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://your-project.supabase.co');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'your-anon-key');

  // Headers pour les appels Edge Functions
  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? anonKey}',
        'Content-Type': 'application/json',
      };

  // ============================================================
  // Dashboard
  // ============================================================

  /// Récupère les statistiques du tableau de bord
  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await _supabase.rpc('get_admin_dashboard_stats');
      return DashboardStats.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des statistiques: $e');
    }
  }

  /// Récupère les activités récentes des administrateurs
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('admin_activities')
          .select('*, admin:users(name, avatar)')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des activités: $e');
    }
  }

  // ============================================================
  // Gestion des produits
  // ============================================================

  /// Récupère tous les produits avec pagination et filtres
  Future<PaginatedResult<Map<String, dynamic>>> getProducts({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
    String? shopId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('products')
          .select('*, shop:shops(id, name)', count: CountOption.exact)
          .range(page * limit, (page + 1) * limit - 1);

      if (search != null && search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (shopId != null) {
        query = query.eq('shop_id', shopId);
      }
      query = query.order(sortBy, ascending: ascending);

      final response = await query;
      return PaginatedResult(
        items: List<Map<String, dynamic>>.from(response),
        total: response.count ?? 0,
      );
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des produits: $e');
    }
  }

  /// Met à jour le statut d'un produit
  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await _supabase
          .from('products')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
      await _logActivity('product', productId, 'status_changed', {'new_status': status});
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour du produit: $e');
    }
  }

  /// Supprime définitivement un produit (admin only)
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase.from('products').delete().eq('id', productId);
      await _logActivity('product', productId, 'deleted', {});
    } catch (e) {
      throw AdminApiException('Erreur lors de la suppression du produit: $e');
    }
  }

  // ============================================================
  // Gestion des boutiques
  // ============================================================

  /// Récupère toutes les boutiques avec pagination et filtres
  Future<PaginatedResult<Map<String, dynamic>>> getShops({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
    String? ownerId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('shops')
          .select('*, owner:users(id, name, email)', count: CountOption.exact)
          .range(page * limit, (page + 1) * limit - 1);

      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (ownerId != null) {
        query = query.eq('owner_id', ownerId);
      }
      query = query.order(sortBy, ascending: ascending);

      final response = await query;
      return PaginatedResult(
        items: List<Map<String, dynamic>>.from(response),
        total: response.count ?? 0,
      );
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des boutiques: $e');
    }
  }

  /// Met à jour le statut d'une boutique
  Future<void> updateShopStatus(String shopId, String status) async {
    try {
      await _supabase
          .from('shops')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', shopId);
      await _logActivity('shop', shopId, 'status_changed', {'new_status': status});
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour de la boutique: $e');
    }
  }

  /// Vérifie une boutique (badge vérifié)
  Future<void> verifyShop(String shopId, bool verified) async {
    try {
      await _supabase
          .from('shops')
          .update({
            'is_verified': verified,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', shopId);
      await _logActivity('shop', shopId, verified ? 'verified' : 'unverified', {});
    } catch (e) {
      throw AdminApiException('Erreur lors de la vérification: $e');
    }
  }

  // ============================================================
  // Gestion des utilisateurs
  // ============================================================

  /// Récupère tous les utilisateurs avec pagination et filtres
  Future<PaginatedResult<Map<String, dynamic>>> getUsers({
    int page = 0,
    int limit = 20,
    String? search,
    String? role,
    bool includeDeleted = false,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('users')
          .select('*', count: CountOption.exact)
          .range(page * limit, (page + 1) * limit - 1);

      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%').or('email.ilike.%$search%');
      }
      if (role != null && role != 'all') {
        query = query.eq('role', role);
      }
      if (!includeDeleted) {
        query = query.is_('deleted_at', null);
      }
      query = query.order(sortBy, ascending: ascending);

      final response = await query;
      return PaginatedResult(
        items: List<Map<String, dynamic>>.from(response),
        total: response.count ?? 0,
      );
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des utilisateurs: $e');
    }
  }

  /// Met à jour le rôle d'un utilisateur
  Future<void> updateUserRole(String userId, String role) async {
    try {
      await _supabase
          .from('users')
          .update({
            'role': role,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      await _logActivity('user', userId, 'role_changed', {'new_role': role});
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour du rôle: $e');
    }
  }

  /// Suspendre un utilisateur
  Future<void> suspendUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_suspended': true,
            'suspended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      await _logActivity('user', userId, 'suspended', {});
    } catch (e) {
      throw AdminApiException('Erreur lors de la suspension: $e');
    }
  }

  /// Réactiver un utilisateur
  Future<void> activateUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_suspended': false,
            'suspended_at': null,
          })
          .eq('id', userId);
      await _logActivity('user', userId, 'activated', {});
    } catch (e) {
      throw AdminApiException('Erreur lors de la réactivation: $e');
    }
  }

  // ============================================================
  // Gestion des commandes
  // ============================================================

  /// Récupère toutes les commandes avec pagination et filtres
  Future<PaginatedResult<Map<String, dynamic>>> getOrders({
    int page = 0,
    int limit = 20,
    String? search,
    String? status,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('*, user:users(name, email)', count: CountOption.exact)
          .range(page * limit, (page + 1) * limit - 1);

      if (search != null && search.isNotEmpty) {
        query = query.ilike('id', '%$search%');
      }
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('created_at', toDate.toIso8601String());
      }
      query = query.order(sortBy, ascending: ascending);

      final response = await query;
      return PaginatedResult(
        items: List<Map<String, dynamic>>.from(response),
        total: response.count ?? 0,
      );
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des commandes: $e');
    }
  }

  /// Met à jour le statut d'une commande
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
            status == 'delivered' ? 'delivered_at' : null: status == 'delivered' ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', orderId);
      await _logActivity('order', orderId, 'status_changed', {'new_status': status});
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour de la commande: $e');
    }
  }

  // ============================================================
  // Gestion des litiges
  // ============================================================

  /// Récupère tous les litiges avec pagination et filtres
  Future<PaginatedResult<Map<String, dynamic>>> getDisputes({
    int page = 0,
    int limit = 20,
    String? status,
    String? userId,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    try {
      var query = _supabase
          .from('disputes')
          .select('*, order:orders(id, total), user:users(name)', count: CountOption.exact)
          .range(page * limit, (page + 1) * limit - 1);

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      query = query.order(sortBy, ascending: ascending);

      final response = await query;
      return PaginatedResult(
        items: List<Map<String, dynamic>>.from(response),
        total: response.count ?? 0,
      );
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des litiges: $e');
    }
  }

  /// Met à jour le statut d'un litige
  Future<void> updateDisputeStatus(String disputeId, String status, {String? mediatorId}) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (mediatorId != null) 'mediator_id': mediatorId,
      };
      await _supabase.from('disputes').update(updates).eq('id', disputeId);
      await _logActivity('dispute', disputeId, 'status_changed', {'new_status': status, 'mediator_id': mediatorId});
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour du litige: $e');
    }
  }

  // ============================================================
  // Gestion des promotions
  // ============================================================

  /// Récupère toutes les promotions
  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final response = await _supabase
          .from('promotions')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des promotions: $e');
    }
  }

  /// Crée une nouvelle promotion
  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('promotions')
          .insert({
            ...data,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      await _logActivity('promotion', response['id'], 'created', data);
      return response;
    } catch (e) {
      throw AdminApiException('Erreur lors de la création de la promotion: $e');
    }
  }

  /// Met à jour une promotion
  Future<void> updatePromotion(String promotionId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('promotions')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', promotionId);
      await _logActivity('promotion', promotionId, 'updated', updates);
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour de la promotion: $e');
    }
  }

  /// Récupère les bannières promotionnelles
  Future<List<Map<String, dynamic>>> getBanners() async {
    try {
      final response = await _supabase
          .from('promo_banners')
          .select()
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des bannières: $e');
    }
  }

  /// Met à jour une bannière
  Future<void> updateBanner(String bannerId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('promo_banners')
          .update(updates)
          .eq('id', bannerId);
      await _logActivity('banner', bannerId, 'updated', updates);
    } catch (e) {
      throw AdminApiException('Erreur lors de la mise à jour de la bannière: $e');
    }
  }

  // ============================================================
  // Statistiques avancées
  // ============================================================

  /// Récupère les statistiques de vente par période
  Future<List<Map<String, dynamic>>> getSalesStats(String period, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await _supabase.rpc('get_admin_sales_stats', params: {
        'period': period,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement des statistiques de vente: $e');
    }
  }

  /// Récupère le top des produits
  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 10, String period = 'month'}) async {
    try {
      final response = await _supabase.rpc('get_top_products', params: {
        'limit': limit,
        'period': period,
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw AdminApiException('Erreur lors du chargement du top produits: $e');
    }
  }

  // ============================================================
  // Rapports et exports
  // ============================================================

  /// Génère un rapport CSV des commandes
  Future<String> exportOrdersReport({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
  }) async {
    try {
      final response = await _supabase.functions.invoke('export-orders-report', body: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': status,
      });
      return response.data['csv_url'] as String;
    } catch (e) {
      throw AdminApiException('Erreur lors de la génération du rapport: $e');
    }
  }

  /// Génère un rapport PDF
  Future<String> generatePdfReport(String type, Map<String, dynamic> params) async {
    try {
      final response = await _supabase.functions.invoke('generate-pdf-report', body: {
        'type': type,
        'params': params,
      });
      return response.data['pdf_url'] as String;
    } catch (e) {
      throw AdminApiException('Erreur lors de la génération du PDF: $e');
    }
  }

  // ============================================================
  // Utilitaires
  // ============================================================

  /// Journalisation des actions admin
  Future<void> _logActivity(String targetType, String targetId, String action, Map<String, dynamic>? metadata) async {
    final adminId = _supabase.auth.currentUser?.id;
    if (adminId == null) return;

    try {
      await _supabase.from('admin_activities').insert({
        'admin_id': adminId,
        'target_type': targetType,
        'target_id': targetId,
        'action': action,
        'metadata': metadata,
        'ip_address': '', // à récupérer côté client si besoin
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Ne pas bloquer l'action principale si le logging échoue
      debugPrint('Failed to log admin activity: $e');
    }
  }
}

// ============================================================
// Modèles associés
// ============================================================

class DashboardStats {
  final int totalUsers;
  final int totalShops;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final double thisMonthRevenue;
  final double revenueGrowth;

  DashboardStats({
    required this.totalUsers,
    required this.totalShops,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.revenueGrowth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] ?? 0,
      totalShops: json['total_shops'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      thisMonthRevenue: (json['this_month_revenue'] as num?)?.toDouble() ?? 0,
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final int total;

  PaginatedResult({required this.items, required this.total});
}

class AdminApiException implements Exception {
  final String message;
  AdminApiException(this.message);
  @override
  String toString() => 'AdminApiException: $message';
}
