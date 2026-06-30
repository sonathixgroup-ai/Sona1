// presentation/thix_sante/patient/details/patient_ai_chat_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class PatientAIChatPage extends StatefulWidget {
  final String? conversationId;

  const PatientAIChatPage({super.key, this.conversationId});

  @override
  State<PatientAIChatPage> createState() => _PatientAIChatPageState();
}

class _PatientAIChatPageState extends State<PatientAIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Si une conversation existe, on pourrait charger l'historique
    // Ici on initialise avec un message de bienvenue
    _messages.add({
      'role': 'assistant',
      'content': 'Bonjour ! Je suis votre assistant santé THIX. Comment puis-je vous aider aujourd\'hui ?',
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Ajouter le message de l'utilisateur
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
      _isProcessing = true;
    });

    // Simuler le traitement de l'IA (appel à une API ou logique locale)
    _processUserMessage(text);
  }

  Future<void> _processUserMessage(String userMessage) async {
    // Simuler un délai de réponse
    await Future.delayed(const Duration(milliseconds: 800));

    // Réponse basée sur des mots-clés (simple IA)
    final response = _generateResponse(userMessage);

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': response,
        'timestamp': DateTime.now(),
      });
      _isProcessing = false;
    });

    // Scroll vers le bas
    _scrollToBottom();
  }

  String _generateResponse(String message) {
    final lower = message.toLowerCase();

    // Symptômes
    if (lower.contains('symptôme') || lower.contains('symptomes') || lower.contains('douleur')) {
      return 'Pour mieux vous aider, notez vos symptômes dans la section "Suivi des symptômes".\n'
          'Si vous avez une douleur intense, consultez un médecin rapidement.';
    }

    // Rendez-vous
    if (lower.contains('rendez-vous') || lower.contains('rdv') || lower.contains('consultation')) {
      return 'Vous pouvez prendre un rendez-vous directement depuis le menu "Rendez-vous".\n'
          'Si vous préférez une téléconsultation, choisissez l\'option en ligne.';
    }

    // Médicaments
    if (lower.contains('médicament') || lower.contains('medicament') || lower.contains('traitement')) {
      return 'Consultez vos médicaments en cours dans la section "Traitements".\n'
          'N\'oubliez pas de respecter les horaires de prise et les dosages prescrits.';
    }

    // Examens
    if (lower.contains('examen') || lower.contains('résultat')) {
      return 'Les résultats de vos examens sont disponibles dans la section "Examens".\n'
          'Si un résultat n\'est pas encore disponible, il le sera prochainement.';
    }

    // Urgence
    if (lower.contains('urgence') || lower.contains('appeler') || lower.contains('15')) {
      return 'En cas d\'urgence, composez le 15 (SAMU) ou rendez-vous aux urgences les plus proches.\n'
          'Vous pouvez aussi utiliser le bouton "Appeler 15" sur votre tableau de bord.';
    }

    // Bien-être
    if (lower.contains('stress') || lower.contains('sommeil') || lower.contains('relaxation')) {
      return 'Je vous recommande de consulter nos programmes bien-être :\n'
          '• Gestion du stress\n'
          '• Méditation\n'
          '• Sommeil réparateur\n'
          'Ils sont disponibles dans l\'onglet "Vie & Bien-être".';
    }

    // Nutrition
    if (lower.contains('nutrition') || lower.contains('alimentation') || lower.contains('régime')) {
      return 'Une alimentation équilibrée est essentielle.\n'
          'Pensez à varier les fruits et légumes, à limiter les sucres et à boire suffisamment d\'eau.';
    }

    // Général
    return 'Je suis là pour vous guider. Si vous avez une question sur vos symptômes, rendez-vous, '
        'médicaments ou examens, n\'hésitez pas à me poser des questions plus précises.\n'
        'Vous pouvez également consulter les sections dédiées dans l\'application.';
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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2563FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFF2563FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Assistant IA'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Effacer l'historique (réinitialiser la conversation)
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'content': 'Bonjour ! Je suis votre assistant santé THIX. Comment puis-je vous aider aujourd\'hui ?',
                  'timestamp': DateTime.now(),
                });
              });
            },
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final time = DateFormat('HH:mm').format(msg['timestamp']);
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF2563FF)
                          : Colors.grey[200],
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
                      crossAxisAlignment: isUser
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['content'],
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Indicateur de traitement
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2563FF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'L\'IA réfléchit...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Zone de saisie
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Posez votre question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563FF),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
