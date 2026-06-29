import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/services/chat_service.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/utils/time_ago.dart';

class ChatDashboardScreen extends StatefulWidget {
  const ChatDashboardScreen({super.key});

  @override
  State<ChatDashboardScreen> createState() => _ChatDashboardScreenState();
}

class _ChatDashboardScreenState extends State<ChatDashboardScreen> {
  late final ChatService _chat = ChatService();
  late final TextEditingController _search = TextEditingController();
  StreamSubscription<List<ChatSummary>>? _sub;
  List<ChatSummary> _chats = const [];
  Object? _error;
  bool _loading = true;

  _ChatDashboardFilter _filter = _ChatDashboardFilter.all;

  @override
  void initState() {
    super.initState();
    // Defer subscription until after first build so Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bind());
  }

  void _bind() {
    final me = context.read<AuthController>().currentUser;
    if (me == null) {
      setState(() {
        _loading = false;
        _error = 'not_logged_in';
      });
      return;
    }

    _sub?.cancel();
    _sub = _chat.streamChatsForUser(me.id).listen((rows) {
      if (!mounted) return;
      setState(() {
        _chats = rows;
        _loading = false;
        _error = null;
      });
    }, onError: (e) {
      debugPrint('ChatDashboardScreen: stream failed err=$e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e;
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _search.dispose();
    super.dispose();
  }

  List<ChatSummary> _filteredChats() {
    final q = _search.text.trim().toLowerCase();
    Iterable<ChatSummary> rows = _chats;
    switch (_filter) {
      case _ChatDashboardFilter.all:
        break;
      case _ChatDashboardFilter.teams:
        rows = rows.where((c) => c.type == 'group');
        break;
      case _ChatDashboardFilter.calls:
        // Not implemented yet: keep empty until call events are supported.
        rows = const <ChatSummary>[];
        break;
      case _ChatDashboardFilter.favorites:
        // Not implemented yet: keep all for now.
        break;
      case _ChatDashboardFilter.appointments:
        // Not implemented yet: keep empty until scheduling is wired.
        rows = const <ChatSummary>[];
        break;
    }

    if (q.isEmpty) return rows.toList(growable: false);
    return rows.where((c) {
      final name = (c.participantName.values.join(' ') + ' ' + c.lastMessage).toLowerCase();
      return name.contains(q);
    }).toList(growable: false);
  }

  void _openChat(ChatSummary c) {
    final title = (c.type == 'group')
        ? (c.participantName.values.firstOrNull ?? 'Groupe')
        : (c.participantName.values.firstWhere((e) => e != 'Moi', orElse: () => 'Discussion'));
    context.push('${AppRoutes.chat}/${Uri.encodeComponent(c.id)}', extra: {'title': title, 'type': c.type});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final me = context.watch<AuthController>().currentUser;

    final chats = _filteredChats();
    final unread = chats.fold<int>(0, (sum, c) {
      final v = c.unreadCount;
      return sum + ((v is int) ? v : 0);
    });
    final groups = chats.where((c) => c.type == 'group').length;
    final onlineSeed = chats.take(8).toList(growable: false);

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: me == null
          ? null
          : _ChatCenterActionButton(
              onTap: () => _showNewChatSheet(context, _chat),
            ),
      bottomNavigationBar: _ChatBottomNav(
        active: _ChatBottomTab.chats,
        onHome: () => context.go(AppRoutes.home),
        onChats: () => context.go(AppRoutes.chat),
        onSpaces: () => context.go(AppRoutes.network),
        onProfile: () {
          final auth = context.read<AuthController>();
          if (!auth.isAuthenticated) {
            context.push(AppRoutes.login);
            return;
          }
          final t = auth.currentUser?.accountType;
          context.go(t == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.userDashboard);
        },
      ),
      body: Stack(
        children: [
          const _ChatBackdrop(),
          SafeArea(
            child: Row(
              children: [
                SizedBox(
                  width: isWide ? 420 : MediaQuery.sizeOf(context).width,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ChatDashboardHeader(
                          onMenu: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu: à connecter'))),
                          onSearchTap: () {},
                          onNotificationsTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifications: à connecter'))),
                          onProfileTap: () {
                            final auth = context.read<AuthController>();
                            if (!auth.isAuthenticated) {
                              context.push(AppRoutes.login);
                              return;
                            }
                            final t = auth.currentUser?.accountType;
                            context.go(t == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.userDashboard);
                          },
                          notificationCount: unread.clamp(0, 99),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _GlassSearchField(controller: _search, onChanged: (_) => setState(() {})),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _StatsStrip(
                          onlineCount: onlineSeed.length,
                          newMessagesCount: unread,
                          meetingsCount: 0,
                          securityAlertsCount: 0,
                          onChevronTap: () {},
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _OnlineRow(
                          users: onlineSeed.map((c) => _OnlineUserSeed(name: _displayNameForChat(c))).toList(growable: false),
                          onViewAll: () {},
                          onNewStory: () => _showNewChatSheet(context, _chat),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ChatCategoryTabs(
                          value: _filter,
                          onChanged: (v) => setState(() => _filter = v),
                          groupCount: groups,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _SectionHeader(
                          title: 'Conversations récentes',
                          trailingLabel: 'Filtres',
                          onTrailingTap: _bind,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ChatList(
                          loading: _loading,
                          error: _error,
                          chats: chats,
                          onTapChat: _openChat,
                          onRetry: _bind,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isWide)
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 540),
                        child: _EmptyConversationHint(colorScheme: cs),
                      ),
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

class _ChatBackdrop extends StatelessWidget {
  const _ChatBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c0 = isDark ? EventsCyberColors.bg0 : LightModeColors.background;
    final c1 = isDark ? EventsCyberColors.bg1 : Colors.white;
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c0, c1],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onNewChat;
  final VoidCallback onRefresh;
  const _TopBar({required this.onNewChat, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text('THIX CHAT', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Connectez-vous. Échangez. Avancez.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        _GlassIconButton(icon: Icons.refresh_rounded, tooltip: 'Rafraîchir', onTap: onRefresh),
        const SizedBox(width: 8),
        _GlassIconButton(icon: Icons.add_rounded, tooltip: 'Nouveau chat', onTap: onNewChat),
      ],
    );
  }
}

String _displayNameForChat(ChatSummary c) {
  final title = (c.type == 'group')
      ? (c.participantName.values.firstOrNull ?? 'Groupe')
      : (c.participantName.values.firstWhere((e) => e != 'Moi', orElse: () => 'Discussion'));
  return title.trim().isEmpty ? 'Discussion' : title.trim();
}

enum _ChatDashboardFilter { all, teams, calls, favorites, appointments }

class _ChatDashboardHeader extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback onSearchTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final int notificationCount;
  const _ChatDashboardHeader({
    required this.onMenu,
    required this.onSearchTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    required this.notificationCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        _RoundIconButton(icon: Icons.menu_rounded, onTap: onMenu),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('THIX CHAT', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.2)),
              const SizedBox(height: 2),
              Text('Connectez-vous. Échangez. Avancez.', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(icon: Icons.search_rounded, onTap: onSearchTap),
        const SizedBox(width: 10),
        _NotificationBell(count: notificationCount, onTap: onNotificationsTap),
        const SizedBox(width: 10),
        _ProfileDotAvatar(onTap: onProfileTap),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: cs.onSurface),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _RoundIconButton(icon: Icons.notifications_none_rounded, onTap: onTap),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
              child: Text(count > 99 ? '99+' : '$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _ProfileDotAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _ProfileDotAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            child: Icon(Icons.person_rounded, color: cs.primary),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: LightModeColors.success, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final int onlineCount;
  final int newMessagesCount;
  final int meetingsCount;
  final int securityAlertsCount;
  final VoidCallback onChevronTap;
  const _StatsStrip({
    required this.onlineCount,
    required this.newMessagesCount,
    required this.meetingsCount,
    required this.securityAlertsCount,
    required this.onChevronTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Expanded(child: _StatItem(icon: Icons.group_rounded, label: 'En ligne', value: onlineCount.toString(), color: LightModeColors.success)),
          _StatDivider(color: cs.outlineVariant.withValues(alpha: 0.35)),
          Expanded(child: _StatItem(icon: Icons.chat_bubble_rounded, label: 'Nouveaux\nmessages', value: newMessagesCount.toString(), color: cs.primary)),
          _StatDivider(color: cs.outlineVariant.withValues(alpha: 0.35)),
          Expanded(child: _StatItem(icon: Icons.videocam_rounded, label: 'Réunions\nactives', value: meetingsCount.toString(), color: LightModeColors.secondary)),
          _StatDivider(color: cs.outlineVariant.withValues(alpha: 0.35)),
          Expanded(child: _StatItem(icon: Icons.shield_rounded, label: 'Alertes\nsécurité', value: securityAlertsCount.toString(), color: LightModeColors.error)),
          const SizedBox(width: 6),
          _RoundIconButton(icon: Icons.chevron_right_rounded, onTap: onChevronTap),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final Color color;
  const _StatDivider({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 44, color: color);
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, height: 1.2)),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnlineUserSeed {
  final String name;
  const _OnlineUserSeed({required this.name});
}

class _OnlineRow extends StatelessWidget {
  final List<_OnlineUserSeed> users;
  final VoidCallback onViewAll;
  final VoidCallback onNewStory;
  const _OnlineRow({required this.users, required this.onViewAll, required this.onNewStory});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Text('En ligne', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(foregroundColor: cs.primary, padding: EdgeInsets.zero),
              child: const Text('Voir tout  ›'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: users.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                return _OnlineAvatarTile(
                  name: 'Nouvelle\nhistoire',
                  isAdd: true,
                  onTap: onNewStory,
                );
              }
              final u = users[i - 1];
              return _OnlineAvatarTile(name: u.name, isAdd: false, onTap: () {});
            },
          ),
        ),
      ],
    );
  }
}

class _OnlineAvatarTile extends StatelessWidget {
  final String name;
  final bool isAdd;
  final VoidCallback onTap;
  const _OnlineAvatarTile({required this.name, required this.isAdd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [cs.primary, cs.primaryContainer]),
                  ),
                  child: Center(
                    child: isAdd
                        ? Icon(Icons.add_rounded, color: cs.onPrimary, size: 26)
                        : Text(initial, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w900)),
                  ),
                ),
                if (!isAdd)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: LightModeColors.success, shape: BoxShape.circle, border: Border.all(color: cs.surface, width: 2)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(name, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant, height: 1.1)),
          ],
        ),
      ),
    );
  }
}

class _ChatCategoryTabs extends StatelessWidget {
  final _ChatDashboardFilter value;
  final ValueChanged<_ChatDashboardFilter> onChanged;
  final int groupCount;
  const _ChatCategoryTabs({required this.value, required this.onChanged, required this.groupCount});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = <(_ChatDashboardFilter, String, IconData)>[
      (_ChatDashboardFilter.all, 'Tous', Icons.chat_rounded),
      (_ChatDashboardFilter.teams, 'Equipes', Icons.groups_rounded),
      (_ChatDashboardFilter.calls, 'Appels', Icons.call_rounded),
      (_ChatDashboardFilter.favorites, 'Favoris', Icons.star_rounded),
      (_ChatDashboardFilter.appointments, 'Rendez-vous', Icons.event_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          for (final it in items) ...[
            Expanded(
              child: _CategoryChip(
                icon: it.$3,
                label: it.$2,
                selected: value == it.$1,
                onTap: () => onChanged(it.$1),
                badge: it.$1 == _ChatDashboardFilter.teams && groupCount > 0 ? groupCount : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;
  const _CategoryChip({required this.icon, required this.label, required this.selected, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primary : Colors.transparent;
    final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w800))),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: selected ? cs.onPrimary.withValues(alpha: 0.18) : cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text('$badge', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: selected ? cs.onPrimary : cs.primary, fontWeight: FontWeight.w900)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailingLabel;
  final VoidCallback onTrailingTap;
  const _SectionHeader({required this.title, required this.trailingLabel, required this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const Spacer(),
        TextButton.icon(
          onPressed: onTrailingTap,
          icon: Icon(Icons.tune_rounded, size: 18, color: cs.primary),
          label: Text(trailingLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

enum _ChatBottomTab { home, chats, spaces, profile }

class _ChatBottomNav extends StatelessWidget {
  final _ChatBottomTab active;
  final VoidCallback onHome;
  final VoidCallback onChats;
  final VoidCallback onSpaces;
  final VoidCallback onProfile;
  const _ChatBottomNav({required this.active, required this.onHome, required this.onChats, required this.onSpaces, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomNavItem(icon: Icons.home_rounded, label: 'Accueil', active: active == _ChatBottomTab.home, onTap: onHome),
            _BottomNavItem(icon: Icons.chat_bubble_rounded, label: 'Chats', active: active == _ChatBottomTab.chats, onTap: onChats),
            const SizedBox(width: 56),
            _BottomNavItem(icon: Icons.grid_view_rounded, label: 'Spaces', active: active == _ChatBottomTab.spaces, onTap: onSpaces),
            _BottomNavItem(icon: Icons.person_rounded, label: 'Profil', active: active == _ChatBottomTab.profile, onTap: onProfile),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BottomNavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = active ? ThixHomeColors.goldBadge : cs.onPrimary.withValues(alpha: 0.72);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ChatCenterActionButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ChatCenterActionButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
          ),
          child: Icon(Icons.add_rounded, color: cs.onPrimary, size: 30),
        ),
      ),
    );
  }
}

class _GlassSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _GlassSearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.72),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Rechercher un chat, contact, groupe…',
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  final bool loading;
  final Object? error;
  final List<ChatSummary> chats;
  final ValueChanged<ChatSummary> onTapChat;
  final VoidCallback onRetry;

  const _ChatList({
    required this.loading,
    required this.error,
    required this.chats,
    required this.onTapChat,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _ChatListSkeleton();

    if (error != null) {
      return _InlineStateCard(
        icon: Icons.wifi_off_rounded,
        title: error == 'not_logged_in' ? 'Connexion requise' : 'Impossible de charger vos messages',
        subtitle: error == 'not_logged_in'
            ? 'Connectez-vous pour accéder à THIX CHAT.'
            : 'Vérifiez votre connexion puis réessayez.',
        actionLabel: 'Réessayer',
        onAction: onRetry,
      );
    }

    if (chats.isEmpty) {
      return const _InlineStateCard(
        icon: Icons.forum_rounded,
        title: 'Aucune conversation',
        subtitle: 'Démarrez un chat avec un contact ou créez un groupe.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final c = chats[index];
        final title = (c.type == 'group')
            ? (c.participantName.values.firstOrNull ?? 'Groupe')
            : (c.participantName.values.firstWhere((e) => e != 'Moi', orElse: () => 'Discussion'));
        final time = c.lastMessageAt == null ? '' : formatTimeAgo(c.lastMessageAt!);
        return _ConversationTile(
          title: title,
          subtitle: c.lastMessage,
          time: time,
          isGroup: c.type == 'group',
          onTap: () => onTapChat(c),
        );
      },
    );
  }
}

class _ConversationTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String time;
  final bool isGroup;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isGroup,
    required this.onTap,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _pressed = false;
  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.78),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  _AvatarPill(title: widget.title, isGroup: widget.isGroup),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(widget.subtitle.isEmpty ? ' ' : widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(widget.time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPill extends StatelessWidget {
  final String title;
  final bool isGroup;
  const _AvatarPill({required this.title, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.16);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isGroup ? 14 : 999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.20)),
      ),
      alignment: Alignment.center,
      child: Text(
        (title.trim().isEmpty ? 'T' : title.trim())[0].toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  const _GlassIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.70),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: onTap == null ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.76),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: cs.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(height: 14),
                      FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatListSkeleton extends StatelessWidget {
  const _ChatListSkeleton();

  @override
  Widget build(BuildContext context) {
    // No external shimmer package: lightweight animated opacity.
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
      itemCount: 10,
      itemBuilder: (_, i) => const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: _SkeletonTile(),
      ),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile();

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }
}

class _EmptyConversationHint extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyConversationHint({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.72),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.25)),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 42, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text('Sélectionnez une conversation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Vos messages apparaîtront ici, en temps réel.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showNewChatSheet(BuildContext context, ChatService chat) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _NewChatSheet(chat: chat),
  );
}

class _NewChatSheet extends StatefulWidget {
  final ChatService chat;
  const _NewChatSheet({required this.chat});

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final TextEditingController _q = TextEditingController();
  bool _loading = false;
  List<ChatContact> _results = const [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(v));
  }

  Future<void> _search(String v) async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;
    final q = v.trim();
    if (q.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    setState(() => _loading = true);
    try {
      final rows = await widget.chat.searchProfiles(q);
      if (!mounted) return;
      setState(() => _results = rows.where((e) => e.uid != me.id).toList(growable: false));
    } catch (e) {
      debugPrint('NewChatSheet: search failed err=$e');
      if (!mounted) return;
      setState(() => _results = const []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startDirect(ChatContact c) async {
    final me = context.read<AuthController>().currentUser;
    if (me == null) return;
    try {
      final other = me.copyWith(id: c.uid, displayName: c.displayName, thixId: c.thixId);
      final id = await widget.chat.getOrCreateDirectChat(me: me, other: other);
      if (!mounted) return;
      context.pop();
      // Open conversation.
      context.push('${AppRoutes.chat}/${Uri.encodeComponent(id)}', extra: {'title': c.displayName, 'type': 'direct'});
    } catch (e) {
      debugPrint('NewChatSheet: startDirect failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: cs.surface.withValues(alpha: 0.92),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 46, height: 5, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Nouveau chat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.close_rounded, color: cs.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _q,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom ou THIX ID…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.65))),
                  ),
                ),
                const SizedBox(height: 12),
                if (_loading) const LinearProgressIndicator(minHeight: 3),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)),
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      return ListTile(
                        onTap: () => _startDirect(r),
                        leading: CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.12), child: Text(r.displayName.isEmpty ? '?' : r.displayName[0].toUpperCase(), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800))),
                        title: Text(r.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: r.thixId.trim().isEmpty ? null : Text(r.thixId, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
