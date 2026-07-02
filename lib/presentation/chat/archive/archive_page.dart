// lib/presentation/chat/archive/archive_page.dart
// Page listant toutes les conversations archivées

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/chat_bloc.dart';
import '../core/chat_states.dart';
import '../core/chat_events.dart';
import '../widgets/conversation_tile.dart';
import 'archive_list_item.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({Key? key}) : super(key: key);

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadArchivedConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showAdvancedSearch(),
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        bloc: _chatBloc,
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ArchivedConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return const Center(child: Text('Aucune conversation archivée'));
            }
            return ListView.builder(
              itemCount: state.conversations.length,
              itemBuilder: (context, index) {
                final conv = state.conversations[index];
                return ArchiveListItem(
                  conversation: conv,
                  onUnarchive: () {
                    _chatBloc.add(UnarchiveConversation(conv.id));
                  },
                  onDelete: () {
                    _showDeleteDialog(conv.id);
                  },
                );
              },
            );
          } else if (state is ChatError) {
            return Center(child: Text('Erreur: ${state.message}'));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAdvancedSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdvancedSearchSheet(
        onSearch: (filters) {
          _chatBloc.add(SearchArchivedConversations(filters));
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
              _chatBloc.add(DeleteArchivedConversation(convId));
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
