// presentation/thix_sante/patient/details/patient_ai_chat_page.dart
import 'package:flutter/material.dart';

class PatientAIChatPage extends StatefulWidget {
  final String? conversationId;
  const PatientAIChatPage({super.key, this.conversationId});

  @override
  State<PatientAIChatPage> createState() => _PatientAIChatPageState();
}

class _PatientAIChatPageState extends State<PatientAIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'sender': 'Moi', 'text': text});
      _messageController.clear();
    });
    // Simuler réponse IA
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({'sender': 'IA', 'text': 'Merci pour votre question. Je vais vous aider.'});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant IA')),
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
                    child: Text(msg['text']!),
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
                      hintText: 'Posez votre question...',
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
