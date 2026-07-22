import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  
  AiProvider _selectedProvider = AiProvider.mistral; 
  String _userName = "Utilisateur";

  @override
  void initState() {
    super.initState();
    _aiService = AiService(Supabase.instance.client);
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, display_name')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['display_name'] ?? profile['full_name'] ?? "Utilisateur";
          _userName = _userName.split(' ').first; 
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? textOverride}) async {
    final text = textOverride ?? _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.askAi(
        prompt: text,
        provider: _selectedProvider,
        systemPrompt: "Tu es THIX IA, l'intelligence artificielle avancée de Sonathix Group. Tu fournis des réponses claires, professionnelles et bien structurées.",
      );

      setState(() {
        _messages.add({'role': 'ai', 'text': response});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'ai', 
          'text': '⚠️ Une erreur est survenue lors de la communication avec le serveur. Vérifiez votre connexion.'
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
    const bgColor = Color(0xFFF7F9FF);
    const primaryBlue = Color(0xFF1877F2);
    const darkText = Color(0xFF111827);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkText),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome, color: primaryBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'THIX IA', 
              style: TextStyle(fontWeight: FontWeight.w900, color: darkText, fontSize: 18, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AiProvider>(
                  value: _selectedProvider,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: primaryBlue),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkText),
                  onChanged: (AiProvider? newValue) {
                    if (newValue != null) setState(() => _selectedProvider = newValue);
                  },
                  items: const [
                    DropdownMenuItem(value: AiProvider.mistral, child: Text('Mistral')),
                    DropdownMenuItem(value: AiProvider.openai, child: Text('OpenAI')),
                    DropdownMenuItem(value: AiProvider.anthropic, child: Text('Claude')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
                ? _buildWelcomeScreen(primaryBlue, darkText)
                : _buildChatList(primaryBlue, darkText),
          ),
          
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: primaryBlue, size: 16),
                  const SizedBox(width: 12),
                  Text("THIX IA réfléchit...", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          if (_messages.isEmpty)
             _buildQuickActions(),

          _buildInputArea(primaryBlue),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen(Color primary, Color darkText) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1877F2), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Bonjour, $_userName ! 👋',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: darkText, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Comment puis-je vous aider aujourd\'hui ?',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(Color primary, Color darkText) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';

        if (isUser) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, left: 40),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1877F2), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                msg['text']!,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
              ),
            ),
          );
        } else {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16, right: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.grey.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 16),
                      const SizedBox(width: 8),
                      Text("THIX IA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    msg['text']!,
                    style: TextStyle(color: darkText, fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildQuickActions() {
    final actions = ["Analyser mes données", "Rédiger un email pro", "Traduire un texte", "Générer des idées"];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(actions[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              elevation: 0,
              onPressed: () => _sendMessage(textOverride: actions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 2, right: 10),
                decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(Icons.add_rounded, color: primary),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("L'ajout de fichiers arrive bientôt !")));
                  },
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Posez votre question...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: primary,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            onPressed: _isLoading ? null : () => _sendMessage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "THIX IA peut faire des erreurs. Vérifiez les informations importantes.",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
