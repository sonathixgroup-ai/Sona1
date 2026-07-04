import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SearchProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _searchResults = [];
  List<String> _recentSearches = [];
  Map<String, dynamic> _currentFilters = {};
  bool _isLoading = false;
  int _totalResults = 0;
  int _currentPage = 0;
  bool _hasMore = true;
  String? _lastQuery;

  List<Map<String, dynamic>> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  Map<String, dynamic> get currentFilters => _currentFilters;
  bool get isLoading => _isLoading;
  int get totalResults => _totalResults;
  bool get hasMore => _hasMore;

  Future<void> loadRecentSearches() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      final response = await _supabase
          .from('search_history')
          .select('query')
          .eq('user_id', userId)
          .order('searched_at', ascending: false)
          .limit(10);
      _recentSearches = response.map<String>((e) => e['query'] as String).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  Future<void> searchProducts(String query, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _searchResults.clear();
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;
    
    _setLoading(true);
    _lastQuery = query;
    
    try {
      // Save to search history
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null && query.isNotEmpty) {
        await _supabase.from('search_history').upsert({
          'user_id': userId,
          'query': query,
          'searched_at': DateTime.now().toIso8601String(),
        });
        await loadRecentSearches();
      }
      
      var request = _supabase
          .from('products')
          .select('*, shop:shops(name, rating)', count: CountOption.exact)
          .eq('status', 'active')
          .ilike('title', '%$query%')
          .range(_currentPage * 20, (_currentPage + 1) * 20 - 1);
      
      // Apply filters
      if (_currentFilters['min_price'] != null) {
        request = request.gte('price', _currentFilters['min_price']);
      }
      if (_currentFilters['max_price'] != null) {
        request = request.lte('price', _currentFilters['max_price']);
      }
      if (_currentFilters['min_rating'] != null) {
        request = request.gte('rating', _currentFilters['min_rating']);
      }
      if (_currentFilters['condition'] != null) {
        request = request.eq('condition', _currentFilters['condition']);
      }
      if (_currentFilters['free_shipping'] == true) {
        request = request.eq('free_shipping', true);
      }
      if (_currentFilters['verified_sellers'] == true) {
        request = request.eq('shop.is_verified', true);
      }
      
      final response = await request;
      final newResults = List<Map<String, dynamic>>.from(response);
      
      setState(() {
        if (newResults.length < 20) _hasMore = false;
        _searchResults.addAll(newResults);
        _currentPage++;
        _totalResults = response.count ?? 0;
      });
    } catch (e) {
      debugPrint('Error searching products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchNearby(double lat, double lng, double radiusKm) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .rpc('nearby_products', params: {
            'lat': lat,
            'lng': lng,
            'radius_km': radiusKm,
            'limit': 50,
          });
      _searchResults = List<Map<String, dynamic>>.from(response);
      _totalResults = _searchResults.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching nearby: $e');
    } finally {
      _setLoading(false);
    }
  }

  void applyFilters(Map<String, dynamic> filters) {
    _currentFilters = filters;
    _currentPage = 0;
    _searchResults.clear();
    _hasMore = true;
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      searchProducts(_lastQuery!);
    }
  }

  void clearFilters() {
    _currentFilters = {};
    _currentPage = 0;
    _searchResults.clear();
    _hasMore = true;
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      searchProducts(_lastQuery!);
    }
  }

  void clearRecentSearches() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.from('search_history').delete().eq('user_id', userId);
      _recentSearches.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  void removeRecentSearch(String query) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase
          .from('search_history')
          .delete()
          .match({'user_id': userId, 'query': query});
      _recentSearches.remove(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing recent search: $e');
    }
  }

  void setState(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
