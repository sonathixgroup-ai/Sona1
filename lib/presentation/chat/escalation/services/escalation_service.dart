// ============================================================
// lib/presentation/chat/escalation/services/escalation_service.dart
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escalation_step.dart';
import '../models/escalation_level.dart';
import '../models/escalation_status.dart';
import '../models/escalation_priority.dart';
import '../models/escalation_rule.dart';

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
    try {
      // 1. Récupérer un agent cible valide (UUID)
      final targetAgentId = await _getTargetAgentId(toLevel);
      print('✅ Agent cible trouvé : $targetAgentId');

      // 2. Construire les données
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

      // 3. Insérer dans la table escalation_steps
      final response = await _supabase
          .from('escalation_steps')
          .insert(data)
          .select()
          .single();

      // 4. Mettre à jour la conversation
      await _supabase
          .from('conversations')
          .update({
            'status': 'escalated',
            'current_level': toLevel.index,
          })
          .eq('id', conversationId);

      return EscalationStep.fromJson(response);
    } catch (e) {
      print('❌ Erreur lors de la création de l\'escalade : $e');
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
    final response = await _supabase
        .from('escalation_steps')
        .select()
        .eq('to_level', agentLevel.index)
        .eq('status', EscalationStatus.pending.index)
        .order('created_at', ascending: true);

    return response.map((json) => EscalationStep.fromJson(json)).toList();
  }

  // ============================================================
  // 🔧 RÉCUPÉRATION D'UN AGENT CIBLE (UUID VALIDE)
  // ============================================================
  Future<String> _getTargetAgentId(EscalationLevel level) async {
    try {
      // 🔍 Adaptation selon votre schéma :
      //   - Si vous avez une colonne 'role', utilisez .eq('role', role)
      //   - Si vous avez une colonne 'user_type', utilisez .eq('user_type', role)
      //   - Si vous avez une colonne 'level', utilisez .eq('level', level.index)
      //   - Sinon, prenez n'importe quel utilisateur (fallback ci-dessous)

      // Exemple avec une colonne 'user_type' :
      // final role = _getRoleForLevel(level);
      // final response = await _supabase
      //     .from('profiles')
      //     .select('id')
      //     .eq('user_type', role)   // ← Remplacez 'user_type' par votre colonne
      //     .limit(1)
      //     .maybeSingle();

      // Pour l'instant, on prend le premier utilisateur disponible
      final response = await _supabase
          .from('profiles')
          .select('id')
          .limit(1)
          .maybeSingle();

      if (response != null && response['id'] != null) {
        return response['id'] as String;
      }

      // Si aucun utilisateur n'existe, on lève une exception
      throw Exception('Aucun utilisateur trouvé pour attribuer l\'escalade');
    } catch (e) {
      print('❌ Erreur dans _getTargetAgentId : $e');
      rethrow;
    }
  }

  // ============================================================
  // Optionnel : mapper un niveau vers un rôle (à utiliser si vous avez une colonne de rôle)
  // ============================================================
  String _getRoleForLevel(EscalationLevel level) {
    switch (level) {
      case EscalationLevel.senior: return 'senior_agent';
      case EscalationLevel.manager: return 'manager';
      case EscalationLevel.director: return 'director';
      case EscalationLevel.technical: return 'technical_agent';
      default: return 'agent';
    }
  }

  // ============================================================
  // Escalade automatique (à appeler via un scheduler)
  // ============================================================
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
          .eq('status', 'active');

      for (final conv in conversationsResponse) {
        // Implémentez ici la logique d'analyse pour déclencher des escalades automatiques
        final conversationId = conv['id'];
        // ... logique à ajouter
      }
    } catch (e) {
      print('❌ Erreur dans processAutoEscalations : $e');
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
