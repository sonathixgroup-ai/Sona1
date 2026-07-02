// presentation/thix_sante/doctor/details/doctor_chat_page.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final TextEditingController _messageController =
      TextEditingController();

  final List<Map<String, String>> _messages = [];

  bool get isNewConversation =>
      widget.conversationId == null ||
      widget.conversationId!.isEmpty;

  @override
  void initState() {
    super.initState();

    // Charger des messages fictifs uniquement
    // si une conversation existe déjà
    if (!isNewConversation) {
      _messages.addAll([
        {
          'sender': widget.participantName ?? 'Patient',
          'text': 'Bonjour docteur, comment allez-vous ?',
        },
        {
          'sender': 'Moi',
          'text': 'Bonjour, je vais bien, merci.',
        },
      ]);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'Moi',
        'text': text,
      });
    });

    _messageController.clear();

    // Simulation de réponse automatique
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'sender': widget.participantName ?? 'Patient',
          'text': 'Merci pour votre message docteur.',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.participantName?.trim().isNotEmpty == true
        ? widget.participantName!
        : 'Discussion médicale';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sante/doctor/connect');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun message pour le moment',
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg =
                          _messages[_messages.length - 1 - index];

                      final isMe = msg['sender'] == 'Moi';

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.blue
                                : Colors.grey.shade300,
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
