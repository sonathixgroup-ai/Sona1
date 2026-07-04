import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _announcements = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic> _stats = const {};
  bool _isLoading = false;
  bool _isLoadingOrders = false;

  List<Map<String, dynamic>> get announcements => _announcements;
  List<Map<String, dynamic>> get orders => _orders;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingOrders => _isLoadingOrders;

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
      _stats = const {};
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }
}
