import '../models/ai_models.dart';

abstract class AIChatService {
  Future<AIChatResult> analyzeConversation({
    required String conversationId,
    required List<String> messages,
    String targetLanguage = 'fr',
  });

  Future<AIChatResult> generateSmartReplies({
    required String conversationId,
    required List<String> messages,
  });

  Future<AIChatResult> summarizeConversation({
    required String conversationId,
    required List<String> messages,
  });

  Future<AIChatResult> translateMessage({
    required String conversationId,
    required String message,
    required String targetLanguage,
  });
}

class SupabaseAIChatService implements AIChatService {
  @override
  Future<AIChatResult> analyzeConversation({required String conversationId, required List<String> messages, String targetLanguage = 'fr'}) async {
    return AIChatResult(
      sentiment: 'positive',
      confidence: 0.84,
      raw: {
        'conversationId': conversationId,
        'messagesCount': messages.length,
        'targetLanguage': targetLanguage,
        'action': 'analyzeConversation',
      },
    );
  }

  @override
  Future<AIChatResult> generateSmartReplies({required String conversationId, required List<String> messages}) async {
    return AIChatResult(
      smartReplies: const [
        'Merci, je vérifie ça et je reviens vers toi.',
        'Oui, je suis d’accord avec cette proposition.',
        'Peux-tu préciser le point 2 ?'
      ],
      raw: {
        'conversationId': conversationId,
        'messagesCount': messages.length,
        'action': 'generateSmartReplies',
      },
    );
  }

  @override
  Future<AIChatResult> summarizeConversation({required String conversationId, required List<String> messages}) async {
    return AIChatResult(
      summary: 'Résumé automatique: la conversation traite d\'une demande de suivi avec quelques prochaines étapes à confirmer.',
      raw: {
        'conversationId': conversationId,
        'messagesCount': messages.length,
        'action': 'summarizeConversation',
      },
    );
  }

  @override
  Future<AIChatResult> translateMessage({required String conversationId, required String message, required String targetLanguage}) async {
    return AIChatResult(
      translation: '[${targetLanguage.toUpperCase()}] $message',
      raw: {
        'conversationId': conversationId,
        'action': 'translateMessage',
      },
    );
  }
}
