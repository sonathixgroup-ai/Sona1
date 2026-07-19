// lib/services/event_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data'; // REMPLACE dart:io pour la compatibilité Web
import 'dart:math';
import '../models/event_booking.dart';
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

      final now = DateTime.now();
      results = results.where((e) {
        final status = (e['status'] ?? '').toString();
        final startDate = DateTime.tryParse((e['start_date'] ?? '').toString());
        return status == 'upcoming' &&
            startDate != null &&
            startDate.isAfter(now.subtract(const Duration(hours: 1)));
      }).toList();

      debugPrint('📅 getEvents: ${results.length} événements à venir');

      if (category != null && category != 'all' && category != 'featured') {
        results = results.where((e) => e['category'] == category).toList();
        debugPrint('📅 getEvents: ${results.length} après filtre catégorie $category');
      }

      if (dateFilter == 'today') {
        results = results.where((e) {
          final d = DateTime.tryParse((e['start_date'] ?? '').toString());
          if (d == null) return false;
          return d.day == now.day && d.month == now.month && d.year == now.year;
        }).toList();
        debugPrint('📅 getEvents: ${results.length} événements aujourd\'hui');
      } else if (dateFilter == 'week') {
        final weekLater = now.add(const Duration(days: 7));
        results = results.where((e) {
          final d = DateTime.tryParse((e['start_date'] ?? '').toString());
          if (d == null) return false;
          return d.isAfter(now) && d.isBefore(weekLater);
        }).toList();
        debugPrint('📅 getEvents: ${results.length} événements cette semaine');
      } else if (dateFilter == 'month') {
        results = results.where((e) {
          final d = DateTime.tryParse((e['start_date'] ?? '').toString());
          if (d == null) return false;
          return d.month == now.month && d.year == now.year;
        }).toList();
        debugPrint('📅 getEvents: ${results.length} événements ce mois');
      }

      if (city != null && city != 'all') {
        results = results.where((e) => e['city'] == city).toList();
        debugPrint('📅 getEvents: ${results.length} événements à $city');
      }

      results.sort((a, b) {
        final da = DateTime.tryParse((a['start_date'] ?? '').toString()) ?? DateTime(2100);
        final db = DateTime.tryParse((b['start_date'] ?? '').toString()) ?? DateTime(2100);
        return da.compareTo(db);
      });

      results = results.take(limit).toList();

      final events = <Event>[];
      for (final e in results) {
        final eventMap = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        final eventId = (eventMap['id'] ?? '').toString();
        final isLiked = eventId.isNotEmpty ? await _isEventLiked(eventId) : false;
        final isSaved = eventId.isNotEmpty ? await _isEventSaved(eventId) : false;

        events.add(Event.fromJson({
          ...eventMap,
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

  Future<List<Event>> getPopularEvents({int limit = 10}) async {
    try {
      final response = await _supabase.from('events').select('*');
      List<dynamic> results = response as List;

      final now = DateTime.now();
      results = results.where((e) {
        final status = (e['status'] ?? '').toString();
        final d = DateTime.tryParse((e['start_date'] ?? '').toString());
        return status == 'upcoming' && d != null && d.isAfter(now);
      }).toList();

      results.sort((a, b) => ((b['views_count'] ?? 0) as num).compareTo((a['views_count'] ?? 0) as num));
      results = results.take(limit).toList();

      final events = <Event>[];
      for (final e in results) {
        final eventMap = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        final eventId = (eventMap['id'] ?? '').toString();
        final isLiked = eventId.isNotEmpty ? await _isEventLiked(eventId) : false;
        events.add(Event.fromJson({
          ...eventMap,
          'is_liked': isLiked,
        }));
      }

      return events;
    } catch (e) {
      debugPrint('❌ Error getPopularEvents: $e');
      return [];
    }
  }

  Future<List<Event>> getRecentEvents({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('events')
          .select('*')
          .eq('status', 'upcoming')
          .order('created_at', ascending: false)
          .limit(limit);

      final events = <Event>[];
      for (final e in response as List) {
        final eventMap = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        final eventId = (eventMap['id'] ?? '').toString();
        final isLiked = eventId.isNotEmpty ? await _isEventLiked(eventId) : false;
        events.add(Event.fromJson({
          ...eventMap,
          'is_liked': isLiked,
        }));
      }

      return events;
    } catch (e) {
      debugPrint('❌ Error getRecentEvents: $e');
      return [];
    }
  }

  /// Récupère tous les événements pour le modérateur (y compris passés, annulés, etc.)
  Future<List<Event>> getEventsForModerator({String? status}) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) {
        debugPrint('⚠️ getEventsForModerator: utilisateur non connecté');
        return [];
      }

      final userRole = await _supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (userRole == null ||
          (userRole['role'] != 'moderator' && userRole['role'] != 'admin')) {
        debugPrint('⚠️ getEventsForModerator: permission refusée');
        return [];
      }

      var query = _supabase.from('events').select('*');
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      final response = await query.order('created_at', ascending: false);

      final events = <Event>[];
      for (final e in response as List) {
        final eventMap = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        final eventId = (eventMap['id'] ?? '').toString();
        final isLiked = eventId.isNotEmpty ? await _isEventLiked(eventId) : false;
        events.add(Event.fromJson({
          ...eventMap,
          'is_liked': isLiked,
        }));
      }

      debugPrint('📋 getEventsForModerator: ${events.length} événements trouvés');
      return events;
    } catch (e) {
      debugPrint('❌ Error getEventsForModerator: $e');
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
        ...Map<String, dynamic>.from((response as Map).cast<String, dynamic>()),
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
      for (final e in response as List) {
        final eventMap = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        final eventId = (eventMap['id'] ?? '').toString();
        final isLiked = eventId.isNotEmpty ? await _isEventLiked(eventId) : false;
        events.add(Event.fromJson({
          ...eventMap,
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
      for (final e in response as List) {
        final eventMap = Map<String, dynamic>.from((e as Map).cast<String, dynamic>());
        final eventId = (eventMap['id'] ?? '').toString();
        final isLiked = eventId.isNotEmpty ? await _isEventLiked(eventId) : false;
        events.add(Event.fromJson({
          ...eventMap,
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

      return (response as List)
          .map((e) => Event.fromJson(Map<String, dynamic>.from((e as Map).cast<String, dynamic>())))
          .toList();
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

      final currentViews = ((event['views_count'] as num?) ?? 0).toInt();
      await _supabase
          .from('events')
          .update({'views_count': currentViews + 1})
          .eq('id', eventId);
    } catch (e) {
      debugPrint('❌ Error incrementViews: $e');
    }
  }

  Future<bool> _isEventLiked(String eventId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return false;

    try {
      final response = await _supabase
          .from('event_favorites')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', uid)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> likeEvent(String eventId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    final exists = await _isEventLiked(eventId);
    if (!exists) {
      await _supabase.from('event_favorites').insert({
        'event_id': eventId,
        'user_id': uid,
        'created_at': DateTime.now().toIso8601String(),
      });

      await _supabase.rpc('increment_event_likes', params: {'event_id': eventId});
    }
  }

  Future<void> unlikeEvent(String eventId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return;

    await _supabase
        .from('event_favorites')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', uid);

    await _supabase.rpc('decrement_event_likes', params: {'event_id': eventId});
  }

  Future<bool> _isEventSaved(String eventId) async {
    final uid = currentUserId;
    if (uid.isEmpty) return false;

    try {
      final response = await _supabase
          .from('event_favorites')
          .select('id')
          .eq('event_id', eventId)
          .eq('user_id', uid)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  Future<List<Event>> getFavoriteEvents() async {
    final uid = currentUserId;
    if (uid.isEmpty) return [];

    try {
      final response = await _supabase
          .from('event_favorites')
          .select('event:event_id(*)')
          .eq('user_id', uid)
          .order('created_at', ascending: false);

      final events = <Event>[];
      for (final e in response as List) {
        final event = e['event'];
        if (event != null) {
          events.add(Event.fromJson({
            ...Map<String, dynamic>.from((event as Map).cast<String, dynamic>()),
            'is_liked': true,
          }));
        }
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
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Utilisateur non connecté');

    try {
      final ticketCode = _generateTicketCode();

      final response = await _supabase.from('event_bookings').insert({
        'event_id': eventId,
        'user_id': uid,
        'ticket_quantity': quantity,
        'total_price': totalPrice,
        'payment_method': paymentMethod,
        'payment_status': 'paid',
        'ticket_code': ticketCode,
        'qr_code': ticketCode,
        'status': 'confirmed',
        'booking_date': DateTime.now().toIso8601String(),
      }).select().single();

      final event = await getEventById(eventId);
      if (event != null && event.remainingTickets != null) {
        await _supabase
            .from('events')
            .update({'remaining_tickets': event.remainingTickets! - quantity})
            .eq('id', eventId);
      }

      debugPrint('🎫 bookTicket: Ticket créé pour $quantity places');
      return EventBooking.fromJson(Map<String, dynamic>.from((response as Map).cast<String, dynamic>()));
    } catch (e) {
      debugPrint('❌ Error bookTicket: $e');
      return null;
    }
  }

  Future<List<EventBooking>> getMyTickets() async {
    final uid = currentUserId;
    if (uid.isEmpty) return [];

    try {
      final response = await _supabase
          .from('event_bookings')
          .select('*, events:event_id(title, image_url, start_date, location)')
          .eq('user_id', uid)
          .order('booking_date', ascending: false);

      final bookings = <EventBooking>[];
      for (final e in response as List) {
        final event = e['events'];
        if (event != null) {
          bookings.add(EventBooking.fromJson({
            ...Map<String, dynamic>.from((e as Map).cast<String, dynamic>()),
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
    return 'THIX-' +
        String.fromCharCodes(
          Iterable.generate(12, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
        );
  }

  // ============================================================
  // ADMIN - CRUD
  // ============================================================

  // FIX: Ajout de toutes les nouvelles colonnes
  Future<Event> createEvent({
    required String title,
    required String description,
    required String category,
    String? subCategory,
    required DateTime startDate,
    DateTime? endDate,
    required String location,
    String? address,
    double price = 0,
    String priceCurrency = 'FC',
    bool isFree = false,
    int? capacity,
    String? imageUrl,
    String? bannerUrl,
    String? city,
    bool isFeatured = false,
    String? organizerName,
    String? contactPhone,
    String? contactEmail,
  }) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Admin non connecté');

    final userRole = await _supabase
        .from('users')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    if (userRole == null ||
        (userRole['role'] != 'moderator' && userRole['role'] != 'admin')) {
      throw Exception('Permission refusée');
    }

    debugPrint('📝 createEvent: Création de l\'événement "$title"');

    final now = DateTime.now().toIso8601String();
    final startDateStr = startDate.toIso8601String();

    final response = await _supabase.from('events').insert({
      'title': title,
      'description': description,
      'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      'start_date': startDateStr,
      if (endDate != null) 'end_date': endDate.toIso8601String(),
      'location': location,
      'city': city,
      if (address != null) 'address': address,
      'price': price,
      'price_currency': priceCurrency,
      'is_free': isFree,
      'capacity': capacity,
      'remaining_tickets': capacity,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'is_featured': isFeatured,
      'status': startDate.isAfter(DateTime.now()) ? 'upcoming' : 'ongoing',
      'organizer_id': uid,
      'organizer_name': organizerName,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'created_at': now,
      'updated_at': now,
      'views_count': 0,
      'likes_count': 0,
      'shares_count': 0,
    }).select().single();

    debugPrint('✅ createEvent: Événement créé avec ID ${response['id']}');
    return Event.fromJson(Map<String, dynamic>.from((response as Map).cast<String, dynamic>()));
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Admin non connecté');

    final userRole = await _supabase
        .from('users')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    if (userRole == null ||
        (userRole['role'] != 'moderator' && userRole['role'] != 'admin')) {
      throw Exception('Permission refusée');
    }

    await _supabase
        .from('events')
        .update({
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', eventId);
  }

  Future<void> deleteEvent(String eventId) async {
    final uid = currentUserId;
    if (uid.isEmpty) throw Exception('Admin non connecté');

    final userRole = await _supabase
        .from('users')
        .select('role')
        .eq('id', uid)
        .maybeSingle();
    if (userRole == null ||
        (userRole['role'] != 'moderator' && userRole['role'] != 'admin')) {
      throw Exception('Permission refusée');
    }

    await _supabase.from('events').delete().eq('id', eventId);
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  // FIX: Utilisation de Uint8List pour la compatibilité Web
  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      final uid = currentUserId;
      if (uid.isEmpty) return null;

      final userRole = await _supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (userRole == null ||
          (userRole['role'] != 'moderator' && userRole['role'] != 'admin')) {
        return null;
      }

      final storagePath = 'events/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage.from('event_images').uploadBinary(storagePath, bytes);

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
      final uid = currentUserId;
      if (uid.isEmpty) return _emptyStats();

      final userRole = await _supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();
      if (userRole == null ||
          (userRole['role'] != 'moderator' && userRole['role'] != 'admin')) {
        return _emptyStats();
      }

      final response = await _supabase.from('events').select('*');
      final List<dynamic> events = response as List;

      final totalEvents = events.length;
      final now = DateTime.now();
      final upcomingEvents = events.where((e) {
        final status = (e['status'] ?? '').toString();
        final d = DateTime.tryParse((e['start_date'] ?? '').toString());
        return status == 'upcoming' && d != null && d.isAfter(now);
      }).length;

      int totalViews = 0;
      int totalLikes = 0;
      for (final e in events) {
        totalViews += ((e['views_count'] as num?) ?? 0).toInt();
        totalLikes += ((e['likes_count'] as num?) ?? 0).toInt();
      }

      return {
        'total_events': totalEvents,
        'upcoming_events': upcomingEvents,
        'total_views': totalViews,
        'total_likes': totalLikes,
      };
    } catch (e) {
      debugPrint('❌ Error getAdminStats: $e');
      return _emptyStats();
    }
  }

  Map<String, dynamic> _emptyStats() {
    return {
      'total_events': 0,
      'upcoming_events': 0,
      'total_views': 0,
      'total_likes': 0,
    };
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
