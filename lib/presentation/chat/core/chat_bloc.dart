// lib/presentation/chat/core/chat_bloc.dart
// Bloc complet avec initialisation du token

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import 'chat_events.dart';
import 'chat_states.dart';
import 'chat_repository.dart';
import 'chat_models.dart';
import 'chat_utils.dart';
import '../../../core/auth/token_service.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  late final Stream<List<Map<String, dynamic>>> _realtimeStream;
  String get currentUserId => Supabase.instance.client.auth.currentUser!.id;

  List<Conversation> _allConversations = [];
  String _currentFilter = 'Tous';
  List<Story> _stories = [];
  ChatStats _stats = const ChatStats();

  ChatBloc(this._repository) : super(ChatInitial()) {
    // Initialisation du token au démarrage du Bloc
    _initToken();
    on<LoadConversations>(_onLoadConversations);
    on<FilterConversations>(_onFilterConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<SendEphemeralMessage>(_onSendEphemeralMessage);
    on<SendConfidentialMessage>(_onSendConfidentialMessage);
    on<UnlockConfidentialMessage>(_onUnlockConfidentialMessage);
    on<MarkMessageAsRead>(_onMarkAsRead);
    on<AddReaction>(_onAddReaction);
    on<DeleteMessage>(_onDeleteMessage);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<UpdatePresence>(_onUpdatePresence);
    on<NewMessageReceived>(_onNewMessageReceived);
  }

  Future<void> _initToken() async {
    try {
      await TokenService.getToken();
      print('Token Edge Function prêt');
    } catch (e) {
      print('Erreur token: $e');
    }
  }

  // --- Tous les gestionnaires d'événements restent inchangés ---
  // (copier-coller les implémentations existantes)
  Future<void> _onLoadConversations(LoadConversations event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final conversations = await _repository.fetchConversations(currentUserId);
      _allConversations = conversations;
      _stories = await _repository.fetchStories(currentUserId);
      _stats = await _repository.fetchChatStats(currentUserId);
      _emitFilteredConversations(emit);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onFilterConversations(FilterConversations event, Emitter<ChatState> emit) {
    _currentFilter = event.filter;
    _emitFilteredConversations(emit);
  }

  void _emitFilteredConversations(Emitter<ChatState> emit) {
    final filtered = _currentFilter == 'Tous'
        ? _allConversations
        : _allConversations.where((c) => c.metadata?['tag'] == _currentFilter).toList();
    emit(ConversationsLoaded(
      allConversations: _allConversations,
      filteredConversations: filtered,
      selectedFilter: _currentFilter,
      stories: _stories,
      stats: _stats,
    ));
  }

  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final messages = await _repository.fetchMessages(event.conversationId);
      final pinned = messages.firstWhereOrNull((m) => m.metadata?['pinned'] == true);
      emit(MessagesLoaded(
        conversationId: event.conversationId,
        messages: messages,
        pinnedMessage: pinned,
      ));
      _listenForNewMessages(event.conversationId);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    try {
      final message = Message(
        id: ChatUtils.generateTempId(),
        conversationId: event.conversationId,
        senderId: currentUserId,
        type: event.type,
        content: event.content,
        mediaUrl: event.mediaUrl,
        sentAt: DateTime.now(),
        metadata: event.metadata,
      );
      if (state is MessagesLoaded && (state as MessagesLoaded).conversationId == event.conversationId) {
        final currentState = state as MessagesLoaded;
        emit(MessagesLoaded(
          conversationId: currentState.conversationId,
          messages: [message, ...currentState.messages],
          pinnedMessage: currentState.pinnedMessage,
        ));
      }
      final sent = await _repository.sendMessage(message);
      emit(MessageSentSuccess(sent));
      add(LoadConversations());
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onSendEphemeralMessage(SendEphemeralMessage event, Emitter<ChatState> emit) async {
    await _onSendMessage(event, emit);
  }

  Future<void> _onSendConfidentialMessage(SendConfidentialMessage event, Emitter<ChatState> emit) async {
    await _onSendMessage(event, emit);
  }

  Future<void> _onUnlockConfidentialMessage(UnlockConfidentialMessage event, Emitter<ChatState> emit) async {
    try {
      final isValid = await _repository.verifyConfidentialCode(event.messageId, event.enteredCode);
      if (isValid && state is MessagesLoaded) {
        final currentState = state as MessagesLoaded;
        final message = currentState.messages.firstWhere((m) => m.id == event.messageId);
        if (message.content != null) {
          emit(ConfidentialMessageUnlocked(event.messageId, message.content!));
        }
      } else if (!isValid) {
        emit(ChatError('Code incorrect'));
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> _onMarkAsRead(MarkMessageAsRead event, Emitter<ChatState> emit) async {
    await _repository.markAsRead(event.messageId, currentUserId);
  }

  Future<void> _onAddReaction(AddReaction event, Emitter<ChatState> emit) async {
    await _repository.addReaction(event.messageId, event.reaction, currentUserId);
    if (state is MessagesLoaded) {
      add(LoadMessages((state as MessagesLoaded).conversationId));
    }
  }

  Future<void> _onDeleteMessage(DeleteMessage event, Emitter<ChatState> emit) async {
    await _repository.deleteMessage(event.messageId, currentUserId, forEveryone: event.forEveryone);
    if (state is MessagesLoaded) {
      add(LoadMessages((state as MessagesLoaded).conversationId));
    }
  }

  void _onStartTyping(StartTyping event, Emitter<ChatState> emit) {
    if (state is TypingState) {
      final typingState = state as TypingState;
      if (!typingState.typingUsers.contains(currentUserId)) {
        emit(TypingState(event.conversationId, [...typingState.typingUsers, currentUserId]));
      }
    } else if (state is MessagesLoaded) {
      emit(TypingState(event.conversationId, [currentUserId]));
    }
  }

  void _onStopTyping(StopTyping event, Emitter<ChatState> emit) {
    if (state is TypingState) {
      final typingState = state as TypingState;
      final users = List<String>.from(typingState.typingUsers)..remove(currentUserId);
      emit(TypingState(event.conversationId, users));
    }
  }

  Future<void> _onUpdatePresence(UpdatePresence event, Emitter<ChatState> emit) async {
    await _repository.updatePresence(currentUserId, event.status);
  }

  void _onNewMessageReceived(NewMessageReceived event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded && (state as MessagesLoaded).conversationId == event.message.conversationId) {
      final currentState = state as MessagesLoaded;
      if (!currentState.messages.any((m) => m.id == event.message.id)) {
        emit(MessagesLoaded(
          conversationId: currentState.conversationId,
          messages: [event.message, ...currentState.messages],
          pinnedMessage: currentState.pinnedMessage,
        ));
      }
    }
    emit(NewMessage(event.message));
    add(LoadConversations());
  }

  void _listenForNewMessages(String conversationId) {
    _repository.listenForNewMessages(conversationId).listen((message) {
      add(NewMessageReceived(message));
    });
  }
}
