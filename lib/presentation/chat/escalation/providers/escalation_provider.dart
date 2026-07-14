// ============================================================
// lib/presentation/chat/escalation/providers/escalation_provider.dart
// ============================================================

import 'package:flutter/material.dart';
import '../models/escalation_step.dart';
import '../models/escalation_level.dart';
import '../models/escalation_priority.dart';
import '../services/escalation_service.dart';

class EscalationProvider extends ChangeNotifier {
  final EscalationService _service = EscalationService();

  List<EscalationStep> _pendingEscalations = [];
  List<EscalationStep> _history = [];
  bool _isLoading = false;
  String? _error;

  List<EscalationStep> get pendingEscalations => _pendingEscalations;
  List<EscalationStep> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Charger les escalades en attente pour un agent
  Future<void> loadPendingEscalations(String agentId, EscalationLevel level) async {
    _setLoading(true);
    try {
      _pendingEscalations = await _service.getPendingEscalations(agentId, level);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Charger l'historique pour une conversation
  Future<void> loadHistory(String conversationId) async {
    _setLoading(true);
    try {
      _history = await _service.getEscalationHistory(conversationId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Créer une nouvelle escalade
  Future<EscalationStep?> createEscalation({
    required String conversationId,
    required String fromAgentId,
    required EscalationLevel toLevel,
    required String reason,
    required EscalationPriority priority,
    String? comment,
    String? fromAgentName,
  }) async {
    _setLoading(true);
    try {
      final step = await _service.createEscalation(
        conversationId: conversationId,
        fromAgentId: fromAgentId,
        toLevel: toLevel,
        reason: reason,
        priority: priority,
        comment: comment,
        fromAgentName: fromAgentName,
      );
      _error = null;
      // Ajouter à la liste des en attente si nécessaire
      _pendingEscalations.add(step);
      notifyListeners();
      return step;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Accepter une escalade
  Future<EscalationStep?> acceptEscalation(String escalationId, String agentId) async {
    _setLoading(true);
    try {
      final step = await _service.acceptEscalation(escalationId, agentId);
      // Retirer de la liste des en attente
      _pendingEscalations.removeWhere((s) => s.id == escalationId);
      // Ajouter à l'historique
      _history.add(step);
      _error = null;
      notifyListeners();
      return step;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Refuser une escalade
  Future<EscalationStep?> rejectEscalation(String escalationId, String reason) async {
    _setLoading(true);
    try {
      final step = await _service.rejectEscalation(escalationId, reason);
      _pendingEscalations.removeWhere((s) => s.id == escalationId);
      _error = null;
      notifyListeners();
      return step;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Résoudre une escalade
  Future<EscalationStep?> resolveEscalation(String escalationId) async {
    _setLoading(true);
    try {
      final step = await _service.resolveEscalation(escalationId);
      // Mettre à jour l'historique
      final index = _history.indexWhere((s) => s.id == escalationId);
      if (index != -1) {
        _history[index] = step;
      }
      _error = null;
      notifyListeners();
      return step;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
