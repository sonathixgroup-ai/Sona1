import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_item.dart';

// ============================================================================
// Model EventRegistration (intégré pour éviter les erreurs d'import)
// ============================================================================
class EventRegistration {
  final String id;
  final String userId;
  final String eventId;
  final String status;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  EventRegistration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.createdAt,
    this.metadata,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      eventId: json['event_id'].toString(),
      status: json['status'] ?? 'confirmed',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

// ============================================================================
// EventService
// ============================================================================
class EventService {
  final SupabaseClient _supabase;
  static const String eventsTable = 'events';
  static const String registrationsTable = 'event_registrations';

  EventService({SupabaseClient? client})
      : _supabase = client ?? Supabase.instance.client;

  // -------------------- EVENTS --------------------
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

  // -------------------- REGISTRATIONS --------------------
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
}
