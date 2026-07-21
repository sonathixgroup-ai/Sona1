// 📁 lib/services/chat/sentiment_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat/sentiment.dart';

class SentimentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Analyser un message via la Edge Function
  Future<SentimentResult> analyze(String text) async {
    final cleanText = _cleanText(text);
    if (cleanText.isEmpty) {
      return SentimentResult(
        sentiment: SentimentType.neutral,
        score: 0.0,
        confidence: 0.0,
        label: 'Texte vide',
      );
    }

    try {
      final response = await _supabase.functions.invoke(
        'analyze-sentiment',
        body: {
          'text': cleanText,
          'messageId': null, // Optionnel : l'ID du message pour mise à jour auto
        },
      );

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      final data = response.data as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>;

      return SentimentResult(
        sentiment: _mapSentiment(result['sentiment']),
        score: (result['score'] as num).toDouble(),
        confidence: (result['confidence'] as num).toDouble(),
        label: '${result['provider'] ?? 'IA'}',
      );
    } catch (e) {
      print('❌ Erreur analyse sentiment: $e');
      // Fallback sur les règles locales
      return _analyzeWithRules(cleanText);
    }
  }

  // Analyser et mettre à jour directement le message
  Future<void> analyzeAndUpdateMessage(String messageId, String text) async {
    try {
      await _supabase.functions.invoke(
        'analyze-sentiment',
        body: {
          'text': text,
          'messageId': messageId,
        },
      );
    } catch (e) {
      print('❌ Erreur analyse et mise à jour: $e');
    }
  }

  // ─── RÈGLES (fallback local) ─────────────────────────────────

  SentimentResult _analyzeWithRules(String text) {
    final lower = text.toLowerCase();
    int score = 0;

    const positive = ['merci', 'super', 'génial', 'parfait', 'excellent', 'content', 'satisfait', 'heureux', 'bon', 'bien', 'top'];
    const negative = ['problème', 'erreur', 'bug', 'déçu', 'frustré', 'insatisfait', 'mauvais', 'nul', 'horrible', 'énervé', 'urgent'];
    const veryNegative = ['inadmissible', 'catastrophe', 'désastreux', 'incompétence', 'arnaque'];

    for (var w in positive) if (lower.contains(w)) score += 1;
    for (var w in negative) if (lower.contains(w)) score -= 1;
    for (var w in veryNegative) if (lower.contains(w)) score -= 2;

    double normalized = (score / 5).clamp(-1.0, 1.0);
    SentimentType type;
    if (normalized >= 0.3) type = SentimentType.positive;
    else if (normalized >= -0.1) type = SentimentType.neutral;
    else if (normalized >= -0.5) type = SentimentType.negative;
    else type = SentimentType.veryNegative;

    return SentimentResult(
      sentiment: type,
      score: normalized,
      confidence: 0.5,
      label: 'Règle',
    );
  }

  SentimentType _mapSentiment(String str) {
    switch (str) {
      case 'positive':
        return SentimentType.positive;
      case 'negative':
        return SentimentType.negative;
      case 'very_negative':
        return SentimentType.veryNegative;
      default:
        return SentimentType.neutral;
    }
  }

  String _cleanText(String text) {
    text = text.replaceAll(RegExp(r'https?://\S+'), '');
    text = text.replaceAll(RegExp(r'@\w+'), '');
    text = text.replaceAll(RegExp(r'#\w+'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}
