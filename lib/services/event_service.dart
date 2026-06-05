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
  
  // Propriétés supplémentaires pour le billet
  final String ticketCode;
  final String attendeeThixId;
  final int tickets;

  EventRegistration({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    required this.createdAt,
    this.metadata,
    this.ticketCode = '',
    this.attendeeThixId = '',
    this.tickets = 1,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    // Générer un code de billet si non présent
    final String id = json['id'].toString();
    final String userId = json['user_id'].toString();
    
    String ticketCode = json['ticket_code'] ?? '';
    if (ticketCode.isEmpty) {
      // Générer un code unique basé sur l'ID de réservation
      ticketCode = 'THIX-${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}';
    }
    
    String attendeeThixId = json['attendee_thix_id'] ?? '';
    if (attendeeThixId.isEmpty) {
      attendeeThixId = userId.substring(0, userId.length > 8 ? 8 : userId.length);
    }
    
    int tickets = json['tickets'] ?? json['metadata']?['tickets'] ?? 1;
    if (tickets is String) tickets = int.tryParse(tickets) ?? 1;
    
    return EventRegistration(
      id: id,
      userId: userId,
      eventId: json['event_id'].toString(),
      status: json['status'] ?? 'confirmed',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : null,
      ticketCode: ticketCode,
      attendeeThixId: attendeeThixId,
      tickets: tickets,
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
      'ticket_code': ticketCode,
      'attendee_thix_id': attendeeThixId,
      'tickets': tickets,
    };
  }
  
  // Getters pour faciliter l'accès aux propriétés du metadata
  String get note => metadata?['note'] ?? '';
  int get ticketsFromMetadata => metadata?['tickets'] ?? tickets;
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
      final res = await _supabase
          .from(registrationsTable)
          .select('id')
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('status', 'confirmed')
          .limit(1);
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerForEvent({
    required String userId,
    required String eventId,
    int tickets = 1,
    String? note,
  }) async {
    try {
      final ticketCode = _generateTicketCode();
      final attendeeThixId = _generateAttendeeId(userId);
      
      await _supabase.from(registrationsTable).insert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'confirmed',
        'ticket_code': ticketCode,
        'attendee_thix_id': attendeeThixId,
        'tickets': tickets,
        'metadata': {
          'tickets': tickets,
          'note': note ?? '',
        },
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
      final tickets = metadata?['tickets'] ?? 1;
      final note = metadata?['note'] ?? '';
      final ticketCode = _generateTicketCode();
      final attendeeThixId = _generateAttendeeId(userId);
      
      final res = await _supabase.from(registrationsTable).insert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'confirmed',
        'ticket_code': ticketCode,
        'attendee_thix_id': attendeeThixId,
        'tickets': tickets,
        'metadata': {
          'tickets': tickets,
          'note': note,
          ...?metadata,
        },
      }).select().single();
      return EventRegistration.fromJson(res);
    } catch (e) {
      debugPrint('createRegistration error: $e');
      return null;
    }
  }

  Future<EventRegistration?> getRegistrationById(String registrationId) async {
    try {
      final data = await _supabase
          .from(registrationsTable)
          .select()
          .eq('id', registrationId)
          .single();
      return EventRegistration.fromJson(data);
    } catch (e) {
      debugPrint('getRegistrationById error: $e');
      return null;
    }
  }

  Future<bool> cancelRegistration(String registrationId) async {
    try {
      await _supabase
          .from(registrationsTable)
          .update({'status': 'cancelled'})
          .eq('id', registrationId);
      return true;
    } catch (e) {
      debugPrint('cancelRegistration error: $e');
      return false;
    }
  }

  Future<List<EventRegistration>> getUserRegistrations(String userId) async {
    try {
      final data = await _supabase
          .from(registrationsTable)
          .select()
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .order('created_at', ascending: false);
      return (data as List).map((e) => EventRegistration.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getUserRegistrations error: $e');
      return [];
    }
  }
  
  Future<List<EventRegistration>> getAllUserRegistrations(String userId) async {
    try {
      final data = await _supabase
          .from(registrationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => EventRegistration.fromJson(e)).toList();
    } catch (e) {
      debugPrint('getAllUserRegistrations error: $e');
      return [];
    }
  }

  Future<bool> updateRegistrationStatus(String registrationId, String status) async {
    try {
      await _supabase
          .from(registrationsTable)
          .update({'status': status})
          .eq('id', registrationId);
      return true;
    } catch (e) {
      debugPrint('updateRegistrationStatus error: $e');
      return false;
    }
  }
  
  // Méthodes utilitaires privées
  String _generateTicketCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    String code = 'THIX-';
    for (int i = 0; i < 8; i++) {
      final index = (random.hashCode + i * 31) % chars.length;
      code += chars[index.abs()];
    }
    return code;
  }
  
  String _generateAttendeeId(String userId) {
    if (userId.length >= 8) {
      return userId.substring(0, 8).toUpperCase();
    }
    return userId.padRight(8, '0').toUpperCase();
  }
}
