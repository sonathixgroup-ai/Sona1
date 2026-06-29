// 📁 lib/presentation/thix_sante/patient/screens/patient_messages_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../common/widgets/gradient_button.dart';
import '../../../common/widgets/empty_state.dart';
import '../../../common/widgets/pill_badge.dart';

class PatientMessagesScreen extends ConsumerStatefulWidget {
  const PatientMessagesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientMessagesScreen> createState() => _PatientMessagesScreenState();
}

class _PatientMessagesScreenState extends ConsumerState<PatientMessagesScreen> {
  final List<Map<String, dynamic>> _conversations = [
    {'name': 'Dr. Martin', 'lastMessage': 'Vos résultats sont disponibles', 'time': '14h30', 'unread': 1, 'avatar': '👨‍⚕️'},
    {'name': 'Pharmacie Dubois', 'lastMessage': 'Ordonnance prête', 'time': 'Hier', 'unread': 0, 'avatar': '💊'},
    {'name': 'Assistant THIX', 'lastMessage': 'N\'oubliez pas votre traitement', 'time': 'Hier', 'unread': 0, 'avatar': '🤖'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        ],
      ),
      body: _conversations.isEmpty
          ? const EmptyStateWidget(
              title: 'Aucun message',
              subtitle: 'Vous n\'avez pas encore de messages',
              icon: Icons.chat_bubble_outline,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final conv = _conversations[index];
                return InkWell(
                  onTap: () => _openConversation(conv),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(conv['avatar'], style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(conv['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(conv['lastMessage'], style: const TextStyle(fontSize: 12), maxLines: 1),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(conv['time'], style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            if (conv['unread'] > 0) ...[
                              const SizedBox(height: 4),
                              PillBadge(text: '${conv['unread']}', color: Colors.red, fontSize: 10),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _openConversation(Map<String, dynamic> conv) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(conv['name'])),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (context, i) => Align(
                    alignment: i.isEven ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: i.isEven ? Colors.green : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        i.isEven ? 'Bonjour docteur' : 'Bonjour, comment allez-vous ?',
                        style: TextStyle(color: i.isEven ? Colors.white : Colors.black87, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Écrire un message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GradientButton(
                      text: 'Envoyer',
                      onPressed: () {},
                      width: 80,
                      height: 48,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
