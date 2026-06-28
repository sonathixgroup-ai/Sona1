import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

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
  SupabaseAIChatService({SupabaseClient? client, this.functionName = 'chat_ai'})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final String functionName;

  Future<Map<String, dynamic>> _invoke({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    final res = await _client.functions.invoke(
      functionName,
      body: <String, dynamic>{
        'action': action,
        ...payload,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return <String, dynamic>{'raw': data};
  }

  AIChatResult _parse(Map<String, dynamic> json) {
    final smartReplies = (json['smartReplies'] ?? json['smart_replies'] ?? const []) as List<dynamic>;
    final rawReplies = smartReplies.map((e) => e.toString()).toList(growable: false);
    return AIChatResult(
      translation: json['translation']?.toString(),
      summary: json['summary']?.toString(),
      smartReplies: rawReplies,
      sentiment: json['sentiment']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      raw: json,
    );
  }

  @override
  Future<AIChatResult> analyzeConversation({
    required String conversationId,
    required List<String> messages,
    String targetLanguage = 'fr',
  }) async {
    final json = await _invoke(
      action: 'analyzeConversation',
      payload: {
        'conversationId': conversationId,
        'messages': messages,
        'targetLanguage': targetLanguage,
      },
    );
    return _parse(json);
  }

  @override
  Future<AIChatResult> generateSmartReplies({
    required String conversationId,
    required List<String> messages,
  }) async {
    final json = await _invoke(
      action: 'generateSmartReplies',
      payload: {
        'conversationId': conversationId,
        'messages': messages,
      },
    );
    return _parse(json);
  }

  @override
  Future<AIChatResult> summarizeConversation({
    required String conversationId,
    required List<String> messages,
  }) async {
    final json = await _invoke(
      action: 'summarizeConversation',
      payload: {
        'conversationId': conversationId,
        'messages': messages,
      },
    );
    return _parse(json);
  }

  @override
  Future<AIChatResult> translateMessage({
    required String conversationId,
    required String message,
    required String targetLanguage,
  }) async {
    final json = await _invoke(
      action: 'translateMessage',
      payload: {
        'conversationId': conversationId,
        'message': message,
        'targetLanguage': targetLanguage,
      },
    );
    return _parse(json);
  }
}
