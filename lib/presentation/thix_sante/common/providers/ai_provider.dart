// 📁 lib/presentation/thix_sante/common/providers/ai_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../services/ai/openai_service.dart';
import '../../../../core/utils/logger.dart';

final aiServiceProvider = Provider((ref) => OpenAIService());

// État du chat (liste de messages)
final aiChatProvider = StateNotifierProvider<AiChatNotifier, List<Map<String, String>>>((ref) {
  return AiChatNotifier();
});

class AiChatNotifier extends StateNotifier<List<Map<String, String>>> {
  AiChatNotifier() : super([]);

  void addUserMessage(String message) {
    state = [...state, {'role': 'user', 'content': message}];
  }

  void addAssistantMessage(String message) {
    state = [...state, {'role': 'assistant', 'content': message}];
  }

  void clear() {
    state = [];
  }
}

// Provider pour les appels IA (assistant + prédictions)
final aiProvider = Provider((ref) => AiNotifier(ref));

class AiNotifier {
  final Ref _ref;
  bool _isLoading = false;

  AiNotifier(this._ref);

  bool get isLoading => _isLoading;

  Future<String?> askAssistant(String question) async {
    _isLoading = true;
    try {
      final service = _ref.read(aiServiceProvider);
      final response = await service.askAssistant(question);
      return response;
    } catch (e) {
      Logger.error('Erreur assistant IA', error: e);
      return "Désolé, une erreur s'est produite. Veuillez réessayer.";
    } finally {
      _isLoading = false;
    }
  }

  Future<Map<String, dynamic>?> getPredictiveAnalysis() async {
    _isLoading = true;
    try {
      final service = _ref.read(aiServiceProvider);
      final analysis = await service.getPredictiveAnalysis();
      return analysis;
    } catch (e) {
      Logger.error('Erreur analyse prédictive', error: e);
      return null;
    } finally {
      _isLoading = false;
    }
  }
}
