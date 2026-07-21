import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// N'oublie pas d'importer ton AiService en ajustant le chemin selon ton dossier
import '../../services/ai/ai_service.dart'; 

class ThixIaScreen extends StatefulWidget {
  const ThixIaScreen({Key? key}) : super(key: key);

  @override
  State<ThixIaScreen> createState() => _ThixIaScreenState();
}

class _ThixIaScreenState extends State<ThixIaScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late final AiService _aiService;
  
  // Liste pour stocker la conversation en local
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  
  // L'IA sélectionnée par défaut
  AiProvider _selectedProvider = AiProvider.mistral; 

  @override
  void initState() {
    super.initState();
    _aiService = AiService(Supabase.instance.client);
    
    // Message de bienvenue par défaut
    _messages.add({
      'role': 'ai',
      'text': 'Mbote ! Je suis THIX IA. Comment puis-je t\'aider aujourd\'hui ?'
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 1. Ajouter le message de l'utilisateur à l'écran
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    // 2. Appeler la Edge Function via AiService
    try {
      final response = await _aiService.askAi(
        prompt: text,
        provider: _selectedProvider,
        systemPrompt: "Tu es THIX IA, un assistant virtuel intelligent et utile conçu par Sonathix Group. Tu réponds de manière claire et concise.",
      );

      // 3. Ajouter la réponse de l'IA à l'écran
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai', 
          'text': 'Oups, une erreur s\'est produite. Vérifie ta connexion ou réessaie. ($e)'
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THIX IA', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // Sélecteur de modèle d'IA
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<AiProvider>(
              value: _selectedProvider,
              icon: const Icon(Icons.psychology, color: Colors.blueAccent),
              underline: const SizedBox(),
              onChanged: (AiProvider? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedProvider = newValue;
                  });
                }
              },
              items: const [
                DropdownMenuItem(
                  value: AiProvider.mistral,
                  child: Text('Mistral'),
                ),
                DropdownMenuItem(
                  value: AiProvider.openai,
                  child: Text('OpenAI'),
                ),
                DropdownMenuItem(
                  value: AiProvider.anthropic,
                  child: Text('Claude'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Zone d'affichage des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12, maxLines: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blueAccent : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Indicateur de chargement
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CircularProgressIndicator(),
              ),
            ),
            
          // Zone de saisie de texte
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Pose une question à THIX IA...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
