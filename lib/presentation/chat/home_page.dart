// lib/presentation/chat/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thix_id/presentation/chat/core/chat_bloc.dart';
import 'package:thix_id/presentation/chat/core/chat_events.dart';
import 'package:thix_id/presentation/chat/core/chat_states.dart';
import 'package:thix_id/presentation/chat/widgets/conversation_tile.dart';
import 'package:thix_id/presentation/chat/widgets/chat_stats_row.dart';
import 'package:thix_id/presentation/chat/widgets/stories_row.dart';
import 'package:thix_id/presentation/chat/widgets/chat_filters.dart';
import 'package:thix_id/presentation/chat/home_widgets/bottom_nav_bar.dart';
import 'package:thix_id/presentation/chat/home_widgets/chat_home_appbar.dart';

class ChatHomePage extends StatelessWidget {
  const ChatHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const ChatHomeAppbar(),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationsLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ChatBloc>().add(LoadConversations());
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ChatStatsRow(
                      onlineCount: state.stats.onlineCount,
                      newMessagesCount: state.stats.newMessagesCount,
                      activeMeetingsCount: state.stats.activeMeetingsCount,
                      securityAlertsCount: state.stats.securityAlertsCount,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: StoriesRow(stories: state.stories),
                  ),
                  SliverToBoxAdapter(
                    child: ChatFilters(
                      selectedFilter: state.selectedFilter,
                      onFilterSelected: (filter) {
                        context.read<ChatBloc>().add(FilterConversations(filter));
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final conv = state.filteredConversations[index];
                          return ConversationTile(
                            id: conv.id,
                            name: conv.name,
                            lastMessage: conv.lastMessage ?? 'Aucun message',
                            time: _formatTime(conv.lastMessageTime),
                            unreadCount: conv.unreadCount,
                            avatarUrl: conv.avatarUrl,
                            isOnline: conv.isOnline,
                            isGroup: conv.isGroup,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/chat/conversation',
                                arguments: conv.id,
                              );
                            },
                          );
                        },
                        childCount: state.filteredConversations.length,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is ChatError) {
            return Center(child: Text('Erreur : ${state.message}'));
          }
          return const Center(child: Text('Aucune conversation'));
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return _weekdayShort(time.weekday);
    } else {
      return '${time.day}/${time.month}';
    }
  }

  String _weekdayShort(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }
}
