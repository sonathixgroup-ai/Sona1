import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/event_item.dart';
import '../models/event_registration.dart';

class EventService {
  final SupabaseClient _supabase;

  EventService(this._supabase);

  // ===========================================================================
  // EVENTS
  // ===========================================================================

  Future<List<EventItem>> getRecommendedEvents({
    int limit = 4,
  }) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('is_recommended', true)
          .order('event_date')
          .limit(limit);

      return (response as List)
          .map((e) => EventItem.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getRecommendedEvents error: $e');
      return [];
    }
  }

  Future<List<EventItem>> getUpcomingEvents({
    int limit = 10,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('events')
          .select()
          .gt('event_date', now)
          .order('event_date')
          .limit(limit);

      return (response as List)
          .map((e) => EventItem.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getUpcomingEvents error: $e');
      return [];
    }
  }

  Future<List<EventItem>> getAllEvents({
    String? category,
    String? search,
  }) async {
    try {
      PostgrestFilterBuilder query =
          _supabase.from('events').select();

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (search != null && search.isNotEmpty) {
        query = query.ilike(
          'title',
          '%$search%',
        );
      }

      final response =
          await query.order('event_date');

      return (response as List)
          .map((e) => EventItem.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getAllEvents error: $e');
      return [];
    }
  }

  Future<EventItem?> getEventById(
    String eventId,
  ) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .eq('id', eventId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return EventItem.fromJson(response);
    } catch (e) {
      debugPrint('getEventById error: $e');
      return null;
    }
  }

  Future<List<EventItem>> getEventsByIds(
    List<String> ids,
  ) async {
    try {
      if (ids.isEmpty) return [];

      final response = await _supabase
          .from('events')
          .select()
          .inFilter('id', ids);

      return (response as List)
          .map((e) => EventItem.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('getEventsByIds error: $e');
      return [];
    }
  }

  Future<List<String>> getPopularCategories() async {
    try {
      final response = await _supabase
          .from('events')
          .select('category');

      final Map<String, int> counts = {};

      for (final item in response) {
        final category =
            item['category']?.toString();

        if (category == null ||
            category.isEmpty) {
          continue;
        }

        counts[category] =
            (counts[category] ?? 0) + 1;
      }

      final sorted =
          counts.entries.toList()
            ..sort(
              (a, b) =>
                  b.value.compareTo(a.value),
            );

      return sorted
          .take(5)
          .map((e) => e.key)
          .toList();
    } catch (e) {
      debugPrint(
        'getPopularCategories error: $e',
      );

      return [];
    }
  }

  // ===========================================================================
  // STORAGE
  // ===========================================================================

  String? getEventCoverUrl(
    EventItem event,
  ) {
    try {
      if (event.coverImageBucket ==
              null ||
          event.coverImagePath == null) {
        return null;
      }

      return _supabase.storage
          .from(event.coverImageBucket!)
          .getPublicUrl(
            event.coverImagePath!,
          );
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // TICKETS
  // ===========================================================================

  Future<List<EventRegistration>>
      getUserRegistrations(
    String userId,
  ) async {
    try {
      final response = await _supabase
          .from('thix_event_tickets')
          .select()
          .eq('user_id', userId)
          .order(
            'created_at',
            ascending: false,
          );

      return (response as List)
          .map(
            (e) =>
                EventRegistration.fromJson(
              e,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'getUserRegistrations error: $e',
      );
      return [];
    }
  }

  Future<EventRegistration?>
      getRegistrationById(
    String registrationId,
  ) async {
    try {
      final response = await _supabase
          .from('thix_event_tickets')
          .select()
          .eq('id', registrationId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return EventRegistration.fromJson(
        response,
      );
    } catch (e) {
      debugPrint(
        'getRegistrationById error: $e',
      );
      return null;
    }
  }

  Future<bool> hasUserTicket({
    required String userId,
    required String eventId,
  }) async {
    try {
      final response = await _supabase
          .from('thix_event_tickets')
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('status', 'valid')
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint(
        'hasUserTicket error: $e',
      );
      return false;
    }
  }

  Future<String> createRegistration({
    required String userId,
    required String eventId,
    required String attendeeThixId,
    int tickets = 1,
    String? note,
  }) async {
    try {
      final alreadyRegistered =
          await hasUserTicket(
        userId: userId,
        eventId: eventId,
      );

      if (alreadyRegistered) {
        throw Exception(
          'Billet déjà existant',
        );
      }

      final ticketCode =
          'THIX-${const Uuid().v4()}';

      await _supabase
          .from('thix_event_tickets')
          .insert({
        'user_id': userId,
        'event_id': eventId,
        'attendee_thix_id':
            attendeeThixId,
        'ticket_code': ticketCode,
        'tickets': tickets,
        'note': note,
        'status': 'valid',
        'created_at':
            DateTime.now()
                .toIso8601String(),
      });

      return ticketCode;
    } catch (e) {
      debugPrint(
        'createRegistration error: $e',
      );
      rethrow;
    }
  }

  Future<void> cancelRegistration(
    String registrationId,
  ) async {
    try {
      await _supabase
          .from('thix_event_tickets')
          .update({
        'status': 'cancelled',
      }).eq('id', registrationId);
    } catch (e) {
      debugPrint(
        'cancelRegistration error: $e',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?>
      getTicketByCode(
    String ticketCode,
  ) async {
    try {
      return await _supabase
          .from('thix_event_tickets')
          .select()
          .eq(
            'ticket_code',
            ticketCode,
          )
          .maybeSingle();
    } catch (e) {
      debugPrint(
        'getTicketByCode error: $e',
      );
      return null;
    }
  }

  // ===========================================================================
  // QR VALIDATION
  // ===========================================================================

  Future<bool> validateTicket(
    String ticketCode,
  ) async {
    try {
      final ticket =
          await getTicketByCode(
        ticketCode,
      );

      if (ticket == null) {
        return false;
      }

      return ticket['status'] ==
          'valid';
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // PROMO CODES
  // ===========================================================================

  Future<double?> validatePromoCode({
    required String code,
    required String eventId,
  }) async {
    try {
      final response = await _supabase
          .from('promo_codes')
          .select()
          .eq('code', code)
          .eq('event_id', eventId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final expiry =
          DateTime.tryParse(
        response['valid_until']
                ?.toString() ??
            '',
      );

      if (expiry == null) {
        return null;
      }

      if (expiry.isBefore(
        DateTime.now(),
      )) {
        return null;
      }

      return (response[
                  'discount_percent']
              as num)
          .toDouble();
    } catch (e) {
      debugPrint(
        'validatePromoCode error: $e',
      );
      return null;
    }
  }
}
