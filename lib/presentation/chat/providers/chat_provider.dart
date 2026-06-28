import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

final messagesProvider = StateNotifierProvider<MessagesNotifier, List<Message>>((ref) {
  return MessagesNotifier();
});

class MessagesNotifier extends StateNotifier<List<Message>> {
  MessagesNotifier() : super([]);

  void addMessage(Message message) {
    state = [...state, message];
  }

  void updateMessage(String messageId, Message updatedMessage) {
    state = state.map((msg) => msg.id == messageId ? updatedMessage : msg).toList();
  }

  void deleteMessage(String messageId) {
    state = state.where((msg) => msg.id != messageId).toList();
  }

  void togglePin(String messageId) {
    state = state.map((msg) {
      if (msg.id == messageId) {
        return msg.copyWith(isPinned: !msg.isPinned);
      }
      return msg;
    }).toList();
  }

  void addReaction(String messageId, String emoji) {
    state = state.map((msg) {
      if (msg.id == messageId) {
        final reactions = List<String>.from(msg.reactionEmojis);
        final counts = Map<String, int>.from(msg.reactionCounts);
        
        if (reactions.contains(emoji)) {
          reactions.remove(emoji);
          counts[emoji] = (counts[emoji] ?? 1) - 1;
          if (counts[emoji]! <= 0) counts.remove(emoji);
        } else {
          reactions.add(emoji);
          counts[emoji] = (counts[emoji] ?? 0) + 1;
        }
        
        return msg.copyWith(
          reactionEmojis: reactions,
          reactionCounts: counts,
        );
      }
      return msg;
    }).toList();
  }

  void setMessages(List<Message> messages) {
    state = messages;
  }
}

final currentConversationProvider = StateNotifierProvider<ConversationNotifier, Conversation?>((ref) {
  return ConversationNotifier();
});

class ConversationNotifier extends StateNotifier<Conversation?> {
  ConversationNotifier() : super(null);

  void setConversation(Conversation conversation) {
    state = conversation;
  }

  void updateUnreadCount(int count) {
    if (state != null) {
      state = state!.copyWith(unreadCount: count);
    }
  }

  void toggleMute() {
    if (state != null) {
      state = state!.copyWith(isMuted: !state!.isMuted);
    }
  }

  void toggleArchive() {
    if (state != null) {
      state = state!.copyWith(isArchived: !state!.isArchived);
    }
  }
}

final conversationsProvider = StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref) {
  return ConversationsNotifier();
});

class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  ConversationsNotifier() : super([]);

  void setConversations(List<Conversation> conversations) {
    state = conversations;
  }

  void addConversation(Conversation conversation) {
    state = [conversation, ...state];
  }

  void updateConversation(String conversationId, Conversation updatedConversation) {
    state = state.map((conv) => conv.id == conversationId ? updatedConversation : conv).toList();
  }

  void removeConversation(String conversationId) {
    state = state.where((conv) => conv.id != conversationId).toList();
  }
}
