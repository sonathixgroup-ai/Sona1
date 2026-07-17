// ============================================================
// 📁 lib/services/chat/chat_settings_service.dart
// ============================================================

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat/chat_user.dart';
import '../../models/chat/chat_settings.dart';

class ChatSettingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer le profil chat
  Future<ChatUser> getChatUser(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('id, display_name, username, avatar_url, chat_display_name, chat_avatar, chat_status, last_seen_at, is_online')
        .eq('id', userId)
        .single();
    return ChatUser.fromJson(response);
  }

  // Mettre à jour le profil chat
  Future<void> updateChatUser(String userId, ChatUser user) async {
    await _supabase
        .from('profiles')
        .update({
          'chat_display_name': user.displayName,
          'chat_avatar': user.avatarUrl,
          'chat_status': user.status,
        })
        .eq('id', userId);
  }

  // Uploader un avatar
  Future<String> uploadAvatar(String userId, File image) async {
    final bytes = await image.readAsBytes();
    final ext = image.path.split('.').last;
    final path = 'avatars/$userId.$ext';

    await _supabase.storage.from('profiles').uploadBinary(path, bytes, fileOptions: FileOptions(
      upsert: true,
      contentType: 'image/$ext',
    ));

    final publicUrl = _supabase.storage.from('profiles').getPublicUrl(path);
    return publicUrl;
  }

  // Récupérer les réglages chat
  Future<ChatSettings> getSettings(String userId) async {
    final response = await _supabase
        .from('profiles')
        .select('chat_settings')
        .eq('id', userId)
        .single();

    final raw = response['chat_settings'] as Map<String, dynamic>? ?? {};
    return ChatSettings.fromJson(raw);
  }

  // Mettre à jour les réglages chat
  Future<void> updateSettings(String userId, ChatSettings settings) async {
    await _supabase
        .from('profiles')
        .update({
          'chat_settings': settings.toJson(),
        })
        .eq('id', userId);
  }
}
