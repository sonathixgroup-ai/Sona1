// lib/presentation/chat/drafts/draft_list_sheet.dart
// Feuille modale listant tous les brouillons (pour les retrouver facilement)

import 'package:flutter/material.dart';
import 'draft_manager.dart';

class DraftListSheet extends StatefulWidget {
  final Function(String conversationId, String draftText) onSelectDraft;

  const DraftListSheet({Key? key, required this.onSelectDraft}) : super(key: key);

  @override
  State<DraftListSheet> createState() => _DraftListSheetState();
}

class _DraftListSheetState extends State<DraftListSheet> {
  List<Draft> _drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final drafts = await DraftManager.getAllDrafts();
    if (mounted) setState(() => _drafts = drafts);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Brouillons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_drafts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('Aucun brouillon')),
            )
          else
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _drafts.length,
                itemBuilder: (context, index) {
                  final draft = _drafts[index];
                  return ListTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(
                      draft.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Conversation ${draft.conversationId} • ${_formatDate(draft.lastEdited)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await DraftManager.deleteDraft(draft.conversationId);
                        _loadDrafts();
                      },
                    ),
                    onTap: () {
                      widget.onSelectDraft(draft.conversationId, draft.text);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _drafts.isEmpty ? null : () => _cleanAll(),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
  }

  void _cleanAll() async {
    final drafts = await DraftManager.getAllDrafts();
    for (var d in drafts) {
      await DraftManager.deleteDraft(d.conversationId);
    }
    _loadDrafts();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tous les brouillons supprimés')));
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Aujourd\'hui ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
