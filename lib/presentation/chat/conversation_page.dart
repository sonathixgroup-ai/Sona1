// lib/presentation/chat/conversation_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thix_id/presentation/chat/core/chat_bloc.dart';
import 'package:thix_id/presentation/chat/core/chat_events.dart';
import 'package:thix_id/presentation/chat/core/chat_states.dart';
import 'package:thix_id/presentation/chat/core/chat_models.dart';
import 'package:thix_id/presentation/chat/widgets/chat_bubble.dart';
import 'package:thix_id/presentation/chat/widgets/chat_input_bar.dart';
import 'package:thix_id/presentation/chat/widgets/pinned_message.dart';
import 'package:thix_id/presentation/chat/online_status/typing_indicator.dart';
import 'package:thix_id/presentation/chat/ephemeral/ephemeral_settings.dart';
import 'package:thix_id/presentation/chat/confidential_message/confidential_message.dart';
import 'package:thix_id/presentation/chat/polls/poll_creator_sheet.dart';
import 'package:thix_id/presentation/chat/polls/inline_poll_widget.dart';
import 'package:thix_id/presentation/chat/tasks/task_creator.dart';
import 'package:thix_id/presentation/chat/tasks/task_list_widget.dart';
import 'package:thix_id/presentation/chat/slash_commands/slash_command_panel.dart';
import 'package:thix_id/presentation/chat/slash_commands/slash_command_parser.dart';
import 'package:thix_id/presentation/chat/attachment_picker.dart';
import 'package:thix_id/presentation/chat/voice/voice_recorder_widget.dart';
import 'package:thix_id/presentation/chat/video_message/video_message_widget.dart';
import 'package:thix_id/presentation/chat/contact_share/contact_share_widget.dart';
import 'package:thix_id/presentation/chat/message_reminder/message_reminder.dart';
import 'package:thix_id/presentation/chat/translation/translation_button.dart';
import 'package:thix_id/presentation/chat/translation/translated_bubble.dart';

