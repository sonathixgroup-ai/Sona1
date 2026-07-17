// ============================================================
// lib/services/chat/connection_service.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── MODÈLES (inchangés) ──────────────────────────────────
class ConnectionRequest { /* ... */ }
class Connection { /* ... */ }

class ConnectionService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ... (getters, loadData, _getPendingRequests, etc. inchangés)

  // ✅ sendRequest corrigé (gestion des doublons)
  Future<bool> sendRequest({
    required String senderId,
    required String receiverId,
    String? message,
  }) async {
    if (senderId == receiverId) {
      _error = 'Impossible de s\'envoyer une demande à soi-même';
      notifyListeners();
      return false;
    }
    try {
      // 1. Vérifier si une demande existe déjà (peu importe le statut)
      final existing = await _supabase
          .from('connection_requests')
          .select()
          .or('(sender_id.eq.$senderId,receiver_id.eq.$receiverId),(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
          .maybeSingle();

      if (existing != null) {
        // 2. Si elle existe, on la réactive (ou on la met à jour)
        await _supabase
            .from('connection_requests')
            .update({
              'status': 'pending',
              'message': message,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
        await loadData(senderId);
        return true;
      }

      // 3. Sinon, on crée une nouvelle demande
      final data = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'status': 'pending',
      };
      await _supabase
          .from('connection_requests')
          .insert(data)
          .select()
          .single();
      await loadData(senderId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      debugPrint('❌ sendRequest error: $e');
      return false;
    }
  }

  // ... (acceptRequest, rejectRequest, cancelRequest, checkConnection, getStatusBetween inchangés avec les corrections OR)
}
