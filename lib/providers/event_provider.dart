// lib/providers/event_provider.dart
import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../models/event_model.dart';

class EventProvider extends ChangeNotifier {
  final EventService _eventService;

  List<Event> _events = [];
  List<Event> _featuredEvents = [];
  List<Event> _favoriteEvents = [];
  List<EventBooking> _myTickets = [];
  bool _isLoading = false;
  String? _error;
  String _currentCategory = 'all';
  String _currentDateFilter = 'all';
  String _currentCity = 'all';

  EventProvider(this._eventService);

  // ============================================================
  // GETTERS
  // ============================================================

  List<Event> get events => _events;
  List<Event> get featuredEvents => _featuredEvents;
  List<Event> get favoriteEvents => _favoriteEvents;
  List<EventBooking> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;
  String get currentDateFilter => _currentDateFilter;
  String get currentCity => _currentCity;

  Event? get featuredEvent {
    return _featuredEvents.isNotEmpty ? _featuredEvents.first : null;
  }

  List<Event> get upcomingEvents {
    return _events.where((e) => e.isUpcoming && !e.isPastEvent).take(10).toList();
  }

  List<Event> get recommendedEvents {
    return _events.where((e) => e.isFeatured || e.isUpcoming).take(4).toList();
  }

  // ============================================================
  // CHARGEMENT DES DONNÉES
  // ============================================================

  Future<void> fetchEvents({
    String? category,
    String? dateFilter,
    String? city,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newCategory = category ?? _currentCategory;
      final newDateFilter = dateFilter ?? _currentDateFilter;
      final newCity = city ?? _currentCity;
      
      _currentCategory = newCategory;
      _currentDateFilter = newDateFilter;
      _currentCity = newCity;
      
      _events = await _eventService.getEvents(
        category: newCategory != 'all' ? newCategory : null,
        dateFilter: newDateFilter,
        city: newCity != 'all' ? newCity : null,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ fetchEvents error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeaturedEvents() async {
    try {
      _featuredEvents = await _eventService.getFeaturedEvents();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ fetchFeaturedEvents error: $e');
    }
  }

  Future<Event?> fetchEventById(String id) async {
    try {
      return await _eventService.getEventById(id);
    } catch (e) {
      debugPrint('❌ fetchEventById error: $e');
      return null;
    }
  }

  Future<List<Event>> fetchEventsByCategory(String category) async {
    try {
      return await _eventService.getEventsByCategory(category);
    } catch (e) {
      debugPrint('❌ fetchEventsByCategory error: $e');
      return [];
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    try {
      return await _eventService.searchEvents(query);
    } catch (e) {
      debugPrint('❌ searchEvents error: $e');
      return [];
    }
  }

  // ============================================================
  // INTERACTIONS
  // ============================================================

  Future<void> incrementViews(String eventId) async {
    await _eventService.incrementViews(eventId);
  }

  Future<void> toggleLike(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      if (event.isLiked) {
        await _eventService.unlikeEvent(eventId);
        _events[index] = event.copyWith(isLiked: false);
      } else {
        await _eventService.likeEvent(eventId);
        _events[index] = event.copyWith(isLiked: true);
      }
      notifyListeners();
    }
    
    // Mettre à jour dans les favoris
    await loadFavoriteEvents();
  }

  Future<void> likeEvent(String eventId) async {
    await _eventService.likeEvent(eventId);
    await loadFavoriteEvents();
  }

  Future<void> unlikeEvent(String eventId) async {
    await _eventService.unlikeEvent(eventId);
    await loadFavoriteEvents();
  }

  Future<bool> isEventLiked(String eventId) async {
    final favorites = await getFavoriteEvents();
    return favorites.any((e) => e.id == eventId);
  }

  Future<List<Event>> getFavoriteEvents() async {
    try {
      _favoriteEvents = await _eventService.getFavoriteEvents();
      notifyListeners();
      return _favoriteEvents;
    } catch (e) {
      debugPrint('❌ getFavoriteEvents error: $e');
      return [];
    }
  }

  Future<void> loadFavoriteEvents() async {
    await getFavoriteEvents();
  }

  // ============================================================
  // RÉSERVATION
  // ============================================================

  Future<EventBooking?> bookTicket({
    required String eventId,
    required int quantity,
    required double totalPrice,
    String? paymentMethod,
  }) async {
    try {
      final booking = await _eventService.bookTicket(
        eventId: eventId,
        quantity: quantity,
        totalPrice: totalPrice,
        paymentMethod: paymentMethod,
      );
      
      if (booking != null) {
        await loadMyTickets();
        await fetchEvents(); // Rafraîchir pour mettre à jour les places
      }
      
      return booking;
    } catch (e) {
      debugPrint('❌ bookTicket error: $e');
      return null;
    }
  }

  Future<void> loadMyTickets() async {
    try {
      _myTickets = await _eventService.getMyTickets();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadMyTickets error: $e');
    }
  }

  Future<List<EventBooking>> getMyTickets() async {
    try {
      return await _eventService.getMyTickets();
    } catch (e) {
      debugPrint('❌ getMyTickets error: $e');
      return [];
    }
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<Event?> createEvent({
    required String title,
    required String description,
    required String category,
    required DateTime startDate,
    required String location,
    double price = 0,
    bool isFree = false,
    int? capacity,
    String? imageUrl,
    String? city,
    String? address,
    bool isFeatured = false,
  }) async {
    try {
      final event = await _eventService.createEvent(
        title: title,
        description: description,
        category: category,
        startDate: startDate,
        location: location,
        price: price,
        isFree: isFree,
        capacity: capacity,
        imageUrl: imageUrl,
        city: city,
        address: address,
        isFeatured: isFeatured,
      );
      
      await fetchEvents();
      await fetchFeaturedEvents();
      
      return event;
    } catch (e) {
      debugPrint('❌ createEvent error: $e');
      return null;
    }
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    try {
      await _eventService.updateEvent(eventId, data);
      await fetchEvents();
      await fetchFeaturedEvents();
    } catch (e) {
      debugPrint('❌ updateEvent error: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventService.deleteEvent(eventId);
      await fetchEvents();
      await fetchFeaturedEvents();
    } catch (e) {
      debugPrint('❌ deleteEvent error: $e');
    }
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<String?> uploadImage(String filePath) async {
    return await _eventService.uploadImage(filePath);
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Future<Map<String, dynamic>> getAdminStats() async {
    return await _eventService.getAdminStats();
  }

  // ============================================================
  // FILTRES
  // ============================================================

  void setCategory(String category) {
    if (_currentCategory == category) return;
    _currentCategory = category;
    fetchEvents(category: category);
  }

  void setDateFilter(String filter) {
    if (_currentDateFilter == filter) return;
    _currentDateFilter = filter;
    fetchEvents(dateFilter: filter);
  }

  void setCity(String city) {
    if (_currentCity == city) return;
    _currentCity = city;
    fetchEvents(city: city);
  }

  void resetFilters() {
    _currentCategory = 'all';
    _currentDateFilter = 'all';
    _currentCity = 'all';
    fetchEvents();
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    fetchEvents();
    fetchFeaturedEvents();
    loadFavoriteEvents();
    loadMyTickets();
  }
}
