// presentation/thix_sante/doctor/details/doctor_chat_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class DoctorChatPage extends StatefulWidget {
  final String? conversationId;
  final String? participantName;

  const DoctorChatPage({
    super.key,
    this.conversationId,
    this.participantName,
  });

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  List<Map<String, dynamic>> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;

  String? _error;
  String? _participantId;
  String? _participantName;

  bool get isNewConversation =>
      widget.conversationId == null ||
      widget.conversationId!.isEmpty;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = AuthController.instance.currentUser;

      if (user == null) {
        throw Exception('Médecin non connecté');
      }

      _participantName =
          widget.participantName ?? 'Patient';

      _participantId = widget.conversationId;

      try {
        final response = await _supabase
            .from('health_messages')
            .select('*')
            .or(
              'sender_id.eq.${user.id},recipient_id.eq.${user.id}',
            )
            .order(
              'created_at',
              ascending: true,
            )
            .limit(100);

        if (response is List &&
            response.isNotEmpty) {
          _messages = response
              .map(
                (e) =>
                    e as Map<String, dynamic>,
              )
              .toList();
        } else {
          _loadMockMessages(user.id);
        }
      } catch (e) {
        _loadMockMessages(user.id);
      }

      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMockMessages(String userId) {
    _messages = [
      {
        'id': '1',
        'sender_id': _participantId ?? 'patient_1',
        'recipient_id': userId,
        'content':
            'Bonjour docteur, comment allez-vous ?',
        'created_at': DateTime.now()
            .subtract(
              const Duration(hours: 2),
            )
            .toIso8601String(),
        'sender_name':
            _participantName ?? 'Patient',
      },
      {
        'id': '2',
        'sender_id': userId,
        'recipient_id':
            _participantId ?? 'patient_1',
        'content':
            'Bonjour, je vais bien merci.',
        'created_at': DateTime.now()
            .subtract(
              const Duration(hours: 1),
            )
            .toIso8601String(),
        'sender_name': 'Moi',
      },
    ];
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final user = AuthController.instance.currentUser;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final message = {
        'id':
            'msg_${DateTime.now().millisecondsSinceEpoch}',
        'sender_id': user.id,
        'recipient_id':
            _participantId ?? 'unknown',
        'content': text,
        'created_at':
            DateTime.now().toIso8601String(),
        'sender_name':
            user.displayName ?? 'Docteur',
      };

      try {
        await _supabase
            .from('health_messages')
            .insert({
          'sender_id': user.id,
          'recipient_id':
              _participantId ?? 'unknown',
          'content': text,
          'is_read': false,
        });
      } catch (_) {}

      setState(() {
        _messages.add(message);

        _messageController.clear();

        _isSending = false;
      });

      _scrollToBottom();

      _simulateReply(user.id);
    } catch (e) {
      setState(() {
        _isSending = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateReply(String userId) {
    Future.delayed(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;

        final reply = {
          'id':
              'msg_${DateTime.now().millisecondsSinceEpoch}',
          'sender_id':
              _participantId ?? 'patient_1',
          'recipient_id': userId,
          'content':
              'Merci docteur pour votre réponse.',
          'created_at':
              DateTime.now().toIso8601String(),
          'sender_name':
              _participantName ?? 'Patient',
        };

        setState(() {
          _messages.add(reply);
        });

        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController
            .position.maxScrollExtent,
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _participantName?.trim().isNotEmpty ==
                true
            ? _participantName!
            : 'Discussion médicale';

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF2563FF),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  Colors.white.withOpacity(0.15),
              child: Text(
                title[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                '/sante/doctor/connect',
              );
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Erreur : $_error',
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      ElevatedButton(
                        onPressed:
                            _initializeChat,
                        child: const Text(
                          'Réessayer',
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child:
                          _messages.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Aucun message',
                                  ),
                                )
                              : ListView.builder(
                                  controller:
                                      _scrollController,
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal:
                                        16,
                                    vertical:
                                        12,
                                  ),
                                  itemCount:
                                      _messages
                                          .length,
                                  itemBuilder:
                                      (
                                        context,
                                        index,
                                      ) {
                                        final msg =
                                            _messages[index];

                                        final isMe =
                                            msg['sender_id'] ==
                                                AuthController
                                                    .instance
                                                    .currentUser
                                                    ?.id;

                                        return _MessageBubble(
                                          message:
                                              msg['content']
                                                  as String,
                                          isMe:
                                              isMe,
                                          time:
                                              DateTime.parse(
                                            msg['created_at']
                                                as String,
                                          ),
                                          senderName:
                                              isMe
                                                  ? 'Moi'
                                                  : (msg['sender_name']
                                                              as String? ??
                                                          'Patient'),
                                        );
                                      },
                                ),
                    ),

                    _buildInput(),
                  ],
                ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
                  _messageController,
              maxLines: null,
              decoration:
                  InputDecoration(
                hintText:
                    'Écrivez un message...',
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    24,
                  ),
                  borderSide:
                      BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Colors.grey[100],
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted:
                  (_) => _sendMessage(),
            ),
          ),

          const SizedBox(width: 8),

          CircleAvatar(
            radius: 24,
            backgroundColor:
                _isSending
                    ? Colors.grey
                    : const Color(
                        0xFF2563FF,
                      ),
            child: IconButton(
              onPressed:
                  _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color:
                            Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color:
                          Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble
    extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime time;
  final String senderName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.time,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 8,
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment
                      .start,
          children: [
            if (!isMe)
              Padding(
                padding:
                    const EdgeInsets.only(
                  left: 8,
                  bottom: 4,
                ),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        Colors.grey[600],
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color:
                    isMe
                        ? const Color(
                            0xFF2563FF,
                          )
                        : Colors.grey[200],
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe
                        ? CrossAxisAlignment
                            .end
                        : CrossAxisAlignment
                            .start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color:
                          isMe
                              ? Colors.white
                              : Colors.black87,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    DateFormat(
                      'HH:mm',
                    ).format(time),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isMe
                              ? Colors.white
                                  .withOpacity(
                                  0.7,
                                )
                              : Colors
                                  .grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
