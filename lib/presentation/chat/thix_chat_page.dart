// lib/presentation/chat/thix_chat_page.dart
// Page d'accueil du module THIX Chat : liste des conversations, stories, stats

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/chat_bloc.dart';
import 'core/chat_states.dart';
import 'core/chat_events.dart';
import 'widgets/conversation_tile.dart';
import 'widgets/stories_row.dart';
import 'widgets/chat_stats_row.dart';
import 'widgets/chat_filters.dart';

class ThixChatPage extends StatefulWidget {
  const ThixChatPage({Key? key}) : super(key: key);

  @override
  State<ThixChatPage> createState() => _ThixChatPageState();
}

class _ThixChatPageState extends State<ThixChatPage> {
  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = context.read<ChatBloc>();
    _chatBloc.add(LoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('THIX Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archives',
            onPressed: () => context.push('/chat/archive'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: () => context.push('/chat/translation/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _chatBloc.add(LoadConversations()),
        child: BlocBuilder<ChatBloc, ChatState>(
          bloc: _chatBloc,
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatError) {
              return Center(child: Text('Erreur : ${state.message}'));
            }
            if (state is ConversationsLoaded) {
              return ListView(
                children: [
                  if (state.stories.isNotEmpty) StoriesRow(stories: state.stories),
                  ChatStatsRow(stats: state.stats),
                  ChatFilters(
                    selectedFilter: state.selectedFilter,
                    onFilterSelected: (filter) => _chatBloc.add(FilterConversations(filter)),
                  ),
                  const Divider(height: 1),
                  if (state.filteredConversations.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Aucune conversation')),
                    )
                  else
                    ...state.filteredConversations.map((conv) {
                      return ConversationTile(
                        conversation: conv,
                        onTap: () => context.push(
                          '/chat/${Uri.encodeComponent(conv.id)}',
                          extra: {'title': conv.name, 'type': conv.isGroup ? 'group' : 'direct'},
                        ),
                      );
                    }),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO : démarrer une nouvelle conversation
        },
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
