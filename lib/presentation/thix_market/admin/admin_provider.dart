import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;

  DashboardStats _dashboardStats = DashboardStats.empty();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _disputes = [];

  int _currentPage = 0;
  int _pageSize = 20;

  String _searchQuery = '';
  String _statusFilter = 'all';

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _isAdmin;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get shops => _shops;
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get orders => _orders;
  List<Map<String, dynamic>> get disputes => _disputes;

  DashboardStats get dashboardStats => _dashboardStats;

  // =========================
  // ADMIN CHECK
  // =========================
  Future<bool> checkAdminStatus() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = await _supabase
          .from('users')
          .select('role')
          .eq('id', userId)
          .single();

      _isAdmin = data['role'] == 'admin';
      notifyListeners();
      return _isAdmin;
    } catch (_) {
      return false;
    }
  }

  // =========================
  // DASHBOARD
  // =========================
  Future<void> loadDashboard() async {
    if (!_isAdmin) return;

    _setLoading(true);

    try {
      final stats = await _supabase.rpc('get_admin_dashboard_stats');
      _dashboardStats = DashboardStats.fromJson(stats);

      final ordersData = await _supabase
          .from('orders')
          .select('*, user:users(name)')
          .order('created_at', ascending: false)
          .limit(10);

      final activitiesData = await _supabase
          .from('admin_activities')
          .select('*, admin:users(name)')
          .order('created_at', ascending: false)
          .limit(10);

      _orders = List<Map<String, dynamic>>.from(ordersData);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // PRODUCTS
  // =========================
  Future<void> loadProducts({bool refresh = false}) async {
    if (!_isAdmin) return;

    if (refresh) {
      _currentPage = 0;
      _products.clear();
    }

    _setLoading(true);

    try {
      final data = await _supabase
          .from('products')
          .select('*, shop:shops(name)')
          .ilike('title', _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%')
          .order('created_at', ascending: false)
          .range(
            _currentPage * _pageSize,
            (_currentPage + 1) * _pageSize - 1,
          );

      _products = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // SHOPS
  // =========================
  Future<void> loadShops({bool refresh = false}) async {
    if (!_isAdmin) return;

    if (refresh) {
      _currentPage = 0;
      _shops.clear();
    }

    _setLoading(true);

    try {
      final data = await _supabase
          .from('shops')
          .select('*, owner:users(name, email)')
          .ilike('name', _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%')
          .order('created_at', ascending: false)
          .range(
            _currentPage * _pageSize,
            (_currentPage + 1) * _pageSize - 1,
          );

      _shops = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // USERS
  // =========================
  Future<void> loadUsers({bool refresh = false}) async {
    if (!_isAdmin) return;

    if (refresh) {
      _currentPage = 0;
      _users.clear();
    }

    _setLoading(true);

    try {
      final data = await _supabase
          .from('users')
          .select('*')
          .ilike('name', _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%')
          .order('created_at', ascending: false)
          .range(
            _currentPage * _pageSize,
            (_currentPage + 1) * _pageSize - 1,
          );

      _users = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // ORDERS
  // =========================
  Future<void> loadOrders({bool refresh = false}) async {
    if (!_isAdmin) return;

    if (refresh) {
      _currentPage = 0;
      _orders.clear();
    }

    _setLoading(true);

    try {
      final data = await _supabase
          .from('orders')
          .select('*, user:users(name, email)')
          .ilike('id', _searchQuery.isNotEmpty ? '%$_searchQuery%' : '%')
          .order('created_at', ascending: false)
          .range(
            _currentPage * _pageSize,
            (_currentPage + 1) * _pageSize - 1,
          );

      _orders = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // DISPUTES
  // =========================
  Future<void> loadDisputes({bool refresh = false}) async {
    if (!_isAdmin) return;

    if (refresh) {
      _currentPage = 0;
      _disputes.clear();
    }

    _setLoading(true);

    try {
      final data = await _supabase
          .from('disputes')
          .select('*, order:orders(id, total), user:users(name)')
          .order('created_at', ascending: false)
          .range(
            _currentPage * _pageSize,
            (_currentPage + 1) * _pageSize - 1,
          );

      _disputes = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      _error = e.toString();
    }

    _setLoading(false);
  }

  // =========================
  // PAGINATION
  // =========================
  void nextPage() {
    _currentPage++;
    notifyListeners();
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _searchQuery = value;
    _currentPage = 0;
    notifyListeners();
  }

  void setStatus(String value) {
    _statusFilter = value;
    _currentPage = 0;
    notifyListeners();
  }

  // =========================
  // HELPERS
  // =========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// =========================
// DASHBOARD MODEL
// =========================
class DashboardStats {
  final int totalUsers;
  final int totalShops;
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;

  DashboardStats({
    required this.totalUsers,
    required this.totalShops,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalRevenue,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalUsers: 0,
      totalShops: 0,
      totalProducts: 0,
      totalOrders: 0,
      totalRevenue: 0,
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['total_users'] ?? 0,
      totalShops: json['total_shops'] ?? 0,
      totalProducts: json['total_products'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}
