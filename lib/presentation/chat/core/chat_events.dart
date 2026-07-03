// lib/presentation/chat/core/chat_events.dart
// [PARTIE] Événements du Bloc

import 'package:equatable/equatable.dart';
import 'chat_constants.dart';
import 'chat_utils.dart';
import 'chat_models.dart';
import '../archive/search_filters.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {}

class FilterConversations extends ChatEvent {
  final String filter;
  const FilterConversations(this.filter);
  @override
  List<Object> get props => [filter];
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

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

class SendEphemeralMessage extends SendMessage {
  final int durationSeconds;
  SendEphemeralMessage({
    required super.conversationId,
    super.content,
    super.mediaUrl,
    required this.durationSeconds,
  }) : super(
          type: ChatConstants.messageTypeEphemeral,
          metadata: {ChatConstants.metadataKeyDuration: durationSeconds},
        );
  @override
  List<Object?> get props => [...super.props, durationSeconds];
}

class SendConfidentialMessage extends SendMessage {
  final String code;
  final bool isBiometric;
  SendConfidentialMessage({
    required super.conversationId,
    super.content,
    super.mediaUrl,
    required this.code,
    this.isBiometric = false,
  }) : super(
          type: ChatConstants.messageTypeConfidential,
          metadata: {
            ChatConstants.metadataKeyCodeHash: ChatUtils.hashConfidentialCode(code), // ✅ corrigé
            ChatConstants.metadataKeyIsBiometric: isBiometric,
          },
        );
  @override
  List<Object?> get props => [...super.props, code, isBiometric];
}

class UnlockConfidentialMessage extends ChatEvent {
  final String messageId;
  final String enteredCode;
  const UnlockConfidentialMessage(this.messageId, this.enteredCode);
  @override
  List<Object> get props => [messageId, enteredCode];
}

class MarkMessageAsRead extends ChatEvent {
  final String messageId;
  final String conversationId;
  const MarkMessageAsRead(this.messageId, this.conversationId);
  @override
  List<Object> get props => [messageId, conversationId];
}

class AddReaction extends ChatEvent {
  final String messageId;
  final String reaction;
  const AddReaction(this.messageId, this.reaction);
  @override
  List<Object> get props => [messageId, reaction];
}

class DeleteMessage extends ChatEvent {
  final String messageId;
  final bool forEveryone;
  const DeleteMessage(this.messageId, {this.forEveryone = false});
  @override
  List<Object> get props => [messageId, forEveryone];
}

// Épingler / désépingler un message
class PinMessage extends ChatEvent {
  final String conversationId;
  final String messageId;
  const PinMessage(this.conversationId, this.messageId);
  @override
  List<Object> get props => [conversationId, messageId];
}

class UnpinMessage extends ChatEvent {
  final String conversationId;
  final String messageId;
  const UnpinMessage(this.conversationId, this.messageId);
  @override
  List<Object> get props => [conversationId, messageId];
}

class StartTyping extends ChatEvent {
  final String conversationId;
  const StartTyping(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class StopTyping extends ChatEvent {
  final String conversationId;
  const StopTyping(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class UpdatePresence extends ChatEvent {
  final String status;
  const UpdatePresence(this.status);
  @override
  List<Object> get props => [status];
}

class NewMessageReceived extends ChatEvent {
  final Message message;
  const NewMessageReceived(this.message);
  @override
  List<Object> get props => [message];
}

// ==================== ARCHIVES ====================
class LoadArchivedConversations extends ChatEvent {}

class UnarchiveConversation extends ChatEvent {
  final String conversationId;
  const UnarchiveConversation(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class DeleteArchivedConversation extends ChatEvent {
  final String conversationId;
  const DeleteArchivedConversation(this.conversationId);
  @override
  List<Object> get props => [conversationId];
}

class SearchArchivedConversations extends ChatEvent {
  final SearchFilters filters;
  const SearchArchivedConversations(this.filters);
  @override
  List<Object> get props => [filters];
}
