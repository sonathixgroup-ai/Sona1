// Route: lib/services/chat/call_token_service.dart
// PRODUCTION - Token Service avec cache + retry + fallback
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallTokenService {
  final SupabaseClient _client = Supabase.instance.client;

  // Cache simple en mémoire pour éviter de spammer la function
  // Clé = "$channel:$uid"
  final Map<String, _CachedToken> _cache = {};

  static const Duration _cacheTtl = Duration(minutes: 50);
  static const Duration _timeout = Duration(seconds: 12);

  // Si tu veux mettre ton AppId en fallback (optionnel)
  // Laisse vide, la function le renvoie normalement
  static const String _fallbackAppId = '';

  Future<Map<String, String>> getToken({
    required String channel,
    required int uid,
  }) async {
    final cacheKey = '$channel:$uid';
    final now = DateTime.now();

    // 1. Check cache
    final cached = _cache[cacheKey];
    if (cached!= null && now.difference(cached.createdAt) < _cacheTtl) {
      debugPrint('🎟️ Token cache hit for $channel');
      return {'token': cached.token, 'appId': cached.appId};
    }

    // 2. Try Edge Function avec retry
    int attempts = 0;
    Exception? lastError;

    while (attempts < 2) {
      attempts++;
      try {
        final res = await _client.functions
           .invoke(
              'agora-token',
              body: {
                'channelName': channel,
                'uid': uid,
                'role': 'publisher',
                'expire': 3600,
              },
            )
           .timeout(_timeout);

        if (res.data == null) {
          throw Exception('Empty response from agora-token');
        }

        final data = res.data as Map<String, dynamic>;

        final token = data['token'] as String?;
        final appId = (data['appId']?? data['app_id']?? _fallbackAppId) as String?;

        if (token == null || token.isEmpty) {
          throw Exception('Token missing in response: $data');
        }

        if (appId == null || appId.isEmpty) {
          throw Exception('appId missing in response and no fallback');
        }

        // Cache
        _cache[cacheKey] = _CachedToken(
          token: token,
          appId: appId,
          createdAt: now,
        );

        debugPrint('✅ Token fetched for $channel uid $uid');
        return {'token': token, 'appId': appId};
      } on TimeoutException {
        lastError = Exception('agora-token timeout (attempt $attempts)');
        debugPrint('⏱️ $lastError');
      } catch (e) {
        lastError = Exception('agora-token error: $e');
        debugPrint('❌ $lastError');
        if (attempts >= 2) break;
        await Future.delayed(const Duration(milliseconds: 600));
      }
    }

    // 3. Fallback: si cache expiré existe encore, on l'utilise
    if (cached!= null) {
      debugPrint('⚠️ Using expired cache as fallback for $channel');
      return {'token': cached.token, 'appId': cached.appId};
    }

    // 4. Echec total
    throw lastError?? Exception('Failed to get Agora token');
  }

  /// Pour tests : forcer un token sans serveur (NE PAS UTILISER EN PROD)
  /// Retourne un token vide si AppId est en mode test sans token.
  Map<String, String> getTestToken(String appId) {
    return {'token': '', 'appId': appId};
  }

  void clearCache() => _cache.clear();
  void invalidate(String channel, int uid) => _cache.remove('$channel:$uid');
}

class _CachedToken {
  final String token;
  final String appId;
  final DateTime createdAt;

  _CachedToken({
    required this.token,
    required this.appId,
    required this.createdAt,
  });
}
