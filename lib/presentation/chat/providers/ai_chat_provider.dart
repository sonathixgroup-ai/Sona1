import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_models.dart';
import '../services/ai_chat_service.dart';

final aiChatServiceProvider = Provider<AIChatService>((ref) {
  return SupabaseAIChatService();
});

class AIChatController extends StateNotifier<AsyncValue<AIChatState>> {
  AIChatController(this._service)
      : super(const AsyncValue.data(AIChatState()));

  final AIChatService _service;

  Future<void> analyzeConversation({
    required String conversationId,
    required List<String> messages,
    String targetLanguage = 'fr',
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.analyzeConversation(
        conversationId: conversationId,
        messages: messages,
        targetLanguage: targetLanguage,
      );
      state = AsyncValue.data(state.valueOrNull?.copyWith(result: result) ?? AIChatState(result: result));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> generateSmartReplies({
    required String conversationId,
    required List<String> messages,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.generateSmartReplies(
        conversationId: conversationId,
        messages: messages,
      );
      state = AsyncValue.data(state.valueOrNull?.copyWith(result: result) ?? AIChatState(result: result));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> summarizeConversation({
    required String conversationId,
    required List<String> messages,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.summarizeConversation(
        conversationId: conversationId,
        messages: messages,
      );
      state = AsyncValue.data(state.valueOrNull?.copyWith(result: result) ?? AIChatState(result: result));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> translateMessage({
    required String conversationId,
    required String message,
    required String targetLanguage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.translateMessage(
        conversationId: conversationId,
        message: message,
        targetLanguage: targetLanguage,
      );
      state = AsyncValue.data(state.valueOrNull?.copyWith(result: result) ?? AIChatState(result: result));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final aiChatControllerProvider = StateNotifierProvider<AIChatController, AsyncValue<AIChatState>>((ref) {
  return AIChatController(ref.watch(aiChatServiceProvider));
});
