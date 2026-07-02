// lib/presentation/chat/core/chat_events.dart
// [PARTIE] Événements du Bloc

import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

// Chargement des conversations
class LoadConversations extends ChatEvent {}

// Filtrage des conversations
class FilterConversations extends ChatEvent {
  final String filter;
  const FilterConversations(this.filter);
  @override
  List<Object> get props => [filter];
}

// Chargement des messages d'une conversation
class LoadMessages extends ChatEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

// Envoi d'un message standard (texte, image, etc.)
class SendMessage extends ChatEvent {
  final String conversationId;
  final String type;
  final String? content;
  final String? mediaUrl;
  final Map<String, dynamic>? metadata;
  const SendMessage({
    required this.conversationId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.metadata,
  });
  @override
  List<Object?> get props => [conversationId, type, content];
}

// Envoi d'un message éphémère
class SendEphemeralMessage extends SendMessage {
  final int durationSeconds;
  const SendEphemeralMessage({
    required super.conversationId,
    super.content,
    super.mediaUrl,
    required this.durationSeconds,
  }) : super(
          type: ChatConstants.messageTypeEphemeral,
          metadata: {ChatConstants.metadataKeyDuration: durationSeconds},
        );
  @override
  List<Object> get props => [...super.props, durationSeconds];
}

// Envoi d'un message confidentiel (avec code)
class SendConfidentialMessage extends SendMessage {
  final String code;
  final bool isBiometric;
  const SendConfidentialMessage({
    required super.conversationId,
    super.content,
    super.mediaUrl,
    required this.code,
    this.isBiometric = false,
  }) : super(
          type: ChatConstants.messageTypeConfidential,
          metadata: {
            ChatConstants.metadataKeyCodeHash: ChatUtils.hashCode(code),
            ChatConstants.metadataKeyIsBiometric: isBiometric,
          },
        );
  @override
  List<Object> get props => [...super.props, code, isBiometric];
}

// Déverrouiller un message confidentiel
class UnlockConfidentialMessage extends ChatEvent {
  final String messageId;
  final String enteredCode;
  const UnlockConfidentialMessage(this.messageId, this.enteredCode);
  @override
  List<Object> get props => [messageId, enteredCode];
}

// Marquer un message comme lu
class MarkMessageAsRead extends ChatEvent {
  final String messageId;
  final String conversationId;
  const MarkMessageAsRead(this.messageId, this.conversationId);
}

// Ajouter une réaction
class AddReaction extends ChatEvent {
  final String messageId;
  final String reaction;
  const AddReaction(this.messageId, this.reaction);
}

// Supprimer un message
class DeleteMessage extends ChatEvent {
  final String messageId;
  final bool forEveryone;
  const DeleteMessage(this.messageId, {this.forEveryone = false});
}

// Indicateur de frappe
class StartTyping extends ChatEvent {
  final String conversationId;
  const StartTyping(this.conversationId);
}
class StopTyping extends ChatEvent {
  final String conversationId;
  const StopTyping(this.conversationId);
}

// Mise à jour de présence
class UpdatePresence extends ChatEvent {
  final String status;
  const UpdatePresence(this.status);
}

// Réception d'un nouveau message en temps réel (via WebSocket)
class NewMessageReceived extends ChatEvent {
  final Message message;
  const NewMessageReceived(this.message);
}
