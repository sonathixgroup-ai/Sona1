// lib/presentation/chat/drafts/draft_manager.dart
// Gestion centralisée des brouillons (sauvegarde, chargement, suppression)

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Draft {
  final String id; // conversationId + timestamp
  final String conversationId;
  final String text;
  final DateTime lastEdited;
  final Map<String, dynamic>? metadata; // pour pièces jointes, reply, etc.

  Draft({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.lastEdited,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'text': text,
    'last_edited': lastEdited.toIso8601String(),
    'metadata': metadata,
  };

  factory Draft.fromJson(Map<String, dynamic> json) => Draft(
    id: json['id'],
    conversationId: json['conversation_id'],
    text: json['text'],
    lastEdited: DateTime.parse(json['last_edited']),
    metadata: json['metadata'],
  );
}

class DraftManager {
  static const String _draftsKey = 'chat_drafts';

  // Sauvegarder ou mettre à jour un brouillon
  static Future<void> saveDraft(String conversationId, String text, {Map<String, dynamic>? metadata}) async {
    if (text.trim().isEmpty && (metadata == null || metadata.isEmpty)) {
      await deleteDraft(conversationId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadDraftsMap(prefs);
    final id = '${conversationId}_${DateTime.now().millisecondsSinceEpoch}';
    final existing = drafts[conversationId];
    final draft = Draft(
      id: existing?.id ?? id,
      conversationId: conversationId,
      text: text,
      lastEdited: DateTime.now(),
      metadata: metadata,
    );
    drafts[conversationId] = draft;
    await _saveDraftsMap(prefs, drafts);
  }

  // Charger le brouillon pour une conversation donnée
  static Future<Draft?> loadDraft(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadDraftsMap(prefs);
    return drafts[conversationId];
  }

  // Supprimer le brouillon d'une conversation
  static Future<void> deleteDraft(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadDraftsMap(prefs);
    drafts.remove(conversationId);
    await _saveDraftsMap(prefs, drafts);
  }

  // Récupérer tous les brouillons (pour affichage global)
  static Future<List<Draft>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadDraftsMap(prefs);
    return drafts.values.toList()
      ..sort((a, b) => b.lastEdited.compareTo(a.lastEdited));
  }

  // Nettoyer les brouillons trop vieux (> 7 jours)
  static Future<void> cleanOldDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final drafts = await _loadDraftsMap(prefs);
    final now = DateTime.now();
    drafts.removeWhere((_, draft) => now.difference(draft.lastEdited).inDays > 7);
    await _saveDraftsMap(prefs, drafts);
  }

  static Future<Map<String, Draft>> _loadDraftsMap(SharedPreferences prefs) async {
    final String? data = prefs.getString(_draftsKey);
    if (data == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(data);
    return decoded.map((key, value) => MapEntry(key, Draft.fromJson(value)));
  }

  static Future<void> _saveDraftsMap(SharedPreferences prefs, Map<String, Draft> drafts) async {
    final Map<String, dynamic> toSave = {};
    drafts.forEach((key, draft) {
      toSave[key] = draft.toJson();
    });
    await prefs.setString(_draftsKey, jsonEncode(toSave));
  }
}
