import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_item.dart';
import '../models/event_registration.dart';

class EventService {
  final SupabaseClient _supabase;
  static const String eventsTable = 'events';
  static const String registrationsTable = 'event_registrations';
  static const String promoCodesTable = 'event_promo_codes';

  EventService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  // ==================== EVENTS ====================
  Future<EventItem?> getEventById(String eventId) async {
    try {
      final data = await _supabase.from(eventsTable).select().eq('id', eventId).single();
      return EventItem.fromJson(data);
    } catch (e) {
      debugPrint('getEventById error: $e');
      return null;
    }
  }

  Future<List<EventItem>> getAllEvents() async {
    try {
      final data = await _supabase.from(eventsTable).select().order('starts_at');
      return (data as List).map((e) => EventItem.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getAllEvents error: $e');
      return [];
    }
  }

  // ==================== REGISTRATIONS ====================
  Future<bool> hasUserTicket(String userId, String eventId) async {
    try {
      final res = await _supabase.from(registrationsTable).select('id').eq('user_id', userId).eq('event_id', eventId).limit(1);
      return res.isNotEmpty;
    } catch (_) {
      return false;
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
      return false;
    }
  }

  Future<EventRegistration?> createRegistration({
    required String userId,
    required String eventId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final res = await _supabase.from(registrationsTable).insert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'confirmed',
        'metadata': metadata ?? {},
      }).select().single();
      return EventRegistration.fromJson(res);
    } catch (e) {
      debugPrint('createRegistration error: $e');
      return null;
    }
  }

  Future<EventRegistration?> getRegistrationById(String registrationId) async {
    try {
      final data = await _supabase.from(registrationsTable).select().eq('id', registrationId).single();
      return EventRegistration.fromJson(data);
    } catch (e) {
      debugPrint('getRegistrationById error: $e');
      return null;
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    try {
      await _supabase.from(registrationsTable).update({'status': 'cancelled'}).eq('id', registrationId);
      return true;
    } catch (e) {
      debugPrint('cancelRegistration error: $e');
      return false;
    }
  }

  Future<List<EventRegistration>> getUserRegistrations(String userId) async {
    try {
      final data = await _supabase.from(registrationsTable).select().eq('user_id', userId).order('created_at', ascending: false);
      return (data as List).map((e) => EventRegistration.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getUserRegistrations error: $e');
      return [];
    }
  }

  /// Validates a promo code for an event.
  ///
  /// Returns the discount percent (e.g. 10.0) or null if invalid/expired.
  Future<double?> validatePromoCode({required String code, required String eventId}) async {
    final c = code.trim();
    if (c.isEmpty) return null;
    try {
      final row = await _supabase
          .from(promoCodesTable)
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
    } catch (e) {
      // Soft-fail if table doesn't exist / RLS blocks.
      debugPrint('validatePromoCode error: $e');
      return null;
    }
  }
}
