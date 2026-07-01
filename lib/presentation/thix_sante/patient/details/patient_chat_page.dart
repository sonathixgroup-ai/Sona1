// presentation/thix_sante/patient/details/patient_chat_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/supabase/supabase_config.dart';

class PatientChatPage extends StatefulWidget {
  final String chatId;
  final String? recipientName;

  const PatientChatPage({
    super.key,
    required this.chatId,
    this.recipientName,
  });

  @override
  State<PatientChatPage> createState() => _PatientChatPageState();
}

class _PatientChatPageState extends State<PatientChatPage> {
  final SupabaseClient _supabase = SupabaseConfig.client;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  String? _recipientName;
  String? _recipientId;
  bool _isInitialized = false;

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
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer le nom du destinataire
      _recipientName = widget.recipientName ?? 'Interlocuteur';

      // Récupérer l'ID du destinataire (si le chatId est un email ou un ID)
      // Dans une vraie app, on aurait une table de correspondance
      // Pour cet exemple, on utilise l'extra ou on simule
      if (widget.chatId.contains('@')) {
        // C'est probablement un email
        final response = await _supabase
            .from('profiles')
            .select('id')
            .eq('email', widget.chatId)
            .maybeSingle();
        if (response != null) {
          _recipientId = response['id'];
        } else {
          _recipientId = widget.chatId; // fallback
        }
      } else {
        _recipientId = widget.chatId;
      }

      // Charger les messages existants (pour l'exemple, on charge depuis une table health_messages)
      // Si la table n'existe pas, on charge des messages mockés
      try {
        final response = await _supabase
            .from('health_messages')
            .select('*')
            .or(
                'sender_id.eq.${user.id},recipient_id.eq.${user.id},sender_id.eq.${_recipientId},recipient_id.eq.${_recipientId}')
            .order('created_at', ascending: true)
            .limit(50);

        if (response is List && response.isNotEmpty) {
          _messages = response.map((e) => e as Map<String, dynamic>).toList();
        } else {
          // Pas de messages en base, charger des messages mockés pour l'exemple
          _loadMockMessages(user.id);
        }
      } catch (e) {
        // Si la table n'existe pas, charger des messages mockés
        _loadMockMessages(user.id);
      }

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });

      // Scroll en bas après chargement
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    // Messages mockés
    _messages = [
      {
        'id': 'msg1',
        'sender_id': _recipientId ?? 'doc1',
        'recipient_id': userId,
        'content': 'Bonjour, comment allez-vous ?',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'is_read': true,
        'sender_name': _recipientName,
      },
      {
        'id': 'msg2',
        'sender_id': userId,
        'recipient_id': _recipientId ?? 'doc1',
        'content': 'Bonjour, je vais bien merci. J\'ai une question sur mon traitement.',
        'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)).toIso8601String(),
        'is_read': true,
        'sender_name': 'Moi',
      },
      {
        'id': 'msg3',
        'sender_id': _recipientId ?? 'doc1',
        'recipient_id': userId,
        'content': 'Bien sûr, posez votre question.',
        'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)).toIso8601String(),
        'is_read': true,
        'sender_name': _recipientName,
      },
      {
        'id': 'msg4',
        'sender_id': userId,
        'recipient_id': _recipientId ?? 'doc1',
        'content': 'Est-ce que je peux prendre le médicament le matin à jeun ?',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'is_read': false,
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

      final newMessage = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'sender_id': user.id,
        'recipient_id': _recipientId ?? widget.chatId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'sender_name': user.displayName ?? 'Moi',
      };

      // Envoyer le message à la base de données (si la table existe)
      try {
        await _supabase.from('health_messages').insert({
          'sender_id': user.id,
          'recipient_id': _recipientId ?? widget.chatId,
          'content': text,
          'is_read': false,
        });
      } catch (_) {
        // Si la table n'existe pas, on garde le message en local
      }

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _isSending = false;
      });

      _scrollToBottom();

      // Simuler une réponse automatique (pour la démo)
      if (!_recipientId?.contains('assistant') ?? false) {
        _simulateReply(user.id);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _simulateReply(String userId) {
    Future.delayed(const Duration(seconds: 2), () {
      final reply = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'sender_id': _recipientId ?? 'doc1',
        'recipient_id': userId,
        'content': 'Je vous répondrai dans les plus brefs délais.',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'sender_name': _recipientName ?? 'Interlocuteur',
      };

      if (mounted) {
        setState(() {
          _messages.add(reply);
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2563FF).withOpacity(0.1),
              child: Text(
                _recipientName?.isNotEmpty == true ? _recipientName![0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF2563FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(_recipientName ?? 'Discussion'),
          ],
        ),
        backgroundColor: const Color(0xFF2563FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Erreur : $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeChat,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Liste des messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = msg['sender_id'] == AuthController.instance.currentUser?.id;
                          return _MessageBubble(
                            message: msg['content'] as String,
                            isMe: isMe,
                            time: DateTime.parse(msg['created_at'] as String),
                            senderName: isMe ? 'Moi' : (msg['sender_name'] as String? ?? 'Interlocuteur'),
                          );
                        },
                      ),
                    ),
                    // Zone de saisie
                    _buildMessageInput(),
                  ],
                ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Écrivez un message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _sendMessage(),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _isSending ? Colors.grey : const Color(0xFF2563FF),
            radius: 24,
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
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
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF2563FF) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(time),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
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
