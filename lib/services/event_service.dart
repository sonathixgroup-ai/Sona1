// lib/services/event_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';

import '../models/event_model.dart';

class EventService {
  final SupabaseClient _supabase;
<<<<<<< Updated upstream
=======
  // Prefer the Admin-published tables so "Admin → App" is synchronized.
  static const String eventsTable = 'thix_events';
  static const String eventsStatusView = 'thix_events_status';
  static const String registrationsTable = 'thix_event_registrations';
  static const String promoCodesTable = 'thix_event_promo_codes';

  // Legacy tables (some older deployments used these names).
  static const String _legacyEventsTable = 'events';
  static const String _legacyRegistrationsTable = 'event_registrations';
  static const String _legacyPromoCodesTable = 'event_promo_codes';
>>>>>>> Stashed changes

  EventService(this._supabase);

<<<<<<< Updated upstream
  String get currentUserId => _supabase.auth.currentUser?.id ?? '';

  // ============================================================
  // LECTURE DES ÉVÉNEMENTS
  // ============================================================

  Future<List<Event>> getEvents({
    String? category,
    String? dateFilter,
    String? city,
    int limit = 50,
=======
  // ==================== EVENTS ====================
  Future<EventItem?> getEventById(String eventId) async {
    try {
      // Prefer view if available.
      final row = await _supabase.from(eventsStatusView).select('*').eq('id', eventId).maybeSingle();
      if (row != null) return _mapThixEventRow(row);

      final data = await _supabase.from(eventsTable).select('*').eq('id', eventId).maybeSingle();
      if (data != null) return _mapThixEventRow(data);
      return null;
    } catch (e) {
      debugPrint('getEventById error: $e');
      // Legacy fallback.
      try {
        final data = await _supabase.from(_legacyEventsTable).select().eq('id', eventId).single();
        return EventItem.fromJson((data as Map).cast<String, dynamic>());
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<EventItem>> getAllEvents() async {
    try {
      // Prefer status view (contains computed fields).
      try {
        final data = await _supabase
            .from(eventsStatusView)
            .select('*')
            .eq('status', 'published')
            .order('starts_at');
        if (data is List) {
          return data
              .map((e) => _mapThixEventRow((e as Map).cast<String, dynamic>()))
              .where((e) => e.id.trim().isNotEmpty)
              .toList(growable: false);
        }
      } catch (e) {
        debugPrint('getAllEvents view fallback err=$e');
      }

      final data = await _supabase
          .from(eventsTable)
          .select('*')
          .eq('status', 'published')
          .order('starts_at');
      if (data is! List) return const [];
      return data
          .map((e) => _mapThixEventRow((e as Map).cast<String, dynamic>()))
          .where((e) => e.id.trim().isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      debugPrint('getAllEvents error: $e');
      // Legacy fallback.
      try {
        final data = await _supabase.from(_legacyEventsTable).select().order('starts_at');
        if (data is! List) return const [];
        return data
            .map((e) => EventItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false);
      } catch (_) {
        return const [];
      }
    }
  }

  // ==================== REGISTRATIONS ====================
  Future<bool> hasUserTicket(String userId, String eventId) async {
    try {
      final res = await _supabase.from(registrationsTable).select('id').eq('user_id', userId).eq('event_id', eventId).limit(1);
      return res.isNotEmpty;
    } catch (_) {
      try {
        final res = await _supabase
            .from(_legacyRegistrationsTable)
            .select('id')
            .eq('user_id', userId)
            .eq('event_id', eventId)
            .limit(1);
        return (res is List) && res.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
  }

  Future<bool> registerForEvent({required String userId, required String eventId}) async {
    try {
      await _supabase.from(registrationsTable).insert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'confirmed',
      });
      return true;
    } catch (e) {
      debugPrint('registerForEvent error: $e');
      try {
        await _supabase.from(_legacyRegistrationsTable).insert({
          'user_id': userId,
          'event_id': eventId,
          'status': 'confirmed',
        });
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<EventRegistration?> createRegistration({
    required String userId,
    required String eventId,
    Map<String, dynamic>? metadata,
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
      debugPrint('❌ Error getEvents: $e');
      return [];
=======
      debugPrint('createRegistration error: $e');
      try {
        final res = await _supabase.from(_legacyRegistrationsTable).insert({
          'user_id': userId,
          'event_id': eventId,
          'status': 'confirmed',
          'metadata': metadata ?? {},
        }).select().single();
        return EventRegistration.fromJson((res as Map).cast<String, dynamic>());
      } catch (_) {
        return null;
      }
    }
  }

  Future<EventRegistration?> getRegistrationById(String registrationId) async {
    try {
      final data = await _supabase.from(registrationsTable).select().eq('id', registrationId).single();
      return EventRegistration.fromJson(data);
    } catch (e) {
      debugPrint('getRegistrationById error: $e');
      try {
        final data = await _supabase.from(_legacyRegistrationsTable).select().eq('id', registrationId).single();
        return EventRegistration.fromJson((data as Map).cast<String, dynamic>());
      } catch (_) {
        return null;
      }
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    try {
      await _supabase.from(registrationsTable).update({'status': 'cancelled'}).eq('id', registrationId);
      return true;
    } catch (e) {
      debugPrint('cancelRegistration error: $e');
      try {
        await _supabase.from(_legacyRegistrationsTable).update({'status': 'cancelled'}).eq('id', registrationId);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<List<EventRegistration>> getUserRegistrations(String userId) async {
    try {
      final data = await _supabase.from(registrationsTable).select().eq('user_id', userId).order('created_at', ascending: false);
      return (data as List).map((e) => EventRegistration.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getUserRegistrations error: $e');
      try {
        final data = await _supabase.from(_legacyRegistrationsTable).select().eq('user_id', userId).order('created_at', ascending: false);
        if (data is! List) return const [];
        return data.map((e) => EventRegistration.fromJson((e as Map).cast<String, dynamic>())).toList(growable: false);
      } catch (_) {
        return const [];
      }
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
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
=======
      // Soft-fail if table doesn't exist / RLS blocks.
      debugPrint('validatePromoCode error: $e');
      try {
        final row = await _supabase
            .from(_legacyPromoCodesTable)
            .select('discount_percent,active,expires_at,event_id,code')
            .eq('code', c)
            .maybeSingle();
        if (row == null) return null;
        final active = (row['active'] as bool?) ?? true;
        if (!active) return null;
        final rowEventId = (row['event_id'] ?? '').toString();
        if (rowEventId.isNotEmpty && rowEventId != eventId) return null;
        final expiresRaw = row['expires_at'];
        if (expiresRaw != null) {
          final expires = DateTime.tryParse(expiresRaw.toString());
          if (expires != null && expires.isBefore(DateTime.now().toUtc())) return null;
        }
        return (row['discount_percent'] as num?)?.toDouble();
      } catch (_) {
        return null;
      }
    }
  }

  EventItem _mapThixEventRow(Map<String, dynamic> row) {
    final id = (row['id'] ?? '').toString();
    final title = (row['title'] ?? 'Sans titre').toString();
    final description = (row['description'] ?? row['quick_hook'] ?? '').toString();
    final category = (row['category'] ?? '').toString();
    final place = (row['place'] ?? row['location'] ?? '').toString();
    final startsAt = DateTime.tryParse((row['starts_at'] ?? '').toString());
    final maxParticipants = (row['max_participants'] as num?)?.toInt();
    final currentParticipants = (row['registrations_count'] as num?)?.toInt() ?? (row['current_participants'] as num?)?.toInt();
    final isActive = (row['status']?.toString() ?? 'published') == 'published';
    final isFree = row['is_free'];
    final price = (row['price'] as num?)?.toDouble();
    final priceLabel = (isFree == true) ? 'Gratuit' : (price == null ? null : '${price.toString()}');

    // If your schema stores cover in bucket/path, the app can resolve it in the UI.
    // We still map any direct URL if present.
    final imageUrl = (row['image_url'] ?? row['cover_url'] ?? row['coverImageUrl'] ?? '').toString();

    return EventItem(
      id: id,
      title: title,
      description: description,
      category: category.isEmpty ? null : category,
      location: place.isEmpty ? null : place,
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants,
      isActive: isActive,
      imageUrl: imageUrl.isEmpty ? null : imageUrl,
      price: price,
      priceLabel: priceLabel,
      startsAt: startsAt,
    );
  }
>>>>>>> Stashed changes
}
