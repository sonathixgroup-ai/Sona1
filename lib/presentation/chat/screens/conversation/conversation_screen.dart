import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/message_model.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ai_chat_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ConversationScreen({Key? key, required this.conversationId}) : super(key: key);

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  late ScrollController _scrollController;
  String? _replyingToId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<String> _messageTexts(List<Message> messages) {
    return messages.map((m) => m.content).whereType<String>().toList(growable: false);
  }

  Future<void> _showAiSheet() async {
    final messages = ref.read(messagesProvider);
    final texts = _messageTexts(messages);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DefaultTabController(
          length: 4,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 48, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(100))),
                const SizedBox(height: 12),
                const TabBar(
                  tabs: [
                    Tab(text: 'Résumé'),
                    Tab(text: 'Réponses'),
                    Tab(text: 'Sentiment'),
                    Tab(text: 'Traduire'),
                  ],
                ),
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    children: [
                      _AiActionPanel(
                        title: 'Résumé',
                        actionLabel: 'Générer le résumé',
                        onRun: () => ref.read(aiChatControllerProvider.notifier).summarizeConversation(conversationId: widget.conversationId, messages: texts),
                      ),
                      _AiActionPanel(
                        title: 'Smart Replies',
                        actionLabel: 'Proposer des réponses',
                        onRun: () => ref.read(aiChatControllerProvider.notifier).generateSmartReplies(conversationId: widget.conversationId, messages: texts),
                      ),
                      _AiActionPanel(
                        title: 'Sentiment',
                        actionLabel: 'Analyser le sentiment',
                        onRun: () => ref.read(aiChatControllerProvider.notifier).analyzeConversation(conversationId: widget.conversationId, messages: texts),
                      ),
                      _TranslatePanel(
                        onRun: (lang) => ref.read(aiChatControllerProvider.notifier).translateMessage(conversationId: widget.conversationId, message: texts.isNotEmpty ? texts.last : '', targetLanguage: lang),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider);
    final conversation = ref.watch(currentConversationProvider);
    final aiState = ref.watch(aiChatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(conversation?.name ?? 'Conversation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _showAiSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          if (aiState.valueOrNull?.result != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _AiResultCard(result: aiState.valueOrNull!.result!),
            ),
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Aucun message'))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.senderId == 'current_user_id';
                      return ListTile(
                        title: Text(message.content),
                        subtitle: Text(isCurrentUser ? 'Vous' : message.senderName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AiActionPanel extends StatelessWidget {
  const _AiActionPanel({required this.title, required this.actionLabel, required this.onRun});

  final String title;
  final String actionLabel;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRun, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _TranslatePanel extends StatefulWidget {
  const _TranslatePanel({required this.onRun});
  final ValueChanged<String> onRun;

  @override
  State<_TranslatePanel> createState() => _TranslatePanelState();
}

class _TranslatePanelState extends State<_TranslatePanel> {
  final _controller = TextEditingController(text: 'en');
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Langue cible'),
            const SizedBox(height: 12),
            TextField(controller: _controller),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => widget.onRun(_controller.text.trim()), child: const Text('Traduire le dernier message')),
          ],
        ),
      ),
    );
  }
}

class _AiResultCard extends StatelessWidget {
  const _AiResultCard({required this.result});
  final dynamic result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.summary != null) Text('Résumé: ${result.summary}'),
            if (result.translation != null) Text('Traduction: ${result.translation}'),
            if (result.sentiment != null) Text('Sentiment: ${result.sentiment} (${(result.confidence ?? 0).toStringAsFixed(2)})'),
            if (result.smartReplies.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Réponses suggérées:'),
              ...result.smartReplies.map((r) => Text('• $r')),
            ],
          ],
        ),
      ),
    );
  }
}
