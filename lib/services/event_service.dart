// lib/services/event_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';

import '../models/event_model.dart';

class EventService {
  final SupabaseClient _supabase;

  EventService(this._supabase);

  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ============================================================
  // LECTURE DES ÉVÉNEMENTS
  // ============================================================

  Future<List<Event>> getEvents({
    String? category,
    String? dateFilter,
    String? city,
    int limit = 50,
  }) async {
    try {
      debugPrint('📅 getEvents: chargement des événements...');
      
      final response = await _supabase.from('events').select('*');
      List<dynamic> results = response as List;
      
      debugPrint('📅 getEvents: ${results.length} événements bruts');
      
      // ✅ CORRIGÉ: Filtrer par statut 'upcoming' par défaut
      // Ne montrer que les événements à venir + ceux en cours
      final now = DateTime.now();
      results = results.where((e) => 
        e['status'] == 'upcoming' && 
        DateTime.parse(e['start_date']).isAfter(now.subtract(const Duration(hours: 1)))
      ).toList();
      
      debugPrint('📅 getEvents: ${results.length} événements à venir');
      
      // Filtre par catégorie
      if (category != null && category != 'all' && category != 'featured') {
        results = results.where((e) => e['category'] == category).toList();
        debugPrint('📅 getEvents: ${results.length} après filtre catégorie $category');
      }
      
      // Filtre par date
      if (dateFilter == 'today') {
        results = results.where((e) => 
          DateTime.parse(e['start_date']).day == now.day &&
          DateTime.parse(e['start_date']).month == now.month &&
          DateTime.parse(e['start_date']).year == now.year
        ).toList();
        debugPrint('📅 getEvents: ${results.length} événements aujourd\'hui');
      } else if (dateFilter == 'week') {
        final weekLater = now.add(const Duration(days: 7));
        results = results.where((e) => 
          DateTime.parse(e['start_date']).isAfter(now) &&
          DateTime.parse(e['start_date']).isBefore(weekLater)
        ).toList();
        debugPrint('📅 getEvents: ${results.length} événements cette semaine');
      } else if (dateFilter == 'month') {
        results = results.where((e) => 
          DateTime.parse(e['start_date']).month == now.month &&
          DateTime.parse(e['start_date']).year == now.year
        ).toList();
        debugPrint('📅 getEvents: ${results.length} événements ce mois');
      }
      
      // Filtre par ville
      if (city != null && city != 'all') {
        results = results.where((e) => e['city'] == city).toList();
        debugPrint('📅 getEvents: ${results.length} événements à $city');
      }
      
      // Tri par date (du plus proche au plus lointain)
      results.sort((a, b) => DateTime.parse(a['start_date']).compareTo(DateTime.parse(b['start_date'])));
      
      // Limite
      results = results.take(limit).toList();
      
      final events = <Event>[];
      for (var e in results) {
        final isLiked = await _isEventLiked(e['id']);
        final isSaved = await _isEventSaved(e['id']);
        
        events.add(Event.fromJson({
          ...e,
          'is_liked': isLiked,
          'is_saved': isSaved,
        }));
      }
      
      debugPrint('✅ getEvents: ${events.length} événements retournés');
      return events;
    } catch (e) {
      debugPrint('❌ Error getEvents: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer les événements populaires
  Future<List<Event>> getPopularEvents({int limit = 10}) async {
    try {
      final response = await _supabase.from('events').select('*');
      List<dynamic> results = response as List;
      
      final now = DateTime.now();
      results = results.where((e) => 
        e['status'] == 'upcoming' && 
        DateTime.parse(e['start_date']).isAfter(now)
      ).toList();
      
      // Trier par nombre de vues
      results.sort((a, b) => (b['views_count'] ?? 0).compareTo(a['views_count'] ?? 0));
      
      results = results.take(limit).toList();
      
      final events = <Event>[];
      for (var e in results) {
        final isLiked = await _isEventLiked(e['id']);
        events.add(Event.fromJson({
          ...e,
          'is_liked': isLiked,
        }));
      }
      
      return events;
    } catch (e) {
      debugPrint('❌ Error getPopularEvents: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE: Récupérer les événements récents
  Future<List<Event>> getRecentEvents({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('status', 'upcoming')
          .order('created_at', ascending: false)
          .limit(limit);
      
      final events = <Event>[];
      for (var e in response as List) {
        final isLiked = await _isEventLiked(e['id']);
        events.add(Event.fromJson({
          ...e,
          'is_liked': isLiked,
        }));
      }
      
      return events;
    } catch (e) {
      debugPrint('❌ Error getRecentEvents: $e');
      return [];
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('id', eventId)
          .maybeSingle();

      if (response == null) return null;

      final isLiked = await _isEventLiked(eventId);
      final isSaved = await _isEventSaved(eventId);

      return Event.fromJson({
        ...response,
        'is_liked': isLiked,
        'is_saved': isSaved,
      });
    } catch (e) {
      debugPrint('❌ Error getEventById: $e');
      return null;
    }
  }

  Future<List<Event>> getFeaturedEvents() async {
    try {
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('is_featured', true)
          .eq('status', 'upcoming')
          .gte('start_date', DateTime.now().toIso8601String())
          .order('start_date', ascending: true)
          .limit(10);
      
      final events = <Event>[];
      for (var e in response as List) {
        final isLiked = await _isEventLiked(e['id']);
        events.add(Event.fromJson({
          ...e,
          'is_liked': isLiked,
        }));
      }
      
      debugPrint('⭐ getFeaturedEvents: ${events.length} événements à la une');
      return events;
    } catch (e) {
      debugPrint('❌ Error getFeaturedEvents: $e');
      return [];
    }
  }

  Future<List<Event>> getEventsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('category', category)
          .eq('status', 'upcoming')
          .gte('start_date', DateTime.now().toIso8601String())
          .order('start_date', ascending: true)
          .limit(20);
      
      final events = <Event>[];
      for (var e in response as List) {
        final isLiked = await _isEventLiked(e['id']);
        events.add(Event.fromJson({
          ...e,
          'is_liked': isLiked,
        }));
      }
      
      return events;
    } catch (e) {
      debugPrint('❌ Error getEventsByCategory: $e');
      return [];
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('status', 'upcoming')
          .or('title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%')
          .order('start_date', ascending: true)
          .limit(50);
      
      return (response as List).map((e) => Event.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ Error searchEvents: $e');
      return [];
    }
  }

  // ============================================================
  // INTERACTIONS (Likes, Vues, Favoris)
  // ============================================================

  Future<void> incrementViews(String eventId) async {
    try {
      final event = await _supabase
          .from('events')
          .select('views_count')
          .eq('id', eventId)
          .maybeSingle();
      
      if (event == null) return;
      
      final currentViews = event['views_count'] ?? 0;
      await _supabase
          .from('events')
          .update({'views_count': currentViews + 1})
          .eq('id', eventId);
    } catch (e) {
      debugPrint('❌ Error incrementViews: $e');
    }
  }

  Future<bool> _isEventLiked(String eventId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return false;

    try {
      final response = await _supabase
          .from('event_favorites')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> likeEvent(String eventId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;

    final exists = await _isEventLiked(eventId);
    if (!exists) {
      await _supabase.from('event_favorites').insert({
        'event_id': eventId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Incrémenter le compteur de likes
      await _supabase.rpc('increment_event_likes', params: {'event_id': eventId});
    }
  }

  Future<void> unlikeEvent(String eventId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return;

    await _supabase
        .from('event_favorites')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', currentUserId);
    
    // Décrémenter le compteur de likes
    await _supabase.rpc('decrement_event_likes', params: {'event_id': eventId});
  }

  Future<bool> _isEventSaved(String eventId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return false;

    try {
      final response = await _supabase
          .from('event_favorites')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', currentUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<Event>> getFavoriteEvents() async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return [];

    try {
      final response = await _supabase
          .from('event_favorites')
          .select('event:event_id(*)')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      final events = <Event>[];
      for (var e in response as List) {
        events.add(Event.fromJson({
          ...e['event'],
          'is_liked': true,
        }));
      }
      return events;
    } catch (e) {
      debugPrint('❌ Error getFavoriteEvents: $e');
      return [];
    }
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
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Utilisateur non connecté');

    try {
      final ticketCode = _generateTicketCode();
      
      final response = await _supabase.from('event_bookings').insert({
        'event_id': eventId,
        'user_id': currentUserId,
        'ticket_quantity': quantity,
        'total_price': totalPrice,
        'payment_method': paymentMethod,
        'payment_status': 'paid',
        'ticket_code': ticketCode,
        'qr_code': ticketCode,
        'status': 'confirmed',
        'booking_date': DateTime.now().toIso8601String(),
      }).select().single();
      
      // Mettre à jour les places restantes
      final event = await getEventById(eventId);
      if (event != null && event.remainingTickets != null) {
        await _supabase
            .from('events')
            .update({'remaining_tickets': event.remainingTickets! - quantity})
            .eq('id', eventId);
      }
      
      debugPrint('🎫 bookTicket: Ticket créé pour $quantity places');
      return EventBooking.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error bookTicket: $e');
      return null;
    }
  }

  Future<List<EventBooking>> getMyTickets() async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) return [];

    try {
      final response = await _supabase
          .from('event_bookings')
          .select('*, events:event_id(title, image_url, start_date, location)')
          .eq('user_id', currentUserId)
          .order('booking_date', ascending: false);

      final bookings = <EventBooking>[];
      for (var e in response as List) {
        final event = e['events'];
        if (event != null) {
          bookings.add(EventBooking.fromJson({
            ...e,
            'event_title': event['title'],
            'event_image_url': event['image_url'],
            'event_date': event['start_date'],
            'event_location': event['location'],
          }));
        }
      }
      return bookings;
    } catch (e) {
      debugPrint('❌ Error getMyTickets: $e');
      return [];
    }
  }

  String _generateTicketCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return 'THIX-' + String.fromCharCodes(
      Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  // ============================================================
  // ADMIN - CRUD
  // ============================================================

  Future<Event> createEvent({
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
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Admin non connecté');

    debugPrint('📝 createEvent: Création de l\'événement "$title"');
    
    final now = DateTime.now().toIso8601String();
    final startDateStr = startDate.toIso8601String();
    
    final response = await _supabase.from('events').insert({
      'title': title,
      'description': description,
      'category': category,
      'start_date': startDateStr,
      'location': location,
      'city': city,
      'address': address,
      'price': price,
      'is_free': isFree,
      'capacity': capacity,
      'remaining_tickets': capacity,
      'image_url': imageUrl,
      'is_featured': isFeatured,
      'status': startDate.isAfter(DateTime.now()) ? 'upcoming' : 'ongoing',
      'organizer_id': currentUserId,
      'created_at': now,
      'updated_at': now,
      'views_count': 0,
      'likes_count': 0,
    }).select().single();

    debugPrint('✅ createEvent: Événement créé avec ID ${response['id']}');
    return Event.fromJson(response);
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Admin non connecté');

    await _supabase
        .from('events')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    final currentUserId = this.currentUserId;
    if (currentUserId.isEmpty) throw Exception('Admin non connecté');

    await _supabase.from('events').delete().eq('id', eventId);
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  Future<String?> uploadImage(String filePath) async {
    try {
      final currentUserId = this.currentUserId;
      if (currentUserId.isEmpty) return null;

      final file = File(filePath);
      final bytes = await file.readAsBytes();
      
      final extension = filePath.split('.').last;
      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = 'events/$fileName';
      
      await _supabase.storage
          .from('event_images')
          .uploadBinary(storagePath, bytes);
      
      return _supabase.storage.from('event_images').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final response = await _supabase.from('events').select('*');
      final List<dynamic> events = response as List;
      
      final totalEvents = events.length;
      final now = DateTime.now();
      final upcomingEvents = events.where((e) => 
        e['status'] == 'upcoming' && 
        DateTime.parse(e['start_date']).isAfter(now)
      ).length;
      
      int totalViews = 0;
      int totalLikes = 0;
      for (var e in events) {
        totalViews += e['views_count'] as int? ?? 0;
        totalLikes += e['likes_count'] as int? ?? 0;
      }
      
      // ✅ CORRIGÉ: Retourner un Map non-nullable
      return {
        'total_events': totalEvents,
        'upcoming_events': upcomingEvents,
        'total_views': totalViews,
        'total_likes': totalLikes,
      };
    } catch (e) {
      debugPrint('❌ Error getAdminStats: $e');
      return {
        'total_events': 0,
        'upcoming_events': 0,
        'total_views': 0,
        'total_likes': 0,
      };
    }
  }

  // ============================================================
  // VÉRIFICATION DE CONNEXION
  // ============================================================

  Future<bool> checkConnection() async {
    try {
      await _supabase.from('events').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('❌ Connection check failed: $e');
      return false;
    }
  }
}
