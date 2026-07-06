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

  // ✅ Nouvelle méthode reset()
  void reset() {
    _searchResults.clear();
    _currentFilters = {};
    _currentPage = 0;
    _hasMore = true;
    _lastQuery = null;
    _totalResults = 0;
    // Ne pas toucher aux recherches récentes pour les conserver
    notifyListeners();
  }

  // ... le reste du code inchangé ...
  
  Future<void> loadRecentSearches() async {
    // ... (tel que dans votre code)
  }

  Future<void> searchProducts(String query, {bool refresh = false}) async {
    // ... (tel que dans votre code)
  }

  Future<void> searchNearby(double lat, double lng, double radiusKm) async {
    // ...
  }

  void applyFilters(Map<String, dynamic> filters) {
    // ...
  }

  void clearFilters() {
    // ...
  }

  void clearRecentSearches() async {
    // ...
  }

  void removeRecentSearch(String query) async {
    // ...
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
