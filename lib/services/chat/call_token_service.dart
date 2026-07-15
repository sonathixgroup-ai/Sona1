// Route: lib/services/chat/call_token_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CallTokenService {
  final _client = Supabase.instance.client;

  Future<Map<String, String>> getToken({
    required String channel,
    required int uid,
  }) async {
    final res = await _client.functions.invoke(
      'agora-token',
      body: {
        'channelName': channel,
        'uid': uid,
        'role': 'publisher',
      },
    );
    final data = res.data as Map<String, dynamic>;
    return {
      'token': data['token'] as String,
      'appId': data['appId'] as String,
    };
  }
}
