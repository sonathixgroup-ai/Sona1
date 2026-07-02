// lib/presentation/chat/core/chat_states.dart
// [PARTIE] États du Bloc

import 'package:equatable/equatable.dart';
import 'chat_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

// État initial
class ChatInitial extends ChatState {}

// Chargement en cours
class ChatLoading extends ChatState {}

// Conversations chargées avec succès
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

// Messages d'une conversation chargés
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

// État d'erreur
class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object> get props => [message];
}

// Message envoyé avec succès (état optimiste)
class MessageSentSuccess extends ChatState {
  final Message message;
  const MessageSentSuccess(this.message);
}

// Message confidentiel déverrouillé
class ConfidentialMessageUnlocked extends ChatState {
  final String messageId;
  final String content;
  const ConfidentialMessageUnlocked(this.messageId, this.content);
}

// Message éphémère expiré (à supprimer visuellement)
class EphemeralMessageExpired extends ChatState {
  final String messageId;
  const EphemeralMessageExpired(this.messageId);
}

// Mise à jour de présence
class UserPresenceUpdated extends ChatState {
  final String userId;
  final String status;
  const UserPresenceUpdated(this.userId, this.status);
}

// Nouveau message reçu en temps réel
class NewMessage extends ChatState {
  final Message message;
  const NewMessage(this.message);
}

// État de frappe
class TypingState extends ChatState {
  final String conversationId;
  final List<String> typingUsers;
  const TypingState(this.conversationId, this.typingUsers);
  @override
  List<Object> get props => [conversationId, typingUsers];
}
