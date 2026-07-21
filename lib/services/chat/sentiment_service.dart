// 📁 lib/services/chat/sentiment_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/chat/sentiment.dart';
import '../../supabase/supabase_config.dart';

class SentimentService {
  // Option 1: API externe (Hugging Face, OpenAI, ou service maison)
  // Option 2: Modèle local avec TensorFlow Lite ou ONNX
  // Option 3: Règle simple (keywords)

  final String _apiUrl = 'https://api-inference.huggingface.co/models/distilbert-base-uncased-finetuned-sst-2-english';
  final String? _apiKey = SupabaseConfig.client.auth.currentUser?.id; // ou votre clé API

  // ============================================================
  // MÉTHODE PRINCIPALE
  // ============================================================

  Future<SentimentResult> analyze(String text) async {
    // 1. Nettoyer le texte
    final cleanText = _cleanText(text);
    if (cleanText.isEmpty) {
      return SentimentResult(
        sentiment: SentimentType.neutral,
        score: 0.0,
        confidence: 0.0,
        label: 'Texte vide',
      );
    }

    // 2. Méthode hybride : règle simple + IA (si disponible)
    //    Pour les petits textes, on utilise des règles.
    //    Pour les textes longs, on utilise l'IA.

    if (cleanText.split(' ').length < 5) {
      return _analyzeWithRules(cleanText);
    }

    // 3. Appel API IA
    try {
      return await _analyzeWithAI(cleanText);
    } catch (e) {
      // Fallback sur les règles
      print('❌ Erreur API sentiment: $e');
      return _analyzeWithRules(cleanText);
    }
  }

  // ============================================================
  // ANALYSE PAR RÈGLES (Fallback)
  // ============================================================

  SentimentResult _analyzeWithRules(String text) {
    final lower = text.toLowerCase();
    int score = 0;

    // Mots positifs
    const positiveWords = [
      'merci', 'super', 'génial', 'parfait', 'excellent', 'content',
      'satisfait', 'heureux', 'bon', 'bien', 'top', 'bravo', 'félicitations',
      'amour', 'j\'aime', 'adore', 'sourire', 'sympa'
    ];
    // Mots négatifs
    const negativeWords = [
      'problème', 'erreur', 'bug', 'déçu', 'frustré', 'insatisfait',
      'mauvais', 'nul', 'horrible', 'détestable', 'énervé', 'colère',
      'grave', 'urgent', 'inacceptable', 'dégoûté', 'triste', 'pleurer',
      'défaut', 'panne', 'perdu'
    ];
    // Mots très négatifs
    const veryNegativeWords = [
      'inadmissible', 'catastrophe', 'horrible', 'désastreux',
      'incompétence', 'inutile', 'arnaque', 'escroquerie'
    ];

    for (var word in positiveWords) {
      if (lower.contains(word)) score += 1;
    }
    for (var word in negativeWords) {
      if (lower.contains(word)) score -= 1;
    }
    for (var word in veryNegativeWords) {
      if (lower.contains(word)) score -= 2;
    }

    // Normaliser le score entre -1 et 1
    double normalized = (score / 5).clamp(-1.0, 1.0);

    SentimentType type;
    if (normalized >= 0.3) type = SentimentType.positive;
    else if (normalized >= -0.1) type = SentimentType.neutral;
    else if (normalized >= -0.5) type = SentimentType.negative;
    else type = SentimentType.veryNegative;

    return SentimentResult(
      sentiment: type,
      score: normalized,
      confidence: 0.7 - (score.abs() / 10),
      label: 'Règle',
    );
  }

  // ============================================================
  // ANALYSE PAR IA
  // ============================================================

  Future<SentimentResult> _analyzeWithAI(String text) async {
    // Option A: Hugging Face
    // Option B: OpenAI (GPT)
    // Option C: Service maison

    // Exemple avec Hugging Face (modèle gratuit)
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          final label = result['label'] as String? ?? 'neutral';
          final score = (result['score'] ?? 0.5).toDouble();

          final sentiment = _mapLabelToSentiment(label, score);
          return SentimentResult(
            sentiment: sentiment,
            score: label == 'POSITIVE' ? score : -score,
            confidence: score,
            label: label,
            probabilities: result['probabilities']?.cast<String, double>(),
          );
        }
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  SentimentType _mapLabelToSentiment(String label, double score) {
    if (label == 'POSITIVE' || label == 'positive') {
      if (score > 0.85) return SentimentType.positive;
      return SentimentType.neutral;
    } else if (label == 'NEGATIVE' || label == 'negative') {
      if (score > 0.85) return SentimentType.veryNegative;
      return SentimentType.negative;
    }
    return SentimentType.neutral;
  }

  // ============================================================
  // UTILITAIRES
  // ============================================================

  String _cleanText(String text) {
    // Supprimer les URLs
    text = text.replaceAll(RegExp(r'https?://\S+'), '');
    // Supprimer les mentions
    text = text.replaceAll(RegExp(r'@\w+'), '');
    // Supprimer les hashtags
    text = text.replaceAll(RegExp(r'#\w+'), '');
    // Normaliser les espaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  // ============================================================
  // ANALYSE DE BATCH (pour plusieurs messages)
  // ============================================================

  Future<List<SentimentResult>> analyzeBatch(List<String> texts) async {
    final results = <SentimentResult>[];
    for (var text in texts) {
      final result = await analyze(text);
      results.add(result);
    }
    return results;
  }

  // ============================================================
  // ANALYSE DU STATUT GLOBAL D'UNE CONVERSATION
  // ============================================================

  Future<Map<String, dynamic>> analyzeConversation(List<String> messages) async {
    if (messages.isEmpty) {
      return {
        'overall': SentimentType.neutral,
        'averageScore': 0.0,
        'total': 0,
        'positive': 0,
        'neutral': 0,
        'negative': 0,
        'veryNegative': 0,
      };
    }

    final results = await analyzeBatch(messages);
    final stats = {
      'total': results.length,
      'positive': results.where((r) => r.sentiment == SentimentType.positive).length,
      'neutral': results.where((r) => r.sentiment == SentimentType.neutral).length,
      'negative': results.where((r) => r.sentiment == SentimentType.negative).length,
      'veryNegative': results.where((r) => r.sentiment == SentimentType.veryNegative).length,
    };

    final avgScore = results.fold<double>(0, (sum, r) => sum + r.score) / results.length;
    final overall = _getOverallSentiment(avgScore);

    return {
      'overall': overall,
      'averageScore': avgScore,
      ...stats,
    };
  }

  SentimentType _getOverallSentiment(double avgScore) {
    if (avgScore >= 0.3) return SentimentType.positive;
    if (avgScore >= -0.1) return SentimentType.neutral;
    if (avgScore >= -0.5) return SentimentType.negative;
    return SentimentType.veryNegative;
  }
}
