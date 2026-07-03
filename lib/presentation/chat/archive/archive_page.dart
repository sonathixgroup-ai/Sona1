// lib/presentation/chat/archive/archive_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/providers/chat_provider.dart'; // ✅ chemin correct
import 'package:thix_id/models/chat_models.dart'; // ✅ pour le type Conversation
import 'archive_list_item.dart';
import 'advanced_search_sheet.dart';
import 'search_filters.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    _chatProvider = context.read<ChatProvider>();
    _chatProvider.loadArchivedConversations();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final archivedConversations = chatProvider.archivedConversations;
    final isLoading = chatProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showAdvancedSearch(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : archivedConversations.isEmpty
              ? const Center(child: Text('Aucune conversation archivée'))
              : ListView.builder(
                  itemCount: archivedConversations.length,
                  itemBuilder: (context, index) {
                    final conv = archivedConversations[index];
                    return ArchiveListItem(
                      conversation: conv,
                      onUnarchive: () {
                        _chatProvider.unarchiveConversation(conv.id);
                      },
                      onDelete: () {
                        _showDeleteDialog(conv.id);
                      },
                    );
                  },
                ),
    );
  }

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdvancedSearchSheet(
        onSearch: (SearchFilters filters) {
          _chatProvider.searchArchivedConversations(filters.toMap());
        },
      ),
    );
  }

  void _showDeleteDialog(String convId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement'),
        content: const Text('Cette conversation sera définitivement supprimée. Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _chatProvider.deleteArchivedConversation(convId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
