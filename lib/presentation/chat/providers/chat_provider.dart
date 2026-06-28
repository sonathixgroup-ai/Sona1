import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class MessagesController extends ChangeNotifier {
  final List<Message> _messages = <Message>[];

  List<Message> get messages => List.unmodifiable(_messages);

  void addMessage(Message message) {
    _messages.add(message);
    notifyListeners();
  }

  void updateMessage(String messageId, Message updatedMessage) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;
    _messages[index] = updatedMessage;
    notifyListeners();
  }

  void deleteMessage(String messageId) {
    _messages.removeWhere((msg) => msg.id == messageId);
    notifyListeners();
  }

  void togglePin(String messageId) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;
    _messages[index] = _messages[index].copyWith(isPinned: !_messages[index].isPinned);
    notifyListeners();
  }

  void addReaction(String messageId, String emoji) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;
    final target = _messages[index];
    final reactions = List<String>.from(target.reactionEmojis);
    final counts = Map<String, int>.from(target.reactionCounts);
    if (reactions.contains(emoji)) {
      reactions.remove(emoji);
      final next = (counts[emoji] ?? 1) - 1;
      if (next <= 0) {
        counts.remove(emoji);
      } else {
        counts[emoji] = next;
      }
    } else {
      reactions.add(emoji);
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    _messages[index] = target.copyWith(reactionEmojis: reactions, reactionCounts: counts);
    notifyListeners();
  }

  void setMessages(List<Message> messages) {
    _messages
      ..clear()
      ..addAll(messages);
    notifyListeners();
  }
}

class ConversationController extends ChangeNotifier {
  Conversation? _conversation;

  Conversation? get conversation => _conversation;

  void setConversation(Conversation conversation) {
    _conversation = conversation;
    notifyListeners();
  }

  void updateUnreadCount(int count) {
    final current = _conversation;
    if (current == null) return;
    _conversation = current.copyWith(unreadCount: count);
    notifyListeners();
  }

  void toggleMute() {
    final current = _conversation;
    if (current == null) return;
    _conversation = current.copyWith(isMuted: !current.isMuted);
    notifyListeners();
  }

  void toggleArchive() {
    final current = _conversation;
    if (current == null) return;
    _conversation = current.copyWith(isArchived: !current.isArchived);
    notifyListeners();
  }
}

class ConversationsController extends ChangeNotifier {
  final List<Conversation> _conversations = <Conversation>[];

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  void setConversations(List<Conversation> conversations) {
    _conversations
      ..clear()
      ..addAll(conversations);
    notifyListeners();
  }

  void addConversation(Conversation conversation) {
    _conversations.insert(0, conversation);
    notifyListeners();
  }

  void updateConversation(String conversationId, Conversation updatedConversation) {
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index == -1) return;
    _conversations[index] = updatedConversation;
    notifyListeners();
  }

  void removeConversation(String conversationId) {
    _conversations.removeWhere((conv) => conv.id == conversationId);
    notifyListeners();
  }
}
