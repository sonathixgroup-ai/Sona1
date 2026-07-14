// ============================================================
// lib/presentation/chat/escalation/services/escalation_service.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escalation_step.dart';
import '../models/escalation_level.dart';
import '../models/escalation_status.dart';
import '../models/escalation_priority.dart';
import '../models/escalation_rule.dart';  // <-- AJOUTER
class EscalationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Créer une nouvelle escalade
  Future<EscalationStep> createEscalation({
    required String conversationId,
    required String fromAgentId,
    required EscalationLevel toLevel,
    required String reason,
    required EscalationPriority priority,
    String? comment,
    String? fromAgentName,
  }) async {
    // Déterminer l'agent cible en fonction du niveau (pour l'exemple, on prend le premier disponible)
    // Dans une vraie implémentation, on pourrait avoir un algorithme de round-robin ou un mapping
    final targetAgentId = await _getTargetAgentId(toLevel);

    final data = {
      'conversation_id': conversationId,
      'from_level': EscalationLevel.agent.index, // on part toujours de L0
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

    // Mettre à jour la conversation : status = escalated, current_level = toLevel
    await _supabase
        .from('conversations')
        .update({
          'status': 'escalated',
          'current_level': toLevel.index,
        })
        .eq('id', conversationId);

    // Ajouter l'historique d'escalade dans la conversation (on pourrait stocker un array)
    // Ici, on pourrait aussi envoyer des notifications

    return EscalationStep.fromJson(response);
  }

  // Accepter une escalade
  Future<EscalationStep> acceptEscalation(String escalationId, String agentId) async {
    final response = await _supabase
        .from('escalation_steps')
        .update({
          'status': EscalationStatus.accepted.index,
          'resolved_at': DateTime.now().toIso8601String(),
          'to_agent_id': agentId, // on peut assigner l'agent qui accepte
        })
        .eq('id', escalationId)
        .select()
        .single();

    // Mettre à jour la conversation : assigned_agent_id = agentId
    final step = EscalationStep.fromJson(response);
    await _supabase
        .from('conversations')
        .update({
          'assigned_agent_id': agentId,
        })
        .eq('id', step.conversationId);

    // Notifier l'agent initial que l'escalade est acceptée

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

    // Remettre la conversation en status active, current_level = agent
    final step = EscalationStep.fromJson(response);
    await _supabase
        .from('conversations')
        .update({
          'status': 'active',
          'current_level': EscalationLevel.agent.index,
        })
        .eq('id', step.conversationId);

    return step;
  }

  // Résoudre une escalade (après traitement)
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

    // Mettre à jour la conversation : status = resolved, closed
    final step = EscalationStep.fromJson(response);
    await _supabase
        .from('conversations')
        .update({
          'status': 'resolved',
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
    // On cherche les escalades dont le to_level correspond au niveau de l'agent
    // et qui sont en attente
    final response = await _supabase
        .from('escalation_steps')
        .select()
        .eq('to_level', agentLevel.index)
        .eq('status', EscalationStatus.pending.index)
        .order('created_at', ascending: true);

    return response.map((json) => EscalationStep.fromJson(json)).toList();
  }

  // Fonction interne pour obtenir l'agent cible (simulation)
  Future<String> _getTargetAgentId(EscalationLevel level) async {
    // Dans une vraie implémentation, on récupérerait les agents disponibles
    // selon leur rôle/niveau, et on ferait un round-robin.
    // Ici, on retourne un ID fictif pour l'exemple.
    // On pourrait aussi stocker un mapping entre niveau et agent dans une table.
    return 'agent_senior_1'; // à remplacer par une vraie logique
  }

  // Escalade automatique basée sur les règles (à appeler périodiquement)
  Future<void> processAutoEscalations() async {
    // 1. Récupérer toutes les règles actives
    final rulesResponse = await _supabase
        .from('escalation_rules')
        .select()
        .eq('is_active', true);

    final rules = rulesResponse.map((json) => EscalationRule.fromJson(json)).toList();

    // 2. Récupérer les conversations actives
    final conversationsResponse = await _supabase
        .from('conversations')
        .select()
        .eq('status', 'active');

    // 3. Pour chaque conversation, vérifier les règles
    for (final conv in conversationsResponse) {
      final conversationId = conv['id'];
      // Récupérer les messages pour analyser le sentiment, les mots-clés, etc.
      // Pour l'exemple, on ne fait que simuler
      // Si une règle correspond, créer une escalade automatique
    }
  }

  // Récupérer la conversation associée à une escalade
  Future<Map<String, dynamic>> getConversation(String conversationId) async {
    final response = await _supabase
        .from('conversations')
        .select()
        .eq('id', conversationId)
        .single();
    return response;
  }
}
