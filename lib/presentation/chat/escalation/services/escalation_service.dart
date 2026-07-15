// lib/presentation/chat/escalation/services/escalation_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escalation_step.dart';
import '../models/escalation_level.dart';
import '../models/escalation_status.dart';
import '../models/escalation_priority.dart';
import '../models/escalation_rule.dart';

class EscalationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🔍 Rechercher un utilisateur par son handle (username)
  Future<Map<String, dynamic>?> getUserByHandle(String username) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, display_name, username, avatar_url')
          .eq('username', username)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Erreur recherche utilisateur par handle : $e');
      return null;
    }
  }

  // Créer une nouvelle escalade
  Future<EscalationStep> createEscalation({
    required String conversationId,
    required String fromAgentId,
    required String targetAgentId,
    required EscalationLevel toLevel,
    required String reason,
    required EscalationPriority priority,
    String? comment,
    String? fromAgentName,
  }) async {
    try {
      // FIX: empêche les doublons que tu as sur tes screenshots
      final existingPending = await _supabase
          .from('escalation_steps')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('to_agent_id', targetAgentId)
          .eq('status', EscalationStatus.pending.index)
          .maybeSingle();

      if (existingPending != null) {
        throw Exception('Une escalade est déjà en attente pour cet agent');
      }

      final target = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', targetAgentId)
          .maybeSingle();
      if (target == null) {
        throw Exception('L\'utilisateur cible n\'existe pas');
      }

      final data = {
        'conversation_id': conversationId,
        'from_level': EscalationLevel.agent.index,
        'to_level': toLevel.index,
        'from_agent_id': fromAgentId,
        'to_agent_id': targetAgentId,
        'reason': reason,
        'priority': priority.index,
        'status': EscalationStatus.pending.index,
        'comment': comment,
        'from_agent_name': fromAgentName,
      };

      final response = await _supabase
          .from('escalation_steps')
          .insert(data)
          .select()
          .single();

      await _supabase
          .from('conversations')
          .update({
            'escalation_status': 'escalated',
            'current_level': toLevel.index,
            'is_escalated': true,
            'escalated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      return EscalationStep.fromJson(response);
    } catch (e) {
      print('❌ Erreur création escalade : $e');
      rethrow;
    }
  }

  // ✅ CORRIGÉ : Accepter une escalade - AJOUTE LE PARTICIPANT
  Future<EscalationStep> acceptEscalation(String escalationId, String agentId) async {
    try {
      final response = await _supabase
          .from('escalation_steps')
          .update({
            'status': EscalationStatus.accepted.index,
            'resolved_at': DateTime.now().toIso8601String(),
            'to_agent_id': agentId,
          })
          .eq('id', escalationId)
          .select()
          .single();

      final step = EscalationStep.fromJson(response);

      // 1. Met à jour la conversation
      await _supabase
          .from('conversations')
          .update({
            'assigned_agent_id': agentId,
            'escalation_status': 'accepted',
            'is_escalated': false,
          })
          .eq('id', step.conversationId);

      // 2. CRITIQUE : Ajoute l'agent comme participant
      // Sans ça, getConversations() ne le verra jamais et getConversation() avec !inner retournait null
      await _supabase.from('conversation_participants').upsert(
        {
          'conversation_id': step.conversationId,
          'user_id': agentId,
          'role': 'member',
          'last_read_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'conversation_id,user_id',
      );

      return step;
    } catch (e) {
      print('❌ Erreur acceptEscalation : $e');
      rethrow;
    }
  }

  // Refuser une escalade
  Future<EscalationStep> rejectEscalation(String escalationId, String reason) async {
    final response = await _supabase
        .from('escalation_steps')
        .update({
          'status': EscalationStatus.rejected.index,
          'comment': reason,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', escalationId)
        .select()
        .single();

    final step = EscalationStep.fromJson(response);
    await _supabase
        .from('conversations')
        .update({
          'escalation_status': 'active',
          'current_level': EscalationLevel.agent.index,
          'is_escalated': false,
        })
        .eq('id', step.conversationId);

    return step;
  }

  // Résoudre une escalade
  Future<EscalationStep> resolveEscalation(String escalationId) async {
    final response = await _supabase
        .from('escalation_steps')
        .update({
          'status': EscalationStatus.resolved.index,
          'resolved_at': DateTime.now().toIso8601String(),
        })
        .eq('id', escalationId)
        .select()
        .single();

    final step = EscalationStep.fromJson(response);
    await _supabase
        .from('conversations')
        .update({
          'escalation_status': 'resolved',
          'is_escalated': false,
        })
        .eq('id', step.conversationId);

    return step;
  }

  // Obtenir l'historique des escalades pour une conversation
  Future<List<EscalationStep>> getEscalationHistory(String conversationId) async {
    final response = await _supabase
        .from('escalation_steps')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => EscalationStep.fromJson(json)).toList();
  }

  // Obtenir les escalades en attente pour un agent (selon son niveau)
  Future<List<EscalationStep>> getPendingEscalations(String agentId, EscalationLevel agentLevel) async {
    final response = await _supabase
        .from('escalation_steps')
        .select()
        .eq('to_level', agentLevel.index)
        .eq('status', EscalationStatus.pending.index)
        .order('created_at', ascending: true);

    return (response as List).map((json) => EscalationStep.fromJson(json)).toList();
  }

  // Obtenir les escalades reçues directement par to_agent_id (utilisé par ta page)
  Future<List<EscalationStep>> getReceivedEscalations(String agentId) async {
    final response = await _supabase
        .from('escalation_steps')
        .select()
        .eq('to_agent_id', agentId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => EscalationStep.fromJson(json)).toList();
  }

  // Escalade automatique
  Future<void> processAutoEscalations() async {
    try {
      final rulesResponse = await _supabase
          .from('escalation_rules')
          .select()
          .eq('is_active', true);

      final rules = (rulesResponse as List).map((json) => EscalationRule.fromJson(json)).toList();

      final conversationsResponse = await _supabase
          .from('conversations')
          .select()
          .eq('escalation_status', 'active');

      for (final conv in conversationsResponse as List) {
        final conversationId = conv['id'];
        // ... logique d'analyse à implémenter
      }
    } catch (e) {
      print('❌ Erreur dans processAutoEscalations : $e');
    }
  }

  // Récupérer la conversation associée à une escalade (retourne null si inexistante)
  Future<Map<String, dynamic>?> getConversation(String conversationId) async {
    try {
      final response = await _supabase
          .from('conversations')
          .select()
          .eq('id', conversationId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('❌ Erreur getConversation : $e');
      return null;
    }
  }
}
