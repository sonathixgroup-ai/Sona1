// lib/presentation/chat/drafts/draft_preview.dart
// Widget d'aperçu du brouillon (affiché dans la barre de saisie)

import 'package:flutter/material.dart';
import 'draft_manager.dart';

class DraftPreview extends StatefulWidget {
  final String conversationId;
  final ValueChanged<String> onRestore;

  const DraftPreview({
    Key? key,
    required this.conversationId,
    required this.onRestore,
  }) : super(key: key);

  @override
  State<DraftPreview> createState() => _DraftPreviewState();
}

class _DraftPreviewState extends State<DraftPreview> {
  Draft? _draft;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await DraftManager.loadDraft(widget.conversationId);
    if (mounted) setState(() => _draft = draft);
  }

  @override
  Widget build(BuildContext context) {
    if (_draft == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: Colors.blue.shade300, width: 3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _draft!.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onRestore(_draft!.text);
              DraftManager.deleteDraft(widget.conversationId);
              setState(() => _draft = null);
            },
            child: const Text('Restaurer', style: TextStyle(fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              DraftManager.deleteDraft(widget.conversationId);
              setState(() => _draft = null);
            },
          ),
        ],
      ),
    );
  }
}