class ConversationPage extends StatefulWidget {
  final String conversationId;
  const ConversationPage({Key? key, required this.conversationId}) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late ChatBloc _chatBloc;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showSlashPanel = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadMessages(widget.conversationId));
    _chatBloc.add(StartTyping(widget.conversationId));
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _chatBloc.add(StopTyping(widget.conversationId));
    super.dispose();
  }

  void _onTextChanged() {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      _chatBloc.add(StartTyping(widget.conversationId));
    } else {
      _chatBloc.add(StopTyping(widget.conversationId));
    }
    // Afficher le panneau slash si l'utilisateur tape "/" en début de ligne
    setState(() {
      _showSlashPanel = text.startsWith('/') && text.length < 20;
    });
  }

  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;
    // Vérifier si c'est une commande slash
    final parsed = SlashCommandParser.parse(text);
    if (parsed != null) {
      _handleSlashCommand(parsed.command, parsed.args, parsed.rawText);
      return;
    }
    _chatBloc.add(SendMessage(
      conversationId: widget.conversationId,
      type: 'text',
      content: text,
    ));
    _messageController.clear();
    _focusNode.requestFocus();
  }

  void _handleSlashCommand(String command, List<String> args, String? rawText) async {
    switch (command) {
      case 'poll':
        final pollData = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => PollCreatorSheet(onPollCreated: (poll) {
            Navigator.pop(_, {
              'question': poll.question,
              'options': poll.options,
              'multiple_choice': poll.isMultipleChoice,
              'anonymous': poll.isAnonymous,
              'duration_hours': poll.expiresAt != null
                  ? DateTime.now().difference(poll.expiresAt!).inHours.abs()
                  : null,
            });
          }),
        );
        if (pollData != null) {
          _chatBloc.add(SendMessage(
            conversationId: widget.conversationId,
            type: 'poll',
            content: pollData['question'],
            metadata: pollData,
          ));
        }
        break;
      case 'todo':
        final task = await showDialog<TaskData>(
          context: context,
          builder: (_) => TaskCreator(onTaskCreated: (t) => Navigator.pop(_, t)),
        );
        if (task != null) {
          _chatBloc.add(SendMessage(
            conversationId: widget.conversationId,
            type: 'task',
            content: task.title,
            metadata: task.toJson(),
          ));
        }
        break;
      case 'remind':
        final remindData = await MessageReminder.showReminderPicker(
          context, 
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          conversationId: widget.conversationId,
          messagePreview: rawText ?? 'Rappel',
        );
        // Ici on envoie un message programmé (scheduled)
        if (remindData != null) {
          _chatBloc.add(ScheduleMessage(
            SendMessage(
              conversationId: widget.conversationId,
              type: 'text',
              content: rawText ?? 'Rappel',
            ),
            remindData,
          ));
        }
        break;
      default:
        // Commande non gérée (ex: /me, /giphy) – on envoie en texte simple
        _chatBloc.add(SendMessage(
          conversationId: widget.conversationId,
          type: 'text',
          content: _messageController.text,
        ));
    }
    _messageController.clear();
  }

  void _sendVoiceMessage(File file, int duration) {
    _chatBloc.add(SendMessage(
      conversationId: widget.conversationId,
      type: 'voice',
      mediaUrl: file.path,
      durationSeconds: duration,
    ));
  }

  void _sendEphemeralMessage() async {
    final duration = await showDialog<int>(
      context: context,
      builder: (_) => EphemeralSettings(onDurationSelected: (d) => Navigator.pop(_, d)),
    );
    if (duration != null) {
      final content = _messageController.text.trim();
      _messageController.clear();
      _chatBloc.add(SendEphemeralMessage(
        conversationId: widget.conversationId,
        content: content.isNotEmpty ? content : null,
        durationSeconds: duration,
      ));
    }
  }

  void _sendConfidentialMessage() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ConfidentialComposerDialog(),
    );
    if (result != null) {
      _chatBloc.add(SendConfidentialMessage(
        conversationId: widget.conversationId,
        content: result['content'],
        code: result['code'],
        isBiometric: result['isBiometric'],
      ));
    }
  }

  void _showAttachmentPicker() {
    AttachmentPicker.showPickerSheet(context, (file) {
      _chatBloc.add(SendMessage(
        conversationId: widget.conversationId,
        type: 'image',
        mediaUrl: file.path,
      ));
    });
  }

  void _showVideoPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VideoMessageWidget(onVideoRecorded: null)),
    );
    if (result != null && result is File) {
      _chatBloc.add(SendMessage(
        conversationId: widget.conversationId,
        type: 'video',
        mediaUrl: result.path,
      ));
    }
  }

  void _shareContact() async {
    final contact = await showModalBottomSheet<Map<String, String>>(
      context: context,
      builder: (_) => const ContactShareWidget(onContactSelected: null),
    );
    if (contact != null) {
      _chatBloc.add(SendMessage(
        conversationId: widget.conversationId,
        type: 'contact',
        content: contact['name'],
        metadata: contact,
      ));
    }
  }

  void _showReactionPicker(String messageId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ReactionPicker(
        onReactionSelected: (reaction) {
          _chatBloc.add(AddReaction(messageId, reaction));
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMessageInfo(Message message) {
    Navigator.pushNamed(
      context,
      '/chat/message-info',
      arguments: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (previous, current) => current is MessagesLoaded,
          builder: (context, state) {
            final convName = (state is MessagesLoaded) ? 'Conversation' : 'Chat';
            return Text(convName);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showConversationMenu(),
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is MessageSentSuccess) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else if (state is ConfidentialMessageUnlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message déverrouillé')),
            );
          } else if (state is ChatError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MessagesLoaded && state.conversationId == widget.conversationId) {
            return Column(
              children: [
                if (state.pinnedMessage != null)
                  PinnedMessage(
                    message: state.pinnedMessage!,
                    onTap: () {
                      // Scroll to pinned message
                    },
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final msg = state.messages[index];
                      final isMe = msg.senderId == _chatBloc.currentUserId;
                      return ChatBubble(
                        message: msg,
                        isMe: isMe,
                        onReactionTap: () => _showReactionPicker(msg.id),
                        onConfidentialTap: () {
                          if (msg.type == 'confidential') {
                            _showConfidentialDialog(msg);
                          }
                        },
                        onLongPress: () => _showMessageInfo(msg),
                      );
                    },
                  ),
                ),
                if (state is TypingState && state.typingUsers.isNotEmpty)
                  TypingIndicator(users: state.typingUsers),
                if (_showSlashPanel)
                  SlashCommandPanel(
                    currentInput: _messageController.text,
                    onExecute: (command, data) {
                      setState(() => _showSlashPanel = false);
                      if (command == 'poll' && data != null) {
                        _chatBloc.add(SendMessage(
                          conversationId: widget.conversationId,
                          type: 'poll',
                          content: data['question'],
                          metadata: data,
                        ));
                      } else if (command == 'todo' && data != null) {
                        _chatBloc.add(SendMessage(
                          conversationId: widget.conversationId,
                          type: 'task',
                          content: data['title'],
                          metadata: data,
                        ));
                      } else if (command == 'remind' && data != null) {
                        _chatBloc.add(ScheduleMessage(
                          SendMessage(
                            conversationId: widget.conversationId,
                            type: 'text',
                            content: data['text'],
                          ),
                          data['scheduled_at'],
                        ));
                      } else {
                        _sendTextMessage('/$command ${data?['text'] ?? ''}');
                      }
                    },
                  ),
                ChatInputBar(
                  controller: _messageController,
                  onSendText: _sendTextMessage,
                  onSendVoice: (path) async {
                    final duration = await _getVoiceDuration(path);
                    _sendVoiceMessage(File(path), duration);
                  },
                  onAttachment: (_) => _showAttachmentPicker(),
                  onEphemeral: _sendEphemeralMessage,
                  onConfidential: _sendConfidentialMessage,
                  onVideo: _showVideoPicker,
                  onContact: _shareContact,
                ),
              ],
            );
          } else if (state is ChatError) {
            return Center(child: Text('Erreur: ${state.message}'));
          }
          return const Center(child: Text('Aucun message'));
        },
      ),
    );
  }

  void _showConversationMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archiver'),
            onTap: () {
              _chatBloc.add(ArchiveConversation(widget.conversationId));
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Supprimer la conversation'),
            onTap: () {
              _chatBloc.add(DeleteConversation(widget.conversationId, forEveryone: true));
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_off),
            title: const Text('Ne pas déranger'),
            onTap: () {
              // Naviguer vers DoNotDisturbSettings
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showConfidentialDialog(Message msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Message confidentiel'),
        content: const Text('Ce message nécessite un code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // Ouvrir un champ code
              Navigator.pop(context);
            },
            child: const Text('Déverrouiller'),
          ),
        ],
      ),
    );
  }

  Future<int> _getVoiceDuration(String path) async {
    // Implémenter avec un package audio (ex: audioplayers)
    return 3;
  }
}

// Dialogue pour composer un message confidentiel
class _ConfidentialComposerDialog extends StatefulWidget {
  @override
  State<_ConfidentialComposerDialog> createState() => _ConfidentialComposerDialogState();
}

class _ConfidentialComposerDialogState extends State<_ConfidentialComposerDialog> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _useBiometric = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Message confidentiel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(hintText: 'Votre message'),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(hintText: 'Code secret (4-6 chiffres)'),
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          Row(
            children: [
              Checkbox(
                value: _useBiometric,
                onChanged: (v) => setState(() => _useBiometric = v ?? false),
              ),
              const Text('Utiliser biométrie'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_messageController.text.isNotEmpty &&
                (_useBiometric || _codeController.text.isNotEmpty)) {
              Navigator.pop(context, {
                'content': _messageController.text,
                'code': _codeController.text,
                'isBiometric': _useBiometric,
              });
            }
          },
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
