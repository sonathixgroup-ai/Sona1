// presentation/thix_sante/doctor/details/doctor_chat_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DoctorChatPage extends StatefulWidget {
  final String? conversationId; id,
  final String? participantName; name,
  const DoctorChatPage({super.key, this.conversationId, this.participantName});

  @override
  State<DoctorChatPage> createState() => _DoctorChatPageState();
}

class _DoctorChatPageState extends State<DoctorChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.conversationId != null) {
      // Simuler des messages
      _messages.add({'sender': 'Patient', 'text': 'Bonjour docteur, comment allez-vous ?'});
      _messages.add({'sender': 'Moi', 'text': 'Bonjour, je vais bien, et vous ?'});
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'Moi', 'text': text});
      _messageController.clear();
    });
    // Simuler réponse
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({'sender': widget.participantName ?? 'Patient', 'text': 'Merci pour votre message.'});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.participantName ?? 'Discussion')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[_messages.length - 1 - index];
                final isMe = msg['sender'] == 'Moi';
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg['text']!, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
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
