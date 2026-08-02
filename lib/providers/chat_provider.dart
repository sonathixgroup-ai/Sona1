import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/chat/chat_service.dart';
import 'package:thix_id/services/chat/presence_service.dart';
import 'package:thix_id/services/chat/audio_service.dart';
import 'package:thix_id/services/chat/group_service.dart';
import 'package:thix_id/services/chat/connection_service.dart';
import 'package:thix_id/models/chat/chat_message.dart';
import 'package:thix_id/presentation/chat/call/providers/call_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService(Supabase.instance.client));
final presenceServiceProvider = Provider<PresenceService>((ref) => PresenceService(Supabase.instance.client));
final audioServiceProvider = Provider<AudioService>((ref) => AudioService(Supabase.instance.client));
final groupServiceProvider = Provider<GroupService>((ref) => GroupService(Supabase.instance.client));
final connectionServiceProvider = Provider<ConnectionService>((ref) => ConnectionService());
final callProvider = ChangeNotifierProvider<CallProvider>((ref) => CallProvider());

class ChatMsgNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService svc;
  final String convId;
  int page = 0;
  static const pageSize = 30;
  bool hasMore = true;
  bool loadingMore = false;

  ChatMsgNotifier(this.svc, this.convId) : super([]) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    page = 0;
    final msgs = await svc.getMessages(convId, limit: pageSize, offset: 0);
    hasMore = msgs.length >= pageSize;
    msgs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = msgs;
  }

  Future<void> loadMore() async {
    if (loadingMore ||!hasMore) return;
    loadingMore = true;
    page++;
    final msgs = await svc.getMessages(convId, limit: pageSize, offset: page * pageSize);
    hasMore = msgs.length >= pageSize;
    var current = [...state,...msgs];
    final seen = <String>{};
    current = current.where((m) => seen.add(m.id)).toList();
    current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = current;
    loadingMore = false;
  }

  void upsertRealtime(List<ChatMessage> updated) {
    var current = [...state];
    bool changed = false;
    for (var msg in updated) {
      final idx = current.indexWhere((m) => m.id == msg.id);
      if (idx!= -1) {
        current[idx] = msg;
        changed = true;
      } else if (!msg.isDeleted) {
        current.insert(0, msg);
        changed = true;
      }
    }
    if (changed) {
      current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = current;
    }
  }

  void addLocal(ChatMessage msg) {
    if (!state.any((m) => m.id == msg.id)) {
      var current = [msg,...state];
      current.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = current;
    }
  }

  void removeLocal(String id) {
    state = state.where((m) => m.id!= id).toList();
  }
}

final chatMessagesProvider = StateNotifierProvider.family<ChatMsgNotifier, List<ChatMessage>, String>((ref, conversationId) {
  return ChatMsgNotifier(ref.read(chatServiceProvider), conversationId);
});
