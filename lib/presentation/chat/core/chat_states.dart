// lib/presentation/chat/core/chat_states.dart
// [PARTIE] États du Bloc

import 'package:equatable/equatable.dart';
import 'chat_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ConversationsLoaded extends ChatState {
  final List<Conversation> allConversations;
  final List<Conversation> filteredConversations;
  final String selectedFilter;
  final List<Story> stories;
  final ChatStats stats;

  const ConversationsLoaded({
    required this.allConversations,
    required this.filteredConversations,
    required this.selectedFilter,
    required this.stories,
    required this.stats,
  });

  @override
  List<Object?> get props => [allConversations, filteredConversations, selectedFilter];
}

class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<Message> messages;
  final Message? pinnedMessage;
  final bool hasReachedEnd;

  const MessagesLoaded({
    required this.conversationId,
    required this.messages,
    this.pinnedMessage,
    this.hasReachedEnd = false,
  });

  @override
  List<Object?> get props => [conversationId, messages, hasReachedEnd];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object> get props => [message];
}

class MessageSentSuccess extends ChatState {
  final Message message;
  const MessageSentSuccess(this.message);
}

class ConfidentialMessageUnlocked extends ChatState {
  final String messageId;
  final String content;
  const ConfidentialMessageUnlocked(this.messageId, this.content);
}

class EphemeralMessageExpired extends ChatState {
  final String messageId;
  const EphemeralMessageExpired(this.messageId);
}

class UserPresenceUpdated extends ChatState {
  final String userId;
  final String status;
  const UserPresenceUpdated(this.userId, this.status);
}

class NewMessage extends ChatState {
  final Message message;
  const NewMessage(this.message);
}

class TypingState extends ChatState {
  final String conversationId;
  final List<String> typingUsers;
  const TypingState(this.conversationId, this.typingUsers);
  @override
  List<Object> get props => [conversationId, typingUsers];
}

// Conversations archivées chargées
class ArchivedConversationsLoaded extends ChatState {
  final List<Conversation> conversations;
  const ArchivedConversationsLoaded(this.conversations);
  @override
  List<Object> get props => [conversations];
}
