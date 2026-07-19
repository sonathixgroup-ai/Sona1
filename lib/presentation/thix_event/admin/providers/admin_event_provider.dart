// lib/presentation/thix_event/admin/providers/admin_event_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:thix_id/presentation/thix_event/models/event_model.dart';
import '../core/admin_constants.dart';
import '../services/admin_event_service.dart';
import 'admin_state.dart';
import 'admin_stats_model.dart';

class AdminEventProvider extends ChangeNotifier {
  final AdminEventService _service;

  AdminEventProvider(this._service);

  AdminStats _stats = AdminStats.empty();
  AdminStats get stats => _stats;
  bool _statsLoading = false;
  bool get statsLoading => _statsLoading;

  Future<void> loadDashboardStats() async {
    if (_statsLoading) return;
    _statsLoading = true;
    notifyListeners();
    try {
      _stats = await _service.getDashboardStats();
    } catch (e) {
      debugPrint('❌ Stats error: $e');
    } finally {
      _statsLoading = false;
      notifyListeners();
    }
  }

  AdminPaginatedState<Event> _eventsState = const AdminPaginatedState<Event>();
  AdminPaginatedState<Event> get eventsState => _eventsState;

  String _searchQuery = '';
  String _categoryFilter = 'all';
  Timer? _debounce;

  final Map<String, List<Event>> _cache = {};
  DateTime? _lastCacheTime;

  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < AdminConstants.cacheDuration;
  }

  Future<void> loadEvents({bool refresh = false}) async {
    if (refresh) {
      _eventsState = const AdminPaginatedState<Event>();
      _cache.clear();
    }
    if (_eventsState.isLoading) return;

    _eventsState = _eventsState.copyWith(status: AdminStatus.loading);
    notifyListeners();

    try {
      final cacheKey = '${_searchQuery}_${_categoryFilter}_0';
      List<Event> events;

      if (!refresh && _cache.containsKey(cacheKey) && _isCacheValid()) {
        events = _cache[cacheKey]!;
      } else {
        events = await _service.getEventsPaginated(
          page: 0,
          pageSize: AdminConstants.eventsPageSize,
          search: _searchQuery,
          category: _categoryFilter == 'all' ? null : _categoryFilter,
        );
        _cache[cacheKey] = events;
        _lastCacheTime = DateTime.now();
      }

      _eventsState = AdminPaginatedState<Event>(
        items: events,
        status: events.isEmpty ? AdminStatus.empty : AdminStatus.success,
        hasMore: events.length == AdminConstants.eventsPageSize,
        currentPage: 0,
      );
    } catch (e) {
      _eventsState = _eventsState.copyWith(status: AdminStatus.error, error: e.toString());
    }
    notifyListeners();
  }

  Future<void> loadMoreEvents() async {
    if (!_eventsState.hasMore || _eventsState.isLoadingMore || _eventsState.isLoading) return;

    _eventsState = _eventsState.copyWith(status: AdminStatus.loadingMore);
    notifyListeners();

    try {
      final nextPage = _eventsState.currentPage + 1;
      final newEvents = await _service.getEventsPaginated(
        page: nextPage,
        pageSize: AdminConstants.eventsPageSize,
        search: _searchQuery,
        category: _categoryFilter == 'all' ? null : _categoryFilter,
      );

      _eventsState = _eventsState.copyWith(
        items: [..._eventsState.items, ...newEvents],
        status: AdminStatus.success,
        hasMore: newEvents.length == AdminConstants.eventsPageSize,
        currentPage: nextPage,
      );
    } catch (e) {
      _eventsState = _eventsState.copyWith(status: AdminStatus.error, error: e.toString());
    }
    notifyListeners();
  }

  void searchEvents(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchQuery = query.trim();
      loadEvents(refresh: true);
    });
  }

  void filterByCategory(String category) {
    _categoryFilter = category;
    loadEvents(refresh: true);
  }

  Future<bool> deleteEvent(String id) async {
    final oldList = List<Event>.from(_eventsState.items);
    _eventsState = _eventsState.copyWith(items: oldList.where((e) => e.id != id).toList());
    notifyListeners();

    try {
      await _service.deleteEvent(id);
      _cache.clear();
      loadDashboardStats();
      return true;
    } catch (e) {
      _eventsState = _eventsState.copyWith(items: oldList);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleFeatured(String id, bool isFeatured) async {
    final index = _eventsState.items.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final old = _eventsState.items[index];
    _eventsState = AdminPaginatedState<Event>(
      items: List<Event>.from(_eventsState.items)..[index] = old.copyWith(isFeatured: isFeatured),
      status: _eventsState.status,
      hasMore: _eventsState.hasMore,
      currentPage: _eventsState.currentPage,
    );
    notifyListeners();

    try {
      await _service.updateEventField(id, {'is_featured': isFeatured});
      return true;
    } catch (_) {
      _eventsState = AdminPaginatedState<Event>(
        items: List<Event>.from(_eventsState.items)..[index] = old,
        status: _eventsState.status,
        hasMore: _eventsState.hasMore,
        currentPage: _eventsState.currentPage,
      );
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
