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
          })
          .eq('id', conversationId);

      return EscalationStep.fromJson(response);
    } catch (e) {
      print('❌ Erreur création escalade : $e');
      rethrow;
    }
  }

  // Accepter une escalade
  Future<EscalationStep> acceptEscalation(String escalationId, String agentId) async {
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
    await _supabase
        .from('conversations')
        .update({
          'assigned_agent_id': agentId,
        })
        .eq('id', step.conversationId);

    return step;
  }

  // Refuser une escalade
  Future<EscalationStep> rejectEscalation(String escalationId, String reason) async {
    final response = await _supabase
        .from('escalation_steps')
        .update({
          'status': EscalationStatus.rejected.index,
          'comment': reason,
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

    return response.map((json) => EscalationStep.fromJson(json)).toList();
  }

  // Obtenir les escalades en attente pour un agent (selon son niveau)
  Future<List<EscalationStep>> getPendingEscalations(String agentId, EscalationLevel agentLevel) async {
    final response = await _supabase
        .from('escalation_steps')
        .select()
        .eq('to_level', agentLevel.index)
        .eq('status', EscalationStatus.pending.index)
        .order('created_at', ascending: true);

    return response.map((json) => EscalationStep.fromJson(json)).toList();
  }

  // Escalade automatique
  Future<void> processAutoEscalations() async {
    try {
      final rulesResponse = await _supabase
          .from('escalation_rules')
          .select()
          .eq('is_active', true);

      final rules = rulesResponse.map((json) => EscalationRule.fromJson(json)).toList();

      final conversationsResponse = await _supabase
          .from('conversations')
          .select()
          .eq('escalation_status', 'active');

      for (final conv in conversationsResponse) {
        final conversationId = conv['id'];
        // ... logique d'analyse à implémenter
      }
    } catch (e) {
      print('❌ Erreur dans processAutoEscalations : $e');
    }
  }

  // ✅ Récupérer la conversation associée à une escalade (retourne null si inexistante)
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
