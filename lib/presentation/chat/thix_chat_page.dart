import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/services/call_service.dart';
import 'package:thix_id/services/chat_service.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/services/presence_service.dart';
import 'package:thix_id/services/status_service.dart';
import 'package:thix_id/services/thix_id_service.dart';
import 'package:thix_id/theme.dart';
import 'package:thix_id/nav.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:thix_id/presentation/chat/thix_agora_call_sheet.dart';

// ============================================================================
// GRADIENT
// ============================================================================
class AppPremiumGradients {
  static LinearGradient thixNavyToGold(ColorScheme scheme) {
    return LinearGradient(
      colors: [scheme.primary, scheme.tertiary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ============================================================================
// PAGE PRINCIPALE THIX CHAT (UI PREMIUM)
// ============================================================================
class ThixChatPage extends StatefulWidget {
  const ThixChatPage({super.key});

  @override
  State<ThixChatPage> createState() => _ThixChatPageState();
}

class _ThixChatPageState extends State<ThixChatPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _chat = ChatService();
  final _status = StatusService();
  final _calls = CallService();
  final _presence = PresenceService();
  final _counters = NotificationCountersService();
  final _homeSearch = TextEditingController();

  String _searchQuery = '';
  StreamSubscription<List<ThixCall>>? _incomingCallsSub;
  String? _incomingForUid;
  bool _incomingSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _homeSearch.addListener(() {
      final next = _homeSearch.text.trim().toLowerCase();
      if (next == _searchQuery) return;
      setState(() => _searchQuery = next);
    });
    unawaited(_presence.setOnline(true));
    _presence.startHeartbeat();
  }

  @override
  void dispose() {
    unawaited(_incomingCallsSub?.cancel());
    _presence.stopHeartbeat();
    unawaited(_presence.setOnline(false));
    _homeSearch.dispose();
    _tabs.dispose();
    super.dispose();
  }

  void _ensureIncomingCallListener(AppUser me) {
    if (_incomingForUid == me.id) return;
    _incomingForUid = me.id;
    unawaited(_incomingCallsSub?.cancel());
    _incomingCallsSub = _calls.streamIncomingOngoingCalls(receiverId: me.id).listen((calls) {
      if (!mounted) return;
      if (calls.isEmpty) return;
      if (_incomingSheetOpen) return;
      final c = calls.first;
      _incomingSheetOpen = true;
      unawaited(_showIncomingCallSheet(me: me, call: c));
    });
  }

  Future<void> _showIncomingCallSheet({required AppUser me, required ThixCall call}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _IncomingCallSheet(
        kind: call.kind,
        callerId: call.callerId,
        onDecline: () async {
          try {
            await _calls.setCallStatus(callId: call.id, status: 'declined');
          } catch (e) {
            debugPrint('IncomingCall: decline failed err=$e');
          }
          if (context.mounted) context.pop();
        },
        onAccept: () async {
          if (!context.mounted) return;
          context.pop();
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            useSafeArea: true,
            builder: (_) => ThixAgoraCallSheet(
              callId: call.id,
              otherUserId: call.callerId,
              kind: call.kind,
              isCaller: false,
              calls: _calls,
            ),
          );
        },
      ),
    );
    _incomingSheetOpen = false;
  }

  AppUser? _me(BuildContext context) => context.read<AuthController>().currentUser;

  // ==================== NAVIGATION ====================
  Future<void> _openNewChat() async {
    final me = _me(context);
    if (me == null) return;
    final pick = await showModalBottomSheet<_NewChatPick?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixChatNewChatSheet(me: me, chat: _chat),
    );
    if (pick != null && mounted) {
      await _openThreadSheet(chatId: pick.chatId, otherUid: pick.otherUid, otherName: pick.title);
    }
  }

  Future<void> _openSearch() async {
    final me = _me(context);
    if (me == null) return;
    final selected = await showModalBottomSheet<_SearchPick?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixChatSearchSheet(me: me, chat: _chat),
    );
    if (selected != null && mounted) {
      await _startChatWith(selected.uid, selected.displayName, selected.thixId);
    }
  }

  Future<void> _startChatWith(String uid, String name, String thixId) async {
    final me = _me(context);
    if (me == null) return;
    final other = AppUser(
      id: uid,
      thixId: thixId,
      thixChat: '',
      thixScore: null,
      email: '',
      phone: null,
      displayName: name,
      accountType: AccountType.personal,
      photoUrl: null,
      bio: null,
      countryOrOrigin: null,
      contactPhone: null,
      maritalStatus: null,
      gender: null,
      occupation: null,
      profession: null,
      dateOfBirth: null,
      placeOfBirth: null,
      nationality: null,
      address: null,
      fatherName: null,
      motherName: null,
      emergencyContactName: null,
      emergencyContactPhone: null,
      emergencyContactRelation: null,
      education: const [],
      experience: const [],
      skills: const [],
      enrollments: const [],
      languages: const [],
      biometricsEnabled: true,
      twoFaEnabled: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final chatId = await _chat.getOrCreateDirectChat(me: me, other: other);
    if (mounted) await _openThreadSheet(chatId: chatId, otherUid: uid, otherName: name);
  }

  Future<void> _openGroups() async {
    final me = _me(context);
    if (me == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixGroupComposerSheet(me: me, chat: _chat),
    );
  }

  Future<void> _openCalls() async {
    final me = _me(context);
    if (me == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixCallLauncherSheet(me: me, chat: _chat, calls: _calls),
    );
  }

  Future<void> _openStatusComposer() async {
    final me = _me(context);
    if (me == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixBottomSheetShell(
        title: 'Nouvelle histoire',
        subtitle: 'Publiez un statut texte, photo, vidéo ou audio.',
        child: ThixStatusComposer(me: me, status: _status),
      ),
    );
  }

  Future<void> _openThreadSheet({required String chatId, required String otherUid, required String otherName}) async {
    final me = _me(context);
    if (me == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixChatThreadSheet(
        me: me,
        chatId: chatId,
        otherUid: otherUid,
        otherName: otherName,
        chat: _chat,
        calls: _calls,
      ),
    );
  }

  Future<void> _openStartByThixId(BuildContext context, AppUser me) async {
    final selected = await showModalBottomSheet<_SearchPick?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixStartChatByThixIdSheet(me: me, chat: _chat),
    );
    if (selected != null && mounted) {
      await _startChatWith(selected.uid, selected.displayName, selected.thixId);
    }
  }

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    if (me == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: AppSpacing.paddingLg,
            child: Text(
              'Veuillez vous connecter pour accéder à THIX CHAT.',
              style: context.textStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    _ensureIncomingCallListener(me);

    return StreamBuilder<SectionBadgeCounts>(
      stream: _counters.streamCounts(me.id),
      builder: (context, snapshot) {
        final counts = snapshot.data ?? SectionBadgeCounts.zero;
        final notificationBadge = counts.info + counts.events + counts.formations + counts.opportunities + counts.jobs;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFF6F8FF)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _circleIconButton(
                          icon: Icons.menu_rounded,
                          onTap: () => context.go(AppRoutes.home),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Row(
                                children: [
                                  Text(
                                    'THIX ',
                                    style: TextStyle(
                                      color: Color(0xFF0D1440),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  Text(
                                    'CHAT',
                                    style: TextStyle(
                                      color: Color(0xFF3455FF),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Connectez-vous. Échangez. Avancez.',
                                style: TextStyle(
                                  color: Color(0xFF666D97),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _circleIconButton(icon: Icons.search_rounded, onTap: _openSearch),
                        const SizedBox(width: 10),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _circleIconButton(
                              icon: Icons.notifications_none_rounded,
                              onTap: () => NotificationsSheet.show(context),
                            ),
                            if (notificationBadge > 0)
                              Positioned(
                                right: -1,
                                top: -1,
                                child: _badge(notificationBadge > 99 ? '99+' : '$notificationBadge'),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.userDashboard),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFE9EEFF),
                                backgroundImage: me.photoUrl != null && me.photoUrl!.trim().isNotEmpty ? NetworkImage(me.photoUrl!) : null,
                                child: me.photoUrl == null || me.photoUrl!.trim().isEmpty
                                    ? Text(
                                        _initials(me.displayName),
                                        style: const TextStyle(
                                          color: Color(0xFF1637D6),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 13,
                                  height: 13,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1CCB6E),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF13256E).withOpacity(0.07),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search_rounded, color: Color(0xFF7C86B2), size: 26),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _homeSearch,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher un chat, contact, groupe...',
                                hintStyle: TextStyle(color: Color(0xFF7C86B2), fontSize: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _openSearch,
                            icon: const Icon(Icons.tune_rounded, color: Color(0xFF6773A7)),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ThixChatsTab(
                      me: me,
                      chat: _chat,
                      query: _searchQuery,
                      counts: counts,
                      onOpenThread: (chatId, otherUid, otherName) => _openThreadSheet(chatId: chatId, otherUid: otherUid, otherName: otherName),
                      onStartByThixId: () => _openStartByThixId(context, me),
                      onOpenStatusComposer: _openStatusComposer,
                      onOpenCalls: _openCalls,
                      onOpenGroups: _openGroups,
                      onOpenFilters: _openSearch,
                      onOpenNewChat: _openNewChat,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(messageBadge: counts.messages),
        );
      },
    );
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: const Color(0xFF11194B), size: 27),
        ),
      ),
    );
  }

  Widget _badge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF5A34F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList(growable: false);
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}j';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'maintenant';
  }

  Widget _buildBottomNav({required int messageBadge}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF20306D).withOpacity(0.08),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              Expanded(child: _navItem(Icons.home_rounded, 'Accueil', active: true, onTap: () {})),
              Expanded(child: _navItem(Icons.chat_bubble_outline_rounded, 'Chats', badge: messageBadge, onTap: _openSearch)),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _openNewChat,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(colors: [Color(0xFF1D4DFF), Color(0xFF3455FF)]),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1D4DFF).withOpacity(0.28),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 38),
                    ),
                  ),
                ),
              ),
              Expanded(child: _navItem(Icons.graphic_eq_rounded, 'Spaces', onTap: _openGroups)),
              Expanded(child: _navItem(Icons.person_outline_rounded, 'Profil', onTap: () => context.go(AppRoutes.userDashboard))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, {bool active = false, int badge = 0, VoidCallback? onTap}) {
    final activeColor = const Color(0xFF2451FF);
    final inactiveColor = const Color(0xFF626A95);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: active ? activeColor : inactiveColor, size: 28),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D7E),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 8 : 0,
              height: 8,
              decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(999)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TOUS LES AUTRES WIDGETS (inchangés – copie intégrale)
// ============================================================================

class ThixChatTemplateHeader extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onNewChat;
  final VoidCallback onGroups;
  final VoidCallback onCalls;
  final VoidCallback onDocs;
  const ThixChatTemplateHeader({super.key, required this.onSearch, required this.onSettings, required this.onNewChat, required this.onGroups, required this.onCalls, required this.onDocs});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final headerBg0 = Color.lerp(scheme.primary, Colors.black, 0.35) ?? scheme.primary;
    final headerBg1 = Color.lerp(scheme.primary, scheme.tertiary, 0.35) ?? scheme.tertiary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [headerBg0, headerBg1]),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('THIX CHAT', style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: scheme.onPrimary)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.lock_rounded, size: 16, color: scheme.onPrimary.withValues(alpha: 0.90)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Chiffrement de bout en bout',
                                style: context.textStyles.bodySmall?.copyWith(color: scheme.onPrimary.withValues(alpha: 0.90), fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _TopAction(icon: Icons.search_rounded, tooltip: 'Rechercher', onTap: onSearch, onColor: scheme.onPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  _TopAction(icon: Icons.settings_rounded, tooltip: 'Réglages', onTap: onSettings, onColor: scheme.onPrimary),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: ThixHeaderActionButton(icon: Icons.add_comment_rounded, label: 'Nouveau', isPrimary: true, onTap: onNewChat)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: ThixHeaderActionButton(icon: Icons.groups_rounded, label: 'Groupes', onTap: onGroups)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: ThixHeaderActionButton(icon: Icons.call_rounded, label: 'Appels', onTap: onCalls)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: ThixHeaderActionButton(icon: Icons.folder_copy_rounded, label: 'Docs', onTap: onDocs)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? onColor;
  const _TopAction({required this.icon, required this.tooltip, required this.onTap, this.onColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.full),
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: onColor ?? scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class ThixHeaderActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  const ThixHeaderActionButton({super.key, required this.icon, required this.label, required this.onTap, this.isPrimary = false});

  @override
  State<ThixHeaderActionButton> createState() => _ThixHeaderActionButtonState();
}

class _ThixHeaderActionButtonState extends State<ThixHeaderActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.isPrimary ? scheme.tertiary.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.12);
    final fg = widget.isPrimary ? scheme.onTertiary : scheme.onPrimary;
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: widget.isPrimary ? 0.0 : 0.20)),
        ),
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.white.withValues(alpha: 0.06),
          hoverColor: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: fg, size: 20),
                const SizedBox(height: 4),
                Text(widget.label, style: context.textStyles.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ChatHomeFilter { all, teams, calls, favorites, meetings }

class ThixChatsTab extends StatefulWidget {
  final AppUser me;
  final ChatService chat;
  final String query;
  final SectionBadgeCounts counts;
  final void Function(String chatId, String otherUid, String otherName) onOpenThread;
  final VoidCallback onStartByThixId;
  final VoidCallback onOpenStatusComposer;
  final VoidCallback onOpenCalls;
  final VoidCallback onOpenGroups;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenNewChat;

  const ThixChatsTab({
    super.key,
    required this.me,
    required this.chat,
    required this.query,
    required this.counts,
    required this.onOpenThread,
    required this.onStartByThixId,
    required this.onOpenStatusComposer,
    required this.onOpenCalls,
    required this.onOpenGroups,
    required this.onOpenFilters,
    required this.onOpenNewChat,
  });

  @override
  State<ThixChatsTab> createState() => _ThixChatsTabState();
}

class _ThixChatsTabState extends State<ThixChatsTab> {
  _ChatHomeFilter _selectedFilter = _ChatHomeFilter.all;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatSummary>>(
      stream: widget.chat.streamChatsForUser(widget.me.id),
      builder: (context, chatSnapshot) {
        final chats = chatSnapshot.data ?? const <ChatSummary>[];
        final waiting = chatSnapshot.connectionState == ConnectionState.waiting && chatSnapshot.data == null;

        return StreamBuilder<List<ChatContact>>(
          stream: widget.chat.streamRecentContacts(uid: widget.me.id, limit: 12),
          builder: (context, contactsSnapshot) {
            final contacts = contactsSnapshot.data ?? const <ChatContact>[];
            final visibleChats = _applyFilters(chats);
            final meetingsCount = chats.where(_isMeetingChat).length;
            final callCount = chats.where(_isCallChat).length;
            final alertsCount = widget.counts.info + widget.counts.events + widget.counts.formations + widget.counts.opportunities + widget.counts.jobs;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 4)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StatsBoard(
                      onlineCount: contacts.length,
                      unreadCount: widget.counts.messages,
                      activeCalls: callCount,
                      alerts: alertsCount,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionLabel(
                    title: 'En ligne',
                    actionLabel: 'Voir tout',
                    onAction: contacts.isEmpty ? null : widget.onOpenFilters,
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 132,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: contacts.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _StoryCreateCard(onTap: widget.onOpenStatusComposer);
                        }
                        final contact = contacts[index - 1];
                        return StreamBuilder<ThixPresence?>(
                          stream: PresenceService().streamPresence(contact.uid),
                          builder: (context, presenceSnapshot) {
                            final online = presenceSnapshot.data?.isOnline ?? true;
                            return _OnlineContactCard(
                              name: contact.displayName,
                              online: online,
                              onTap: () => widget.onOpenThread(
                                widget.chat.directChatIdForUids(widget.me.id, contact.uid),
                                contact.uid,
                                contact.displayName,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _FilterDeck(
                      active: _selectedFilter,
                      meetingCount: meetingsCount,
                      onSelect: (value) {
                        if (value == _ChatHomeFilter.calls) {
                          widget.onOpenCalls();
                          return;
                        }
                        setState(() => _selectedFilter = value);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionLabel(
                    title: 'Conversations récentes',
                    actionLabel: 'Filtres',
                    onAction: widget.onOpenFilters,
                  ),
                ),
                if (waiting)
                  const SliverFillRemaining(child: ThixChatLoadingState())
                else if (chats.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ThixChatEmptyState(
                      title: 'Aucune conversation',
                      subtitle: 'Commence un échange depuis le bouton central ou via un THIX ID.',
                      icon: Icons.forum_rounded,
                      actionLabel: 'Démarrer',
                      onAction: widget.onStartByThixId,
                    ),
                  )
                else if (visibleChats.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: ThixChatEmptyState(
                      title: 'Aucun résultat',
                      subtitle: 'Essayez un autre filtre ou un autre mot-clé.',
                      icon: Icons.search_off_rounded,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: visibleChats.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final chat = visibleChats[index];
                        final otherUid = _otherUid(chat);
                        final title = _chatTitle(chat);
                        final subtitle = chat.lastMessage.trim().isEmpty ? 'Aucun message pour le moment.' : chat.lastMessage.trim();
                        return _ConversationPreviewCard(
                          title: title,
                          subtitle: subtitle,
                          timeLabel: _timeLabel(chat.lastMessageAt),
                          isGroup: _isGroup(chat),
                          isVerified: _isVerifiedConversation(title),
                          isHighlighted: index == 0 && widget.counts.messages > 0,
                          badgeCount: index == 0 ? widget.counts.messages : 0,
                          onTap: otherUid.isEmpty ? null : () => widget.onOpenThread(chat.id, otherUid, title),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<ChatSummary> _applyFilters(List<ChatSummary> chats) {
    final query = widget.query.trim().toLowerCase();
    final searched = query.isEmpty
        ? chats
        : chats.where((chat) {
            final haystack = '${_chatTitle(chat).toLowerCase()} ${chat.lastMessage.toLowerCase()}';
            return haystack.contains(query);
          }).toList(growable: false);

    switch (_selectedFilter) {
      case _ChatHomeFilter.all:
        return searched;
      case _ChatHomeFilter.teams:
        return searched.where(_isGroup).toList(growable: false);
      case _ChatHomeFilter.calls:
        return searched.where(_isCallChat).toList(growable: false);
      case _ChatHomeFilter.favorites:
        return searched.where((chat) => _isVerifiedConversation(_chatTitle(chat)) || !_isGroup(chat)).toList(growable: false);
      case _ChatHomeFilter.meetings:
        return searched.where(_isMeetingChat).toList(growable: false);
    }
  }

  bool _isGroup(ChatSummary chat) => chat.type == 'group' || chat.participants.length > 2;

  bool _isMeetingChat(ChatSummary chat) {
    final value = '${chat.lastMessage} ${chat.title ?? ''}'.toLowerCase();
    return value.contains('meeting') || value.contains('réunion') || value.contains('rendez');
  }

  bool _isCallChat(ChatSummary chat) {
    final value = chat.lastMessage.toLowerCase();
    return value.contains('appel') || value.contains('audio') || value.contains('vidéo') || value.contains('video');
  }

  String _otherUid(ChatSummary chat) => chat.participants.firstWhere((id) => id != widget.me.id, orElse: () => '');

  String _chatTitle(ChatSummary chat) {
    if (_isGroup(chat)) {
      final title = (chat.title ?? '').trim();
      if (title.isNotEmpty) return title;
      final names = chat.participants
          .where((id) => id != widget.me.id)
          .map((id) => chat.participantName[id] ?? 'Membre')
          .take(2)
          .join(', ');
      return names.isEmpty ? 'Groupe THIX' : names;
    }
    final otherUid = _otherUid(chat);
    return chat.participantName[otherUid] ?? 'Utilisateur';
  }

  String _timeLabel(DateTime? value) {
    if (value == null) return '—';
    final local = value.toLocal();
    final now = DateTime.now();
    final sameDay = now.year == local.year && now.month == local.month && now.day == local.day;
    if (sameDay) {
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    final sameYesterday = yesterday.year == local.year && yesterday.month == local.month && yesterday.day == local.day;
    if (sameYesterday) return 'Hier';
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    if (now.difference(local).inDays < 7) {
      return weekdays[local.weekday - 1];
    }
    return '${local.day}/${local.month}';
  }

  bool _isVerifiedConversation(String title) {
    final lower = title.toLowerCase();
    return lower.contains('support') || lower.contains('thix');
  }
}

class _StatsBoard extends StatelessWidget {
  final int onlineCount;
  final int unreadCount;
  final int activeCalls;
  final int alerts;

  const _StatsBoard({
    required this.onlineCount,
    required this.unreadCount,
    required this.activeCalls,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15296D).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _MetricItem(icon: Icons.people_alt_rounded, color: const Color(0xFF16B86D), value: onlineCount, label: 'En ligne')),
          const _MetricDivider(),
          Expanded(child: _MetricItem(icon: Icons.chat_bubble_rounded, color: const Color(0xFF5A34F2), value: unreadCount, label: 'Nouveaux\nmessages')),
          const _MetricDivider(),
          Expanded(child: _MetricItem(icon: Icons.videocam_rounded, color: const Color(0xFF2451FF), value: activeCalls, label: 'Réunions\nactives')),
          const _MetricDivider(),
          Expanded(child: _MetricItem(icon: Icons.shield_rounded, color: const Color(0xFFFF8A1E), value: alerts, label: 'Alertes\nsécurité', showChevron: true)),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 76, color: const Color(0xFFE9EDFA));
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final bool showChevron;

  const _MetricItem({required this.icon, required this.color, required this.value, required this.label, this.showChevron = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 14),
              Text('$value', style: const TextStyle(color: Color(0xFF121A4B), fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(color: Color(0xFF313A70), fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.25)),
            ],
          ),
          if (showChevron)
            const Positioned(
              right: 0,
              top: 22,
              child: Icon(Icons.chevron_right_rounded, color: Color(0xFF1C2459)),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionLabel({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF10184A), fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          if ((actionLabel ?? '').trim().isNotEmpty)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2451FF), padding: EdgeInsets.zero),
              child: Row(
                children: [
                  Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryCreateCard extends StatelessWidget {
  final VoidCallback onTap;
  const _StoryCreateCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B2E76).withOpacity(0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Color(0xFF11194B), size: 36),
          ),
          const SizedBox(height: 10),
          const SizedBox(
            width: 80,
            child: Text(
              'Nouvelle\nhistoire',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF2B336A), fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineContactCard extends StatelessWidget {
  final String name;
  final bool online;
  final VoidCallback onTap;

  const _OnlineContactCard({required this.name, required this.online, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList(growable: false);
    final initials = parts.isEmpty ? 'U' : parts.map((part) => part.substring(0, 1).toUpperCase()).join();
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF2451FF), Color(0xFF6E56FF)]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2451FF).withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(color: Color(0xFFF5F7FF), shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(initials, style: const TextStyle(color: Color(0xFF2451FF), fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFF1CCB6E) : const Color(0xFFC3C8DE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 84,
            child: Text(
              parts.isEmpty ? name : parts.first,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF1D255A), fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDeck extends StatelessWidget {
  final _ChatHomeFilter active;
  final int meetingCount;
  final ValueChanged<_ChatHomeFilter> onSelect;

  const _FilterDeck({required this.active, required this.meetingCount, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, Color color, _ChatHomeFilter value})>[
      (icon: Icons.remove_rounded, label: 'Tous', color: const Color(0xFF2451FF), value: _ChatHomeFilter.all),
      (icon: Icons.groups_rounded, label: 'Équipes', color: const Color(0xFF5A34F2), value: _ChatHomeFilter.teams),
      (icon: Icons.call_rounded, label: 'Appels', color: const Color(0xFF18A85A), value: _ChatHomeFilter.calls),
      (icon: Icons.star_rounded, label: 'Favoris', color: const Color(0xFFFFC73A), value: _ChatHomeFilter.favorites),
      (icon: Icons.calendar_month_rounded, label: 'Rendez-vous', color: const Color(0xFFFF4D7E), value: _ChatHomeFilter.meetings),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15296D).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: _FilterDeckItem(
                icon: items[i].icon,
                label: items[i].label,
                color: items[i].color,
                active: active == items[i].value,
                badge: items[i].value == _ChatHomeFilter.meetings ? meetingCount : 0,
                onTap: () => onSelect(items[i].value),
              ),
            ),
            if (i != items.length - 1) Container(width: 1, height: 50, color: const Color(0xFFE9EDFA)),
          ],
        ],
      ),
    );
  }
}

class _FilterDeckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  const _FilterDeckItem({required this.icon, required this.label, required this.color, required this.active, required this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 28),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: const Color(0xFFFF4D7E), borderRadius: BorderRadius.circular(999)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: active ? const Color(0xFF2451FF) : const Color(0xFF3D4678), fontSize: 12.5, fontWeight: active ? FontWeight.w800 : FontWeight.w600),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 32 : 0,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFF2451FF), borderRadius: BorderRadius.circular(999)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationPreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String timeLabel;
  final bool isGroup;
  final bool isVerified;
  final bool isHighlighted;
  final int badgeCount;
  final VoidCallback? onTap;

  const _ConversationPreviewCard({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.isGroup,
    required this.isVerified,
    required this.isHighlighted,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final parts = title.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).toList(growable: false);
    final initials = parts.isEmpty ? 'T' : parts.map((part) => part.substring(0, 1).toUpperCase()).join();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF172A72).withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isGroup ? 18 : 30),
                    gradient: isGroup
                        ? const LinearGradient(colors: [Color(0xFF2D35FF), Color(0xFF6D39FF)])
                        : const LinearGradient(colors: [Color(0xFFF0F3FF), Color(0xFFE8EEFF)]),
                  ),
                  alignment: Alignment.center,
                  child: isGroup
                      ? const Icon(Icons.groups_rounded, color: Colors.white, size: 30)
                      : Text(initials, style: const TextStyle(color: Color(0xFF2451FF), fontSize: 22, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF141D4F), fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFF2451FF), size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF5A628B), fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isHighlighted)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Icon(Icons.push_pin_rounded, color: Color(0xFF6B6F95), size: 16),
                      )
                    else
                      const SizedBox(height: 6),
                    Text(timeLabel, style: const TextStyle(color: Color(0xFF6C739C), fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (badgeCount > 0)
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A34F2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThixCallLauncherSheet extends StatefulWidget {
  final AppUser me;
  final ChatService chat;
  final CallService calls;
  const ThixCallLauncherSheet({super.key, required this.me, required this.chat, required this.calls});

  @override
  State<ThixCallLauncherSheet> createState() => _ThixCallLauncherSheetState();
}

class _ThixCallLauncherSheetState extends State<ThixCallLauncherSheet> {
  String _kind = 'audio';
  bool _busy = false;

  Future<void> _startCall(ChatContact c) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final other = AppUser(
        id: c.uid,
        thixId: c.thixId,
        thixChat: '',
        thixScore: null,
        email: '',
        phone: null,
        displayName: c.displayName,
        accountType: AccountType.personal,
        photoUrl: null,
        bio: null,
        countryOrOrigin: null,
        contactPhone: null,
        maritalStatus: null,
        gender: null,
        occupation: null,
        profession: null,
        dateOfBirth: null,
        placeOfBirth: null,
        nationality: null,
        address: null,
        fatherName: null,
        motherName: null,
        emergencyContactName: null,
        emergencyContactPhone: null,
        emergencyContactRelation: null,
        education: const [],
        experience: const [],
        skills: const [],
        enrollments: const [],
        languages: const [],
        biometricsEnabled: true,
        twoFaEnabled: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final chatId = await widget.chat.getOrCreateDirectChat(me: widget.me, other: other);
      final callId = await widget.calls.startCall(chatId: chatId, kind: _kind, receiverId: c.uid);
      if (!mounted) return;
      context.pop();
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => ThixAgoraCallSheet(callId: callId, otherUserId: c.uid, kind: _kind, isCaller: true, calls: widget.calls),
      );
    } catch (e) {
      debugPrint('CallLauncher: start call failed err=$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de démarrer l\'appel. (${e.toString()})')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ThixBottomSheetShell(
      title: 'Démarrer un appel',
      subtitle: 'Choisis un contact récent (audio/vidéo).',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Audio'),
                            selected: _kind == 'audio',
                            onSelected: _busy ? null : (_) => setState(() => _kind = 'audio'),
                            selectedColor: scheme.tertiary,
                            labelStyle: context.textStyles.labelLarge?.copyWith(color: _kind == 'audio' ? scheme.onTertiary : scheme.onSurface, fontWeight: FontWeight.w800),
                            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.0)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Vidéo'),
                            selected: _kind == 'video',
                            onSelected: _busy ? null : (_) => setState(() => _kind = 'video'),
                            selectedColor: scheme.tertiary,
                            labelStyle: context.textStyles.labelLarge?.copyWith(color: _kind == 'video' ? scheme.onTertiary : scheme.onSurface, fontWeight: FontWeight.w800),
                            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.0)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: StreamBuilder<List<ChatContact>>(
              stream: widget.chat.streamRecentContacts(uid: widget.me.id, limit: 40),
              builder: (context, snap) {
                final contacts = snap.data ?? const <ChatContact>[];
                if (snap.connectionState == ConnectionState.waiting && snap.data == null) return const ThixChatLoadingState();
                if (contacts.isEmpty) {
                  return ThixChatEmptyState(
                    title: 'Aucun contact',
                    subtitle: 'Démarre une discussion d’abord pour voir des contacts ici.',
                    icon: Icons.call_rounded,
                  );
                }
                return ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final c = contacts[i];
                    return ThixChatListTile(
                      title: c.displayName,
                      subtitle: c.thixId.isEmpty ? 'THIX ID non renseigné' : c.thixId,
                      time: null,
                      leadingIcon: _kind == 'video' ? Icons.videocam_rounded : Icons.call_rounded,
                      onTap: _busy ? null : () => _startCall(c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ThixBottomSheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const ThixBottomSheetShell({super.key, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 680, maxHeight: h * 0.86),
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 44, height: 5, decoration: BoxDecoration(color: scheme.outlineVariant.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(99))),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                              if ((subtitle ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(subtitle!, style: context.textStyles.bodySmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70))),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.pop(),
                          style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
                          icon: Icon(Icons.close_rounded, color: scheme.onSurface),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(child: child),
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

class ThixChatBackground extends StatelessWidget {
  const ThixChatBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface.withValues(alpha: 0.92),
            scheme.surface.withValues(alpha: 0.98),
          ],
        ),
      ),
      child: CustomPaint(
        painter: _ThixRingsPainter(
          ring: scheme.primary.withValues(alpha: 0.05),
          ring2: scheme.tertiary.withValues(alpha: 0.06),
        ),
      ),
    );
  }
}

class _ThixRingsPainter extends CustomPainter {
  final Color ring;
  final Color ring2;
  const _ThixRingsPainter({required this.ring, required this.ring2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.56, size.height * 0.78);
    final p1 = Paint()..style = PaintingStyle.stroke..strokeWidth = 34..color = ring..strokeCap = StrokeCap.round;
    final p2 = Paint()..style = PaintingStyle.stroke..strokeWidth = 22..color = ring2..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final r = size.shortestSide * (0.22 + i * 0.14);
      canvas.drawArc(Rect.fromCircle(center: center, radius: r), 0.5, 4.8, false, i.isEven ? p1 : p2);
    }
  }

  @override
  bool shouldRepaint(covariant _ThixRingsPainter oldDelegate) => oldDelegate.ring != ring || oldDelegate.ring2 != ring2;
}

class ThixContactsTab extends StatelessWidget {
  final AppUser me;
  final ChatService chat;
  final void Function(String chatId, String otherUid, String otherName) onOpenThread;
  const ThixContactsTab({super.key, required this.me, required this.chat, required this.onOpenThread});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: StreamBuilder<List<ChatContact>>(
        stream: chat.streamRecentContacts(uid: me.id, limit: 30),
        builder: (context, snap) {
          final contacts = snap.data ?? const <ChatContact>[];
          if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
            return const ThixChatLoadingState();
          }
          if (contacts.isEmpty) {
            return ThixChatEmptyState(
              title: 'Aucun contact récent',
              subtitle: 'Les contacts apparaissent après des échanges.',
              icon: Icons.contact_page_rounded,
            );
          }
          return ListView.separated(
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final c = contacts[i];
              return ThixChatListTile(
                title: c.displayName,
                subtitle: c.thixId.isEmpty ? 'THIX ID non renseigné' : c.thixId,
                time: null,
                leadingIcon: Icons.person_rounded,
                onTap: () async {
                  try {
                    final other = AppUser(
                      id: c.uid,
                      thixId: c.thixId,
                      thixChat: '',
                      thixScore: null,
                      email: '',
                      phone: null,
                      displayName: c.displayName,
                      accountType: AccountType.personal,
                      photoUrl: null,
                      bio: null,
                      countryOrOrigin: null,
                      contactPhone: null,
                      maritalStatus: null,
                      gender: null,
                      occupation: null,
                      profession: null,
                      dateOfBirth: null,
                      placeOfBirth: null,
                      nationality: null,
                      address: null,
                      fatherName: null,
                      motherName: null,
                      emergencyContactName: null,
                      emergencyContactPhone: null,
                      emergencyContactRelation: null,
                      education: const [],
                      experience: const [],
                      skills: const [],
                      enrollments: const [],
                      languages: const [],
                      biometricsEnabled: true,
                      twoFaEnabled: false,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    final chatId = await chat.getOrCreateDirectChat(me: me, other: other);
                    onOpenThread(chatId, c.uid, c.displayName);
                  } catch (e) {
                    debugPrint('ContactsTab: open thread failed err=$e');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ThixStatusTab extends StatelessWidget {
  final AppUser me;
  final StatusService status;
  const ThixStatusTab({super.key, required this.me, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          ThixStatusComposer(me: me, status: status),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: StreamBuilder<List<StatusUpdate>>(
              stream: status.streamActiveStatuses(),
              builder: (context, snap) {
                final list = snap.data ?? const <StatusUpdate>[];
                if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
                  return const ThixChatLoadingState();
                }
                if (list.isEmpty) {
                  return ThixChatEmptyState(
                    title: 'Aucun statut actif',
                    subtitle: 'Publie un statut pour qu’il apparaisse ici.',
                    icon: Icons.auto_awesome_rounded,
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) => ThixStatusCard(update: list[i], isMine: list[i].uid == me.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ThixChatListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime? time;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  const ThixChatListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onTap,
    this.leadingIcon,
  });

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ThixAvatarChip(icon: leadingIcon ?? Icons.person_rounded),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(subtitle, style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (time != null)
                Text(
                  _formatTime(time!),
                  style: context.textStyles.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55), fontWeight: FontWeight.w700),
                ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class ThixAvatarChip extends StatelessWidget {
  final IconData icon;
  const ThixAvatarChip({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppPremiumGradients.thixNavyToGold(scheme),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: scheme.onPrimary),
      ),
    );
  }
}

class ThixChatLoadingState extends StatelessWidget {
  const ThixChatLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
  }
}

class ThixChatEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const ThixChatEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, color: scheme.onSurface.withValues(alpha: 0.65), size: 26),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(subtitle, style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70)), textAlign: TextAlign.center),
              if ((actionLabel ?? '').trim().isNotEmpty && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.tertiary,
                      foregroundColor: scheme.onTertiary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    ),
                    icon: Icon(Icons.person_search_rounded, size: 18, color: scheme.onTertiary),
                    label: Text(actionLabel!, style: context.textStyles.labelLarge?.copyWith(color: scheme.onTertiary, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ThixStartChatByThixIdSheet extends StatefulWidget {
  final AppUser me;
  final ChatService chat;
  const ThixStartChatByThixIdSheet({super.key, required this.me, required this.chat});

  @override
  State<ThixStartChatByThixIdSheet> createState() => _ThixStartChatByThixIdSheetState();
}

class _ThixStartChatByThixIdSheetState extends State<ThixStartChatByThixIdSheet> {
  final _c = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _start() async {
    final raw = _c.text;
    final normalized = ThixIdService.normalize(raw);
    final canonical = ThixIdService.canonicalizeOrNull(normalized);
    if (!ThixIdService.isValid(normalized) && canonical == null) {
      debugPrint('ThixStartChatByThixIdSheet: input not a valid THIX ID; will try lookup anyway raw=$raw normalized=$normalized');
    }
    setState(() => _busy = true);
    try {
      ChatContact? contact;
      final attempts = <String>{};
      if (ThixIdService.isValid(normalized)) attempts.add(normalized);
      if (canonical != null && ThixIdService.isValid(canonical)) attempts.add(canonical);
      for (final v in attempts) {
        contact = await widget.chat.fetchProfileByThixId(v);
        if (contact != null) break;
      }
      contact ??= await widget.chat.fetchProfileByThixIdOrHandle(normalized);
      if (contact == null) {
        final results = await widget.chat.searchProfiles(normalized, limit: 5);
        if (results.length == 1) contact = results.first;
      }
      if (!mounted) return;
      if (contact == null) {
        final hint = (canonical != null && canonical != normalized)
            ? 'Vérifie le THIX ID. Astuce: checksum attendu → $canonical'
            : 'Vérifie le THIX ID.';
        _snack('Utilisateur introuvable (ou accès refusé). $hint');
        return;
      }
      if (contact.uid == widget.me.id) {
        _snack('Impossible de démarrer un chat avec soi-même.');
        return;
      }
      context.pop(_SearchPick(uid: contact.uid, displayName: contact.displayName, thixId: contact.thixId));
    } catch (e) {
      debugPrint('ThixStartChatByThixIdSheet: start failed err=$e');
      _snack('Erreur de recherche.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Démarrer une discussion', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Entre le THIX ID de la personne pour ouvrir directement la conversation.',
                style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70), height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _c,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'THIX ID',
                  hintText: ThixIdService.exampleV2,
                  prefixIcon: const Icon(Icons.verified_user_rounded),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
                onSubmitted: (_) {
                  if (_busy) return;
                  unawaited(_start());
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _start,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary,
                    foregroundColor: scheme.onTertiary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(Icons.chat_rounded, size: 18, color: scheme.onTertiary),
                  label: Text(_busy ? '...' : 'Ouvrir le chat', style: context.textStyles.labelLarge?.copyWith(color: scheme.onTertiary, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Status UI
// =============================================================================
class ThixStatusComposer extends StatefulWidget {
  final AppUser me;
  final StatusService status;
  const ThixStatusComposer({super.key, required this.me, required this.status});

  @override
  State<ThixStatusComposer> createState() => _ThixStatusComposerState();
}

class _ThixStatusComposerState extends State<ThixStatusComposer> {
  final _c = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _postText() async {
    final text = _c.text.trim();
    if (text.isEmpty) {
      _snack('Écris un statut.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.status.postTextStatus(
        uid: widget.me.id,
        displayName: widget.me.displayName,
        thixId: widget.me.thixId,
        text: text,
      );
      _c.clear();
      _snack('Statut publié.');
    } catch (e) {
      debugPrint('ThixStatusComposer: postText failed err=$e');
      _snack('Erreur publication.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _postMedia(String kind) async {
    setState(() => _busy = true);
    try {
      final result = await FilePicker.pickFiles(withData: kIsWeb);
      if (result == null || result.files.isEmpty) return;
      final f = result.files.first;
      await widget.status.postMediaStatus(
        uid: widget.me.id,
        displayName: widget.me.displayName,
        thixId: widget.me.thixId,
        statusType: kind,
        file: f,
        caption: _c.text.trim().isEmpty ? null : _c.text.trim(),
      );
      _c.clear();
      _snack('Statut publié.');
    } catch (e) {
      debugPrint('ThixStatusComposer: postMedia failed kind=$kind err=$e');
      _snack('Erreur publication média.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mon statut', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _c,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Partage une info…',
                hintStyle: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.45)),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.8), width: 1.2)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _postText,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(_busy ? '...' : 'Publier', style: context.textStyles.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ComposerIconButton(icon: Icons.photo_rounded, tooltip: 'Photo', onPressed: _busy ? null : () => _postMedia('photo')),
                const SizedBox(width: AppSpacing.sm),
                _ComposerIconButton(icon: Icons.videocam_rounded, tooltip: 'Vidéo', onPressed: _busy ? null : () => _postMedia('video')),
                const SizedBox(width: AppSpacing.sm),
                _ComposerIconButton(icon: Icons.mic_rounded, tooltip: 'Audio', onPressed: _busy ? null : () => _postMedia('audio')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const _ComposerIconButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class ThixStatusCard extends StatelessWidget {
  final StatusUpdate update;
  final bool isMine;
  const ThixStatusCard({super.key, required this.update, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThixAvatarChip(icon: isMine ? Icons.verified_user_rounded : Icons.person_rounded),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(update.displayName, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        _statusMeta(update),
                        style: context.textStyles.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.60), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.auto_awesome_rounded, color: scheme.tertiary.withValues(alpha: 0.9)),
              ],
            ),
            if ((update.text).trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(update.text, style: context.textStyles.bodyMedium?.copyWith(height: 1.45)),
            ],
            if ((update.mediaUrl ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.35)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(update.mediaUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_rounded, color: scheme.onSurface.withValues(alpha: 0.5)))),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Text(
                                  update.statusType.toUpperCase(),
                                  style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusMeta(StatusUpdate u) {
    final exp = u.expiresAt.toLocal();
    final hh = exp.hour.toString().padLeft(2, '0');
    final mm = exp.minute.toString().padLeft(2, '0');
    final kind = _prettyKind(u.statusType);
    return 'Expire à $hh:$mm • $kind';
  }

  String _prettyKind(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty || v == 'erreur' || v == 'error') return 'texte';
    if (v == 'text') return 'texte';
    if (v == 'photo' || v == 'image') return 'photo';
    if (v == 'video' || v == 'vidéo') return 'vidéo';
    if (v == 'audio' || v == 'voice') return 'audio';
    return v;
  }
}

// =============================================================================
// Thread Sheet
// =============================================================================
class ThixChatThreadSheet extends StatefulWidget {
  final AppUser me;
  final String chatId;
  final String otherUid;
  final String otherName;
  final ChatService chat;
  final CallService calls;
  const ThixChatThreadSheet({
    super.key,
    required this.me,
    required this.chatId,
    required this.otherUid,
    required this.otherName,
    required this.chat,
    required this.calls,
  });

  @override
  State<ThixChatThreadSheet> createState() => _ThixChatThreadSheetState();
}

class _ThixChatThreadSheetState extends State<ThixChatThreadSheet> {
  final _text = TextEditingController();
  bool _sending = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    unawaited(widget.chat.markChatRead(chatId: widget.chatId, uid: widget.me.id));
    _text.addListener(_onTypingChanged);
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _text.removeListener(_onTypingChanged);
    unawaited(widget.chat.setTyping(chatId: widget.chatId, isTyping: false));
    _text.dispose();
    super.dispose();
  }

  void _onTypingChanged() {
    final isTyping = _text.text.trim().isNotEmpty;
    unawaited(widget.chat.setTyping(chatId: widget.chatId, isTyping: isTyping));
    _typingDebounce?.cancel();
    if (!isTyping) return;
    _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
      unawaited(widget.chat.setTyping(chatId: widget.chatId, isTyping: false));
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendText() async {
    final msg = _text.text.trim();
    if (msg.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.chat.sendMessage(chatId: widget.chatId, sender: widget.me, text: msg);
      _text.clear();
    } catch (e) {
      debugPrint('ThixChatThreadSheet: sendText failed err=$e');
      _snack('Erreur envoi.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendAttachment() async {
    setState(() => _sending = true);
    try {
      final result = await FilePicker.pickFiles(withData: kIsWeb);
      if (result == null || result.files.isEmpty) return;
      await widget.chat.sendAttachment(chatId: widget.chatId, sender: widget.me, file: result.files.first);
    } catch (e) {
      debugPrint('ThixChatThreadSheet: sendAttachment failed err=$e');
      _snack('Erreur pièce jointe.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMeeting() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixMeetingComposerSheet(
        onSubmit: (title, at, duration, location, note) async {
          try {
            await widget.chat.sendMeetingInvite(
              chatId: widget.chatId,
              sender: widget.me,
              title: title,
              scheduledAt: at,
              durationMinutes: duration,
              location: location,
              note: note,
            );
            _snack('Invitation meeting envoyée.');
          } catch (e) {
            debugPrint('ThixChatThreadSheet: sendMeeting failed err=$e');
            _snack('Erreur meeting.');
          }
        },
      ),
    );
  }

  Future<void> _sendMoney() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => ThixMoneyComposerSheet(
        onSubmit: (senderPhone, receiverPhone, network, amount, currency, note, password) async {
          if (password.trim().length < 4) {
            _snack('Mot de passe trop court.');
            return;
          }
          try {
            await widget.chat.sendMoneyTransfer(
              chatId: widget.chatId,
              sender: widget.me,
              senderPhone: senderPhone,
              receiverPhone: receiverPhone,
              network: network,
              amount: amount,
              currency: currency,
              note: note,
            );
            _snack('Transfert envoyé.');
          } catch (e) {
            debugPrint('ThixChatThreadSheet: sendMoney failed err=$e');
            _snack('Erreur transfert.');
          }
        },
      ),
    );
  }

  Future<void> _startCall(String kind) async {
    try {
      await widget.chat.sendCallRequest(chatId: widget.chatId, sender: widget.me, kind: kind);
      final id = await widget.calls.startCall(chatId: widget.chatId, kind: kind, receiverId: widget.otherUid);
      debugPrint('Call started id=$id kind=$kind chat=${widget.chatId}');
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        builder: (_) => ThixAgoraCallSheet(
          callId: id,
          otherUserId: widget.otherUid,
          kind: kind == 'video' ? 'video' : 'audio',
          isCaller: true,
          calls: widget.calls,
        ),
      );
    } catch (e) {
      debugPrint('ThixChatThreadSheet: startCall failed kind=$kind err=$e');
      _snack('Erreur appel.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.otherName, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        StreamBuilder<List<String>>(
                          stream: widget.chat.streamTypingUsers(chatId: widget.chatId, excludeUid: widget.me.id),
                          builder: (context, snap) {
                            final typing = (snap.data ?? const <String>[]).isNotEmpty;
                            if (typing) {
                              return Text('Écrit…', style: context.textStyles.labelSmall?.copyWith(color: scheme.primary.withValues(alpha: 0.95), fontWeight: FontWeight.w800));
                            }
                            return StreamBuilder<DateTime?>(
                              stream: widget.chat.streamReadAt(chatId: widget.chatId, uid: widget.otherUid),
                              builder: (context, readSnap) {
                                final v = readSnap.data;
                                final label = v == null ? 'Non vu' : 'Vu';
                                return Text(label, style: context.textStyles.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55), fontWeight: FontWeight.w700));
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _ThreadAction(icon: Icons.call_rounded, tooltip: 'Appel audio', onTap: () => _startCall('audio')),
                  const SizedBox(width: AppSpacing.sm),
                  _ThreadAction(icon: Icons.videocam_rounded, tooltip: 'Appel vidéo', onTap: () => _startCall('video')),
                  const SizedBox(width: AppSpacing.sm),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.6)),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: widget.chat.streamMessages(widget.chatId),
                builder: (context, snap) {
                  final list = snap.data ?? const <ChatMessage>[];
                  if (snap.connectionState == ConnectionState.waiting && snap.data == null) {
                    return const ThixChatLoadingState();
                  }
                  if (list.isEmpty) {
                    return ThixChatEmptyState(
                      title: 'Démarre la conversation',
                      subtitle: 'Envoie un message ou utilise les actions ci-dessous.',
                      icon: Icons.mark_chat_unread_rounded,
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final m = list[i];
                      final mine = m.senderId == widget.me.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ThixMessageBubble(message: m, isMine: mine),
                      );
                    },
                  );
                },
              ),
            ),
            ThixThreadComposer(
              controller: _text,
              busy: _sending,
              onSend: _sendText,
              onAttach: _sendAttachment,
              onMeeting: _sendMeeting,
              onMoney: _sendMoney,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreadAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _ThreadAction({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 18, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class ThixThreadComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onMoney;
  final VoidCallback onMeeting;
  const ThixThreadComposer({
    super.key,
    required this.controller,
    required this.busy,
    required this.onSend,
    required this.onAttach,
    required this.onMoney,
    required this.onMeeting,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ComposerIconButton(icon: Icons.attach_file_rounded, tooltip: 'Pièce jointe', onPressed: busy ? null : onAttach),
              const SizedBox(width: AppSpacing.sm),
              _ComposerIconButton(icon: Icons.calendar_month_rounded, tooltip: 'Meeting', onPressed: busy ? null : onMeeting),
              const SizedBox(width: AppSpacing.sm),
              _ComposerIconButton(icon: Icons.payments_rounded, tooltip: 'Transfert', onPressed: busy ? null : onMoney),
              const Spacer(),
              Text(busy ? 'Envoi…' : '', style: context.textStyles.labelSmall?.copyWith(color: scheme.onSurface.withValues(alpha: 0.55), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: 'Écrire un message…',
                    hintStyle: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.45)),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full), borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.8), width: 1.2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: busy ? null : onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.tertiary,
                  foregroundColor: scheme.onTertiary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                ),
                child: Icon(Icons.send_rounded, color: scheme.onTertiary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ThixMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const ThixMessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMine
        ? const LinearGradient(colors: [Color(0xFF2451FF), Color(0xFF5A34F2)])
        : const LinearGradient(colors: [Colors.white, Color(0xFFF7F9FF)]);
    final fg = isMine ? Colors.white : const Color(0xFF16204C);
    final rich = _tryMoneyPayload(message.text);
    final isMoney = rich != null;
    final attachmentUrl = (message.extra['download_url'] ?? '').toString();
    final attachmentName = (message.extra['file_name'] ?? 'Document').toString();
    final attachmentExt = ((message.extra['file_ext'] ?? '').toString()).toUpperCase();
    final meetingTitle = (message.extra['meeting_title'] ?? '').toString();
    final callKind = (message.extra['call_kind'] ?? '').toString();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: bg,
            border: Border.all(color: isMine ? Colors.transparent : const Color(0xFFE8EDFA)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF15296D).withOpacity(isMine ? 0.16 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(
                    message.senderName.isEmpty ? 'Utilisateur' : message.senderName,
                    style: context.textStyles.labelSmall?.copyWith(color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w800),
                  ),
                if (!isMine) const SizedBox(height: 6),
                if (isMoney)
                  ThixMoneyBubble(payload: rich!, isMine: isMine)
                else if (message.type == 'attachment' && attachmentUrl.trim().isNotEmpty)
                 _buildAttachmentCard(context, fg, attachmentName, attachmentExt, attachmentUrl)
                else if (message.type == 'meeting')
                 _buildMeetingCard(context, fg, meetingTitle)
                else if (message.type == 'call_request')
                 _buildCallCard(context, fg, callKind)
                else
                 Text(
                   message.text.trim().isEmpty ? '…' : message.text,
                   style: context.textStyles.bodyMedium?.copyWith(color: fg, height: 1.45, fontWeight: FontWeight.w600),
                 ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTs(message.createdAt),
                    style: context.textStyles.labelSmall?.copyWith(color: fg.withValues(alpha: 0.70), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(BuildContext context, Color fg, String name, String ext, String url) {
    final chipBg = isMine ? Colors.white.withOpacity(0.14) : const Color(0xFFEAF0FF);
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri == null) return;
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isMine ? Colors.white.withOpacity(0.12) : const Color(0xFFDCE5FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isMine ? Colors.white : const Color(0xFF2451FF),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                ext.isEmpty ? 'DOC' : ext,
                style: TextStyle(
                  color: isMine ? const Color(0xFF2451FF) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Appuyer pour ouvrir le fichier',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg.withOpacity(0.78), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: fg, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingCard(BuildContext context, Color fg, String title) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withOpacity(0.14) : const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invitation réunion', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  title.trim().isEmpty ? 'Meeting THIX CHAT' : title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg.withOpacity(0.84), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallCard(BuildContext context, Color fg, String kind) {
    final label = kind == 'video' ? 'Appel vidéo' : 'Appel audio';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withOpacity(0.14) : const Color(0xFFEAFBF2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(kind == 'video' ? Icons.videocam_rounded : Icons.call_rounded, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label lancé depuis THIX CHAT',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTs(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Map<String, dynamic>? _tryMoneyPayload(String raw) {
    final t = raw.trim();
    if (!t.startsWith(ChatService.moneyTransferMarker)) return null;
    final payloadPart = t.substring(ChatService.moneyTransferMarker.length);
    final firstNewline = payloadPart.indexOf('\n');
    final jsonText = (firstNewline >= 0) ? payloadPart.substring(0, firstNewline) : payloadPart;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return null;
    } catch (e) {
      debugPrint('ThixMessageBubble: money payload parse failed err=$e');
      return null;
    }
  }
}

class ThixMoneyBubble extends StatelessWidget {
  final Map<String, dynamic> payload;
  final bool isMine;
  const ThixMoneyBubble({super.key, required this.payload, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final amount = (payload['amount'] ?? '').toString();
    final currency = (payload['currency'] ?? '').toString();
    final network = (payload['network'] ?? '').toString();
    final receiver = (payload['receiver_phone'] ?? '').toString();
    final status = (payload['status'] ?? 'pending').toString();
    final note = (payload['note'] ?? '').toString();
    final tagBg = isMine ? Colors.white.withValues(alpha: 0.18) : scheme.primary.withValues(alpha: 0.10);
    final tagFg = isMine ? scheme.onPrimary : scheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_rounded, color: isMine ? scheme.onPrimary : scheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Transfert',
                style: context.textStyles.titleMedium?.copyWith(color: isMine ? scheme.onPrimary : scheme.onSurface, fontWeight: FontWeight.w800),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(AppRadius.full)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  status.toUpperCase(),
                  style: context.textStyles.labelSmall?.copyWith(color: tagFg, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '$amount $currency',
          style: context.textStyles.headlineMedium?.copyWith(color: isMine ? scheme.onPrimary : scheme.onSurface, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Réseau: $network',
          style: context.textStyles.bodyMedium?.copyWith(color: (isMine ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.85), fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          'Vers: $receiver',
          style: context.textStyles.bodyMedium?.copyWith(color: (isMine ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.85), fontWeight: FontWeight.w700),
        ),
        if (note.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            note,
            style: context.textStyles.bodyMedium?.copyWith(color: (isMine ? scheme.onPrimary : scheme.onSurface).withValues(alpha: 0.85), height: 1.35),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// New chat / Search sheets
// =============================================================================
class ThixChatSearchSheet extends StatefulWidget {
  final AppUser me;
  final ChatService chat;
  const ThixChatSearchSheet({super.key, required this.me, required this.chat});

  @override
  State<ThixChatSearchSheet> createState() => _ThixChatSearchSheetState();
}

class _ThixChatSearchSheetState extends State<ThixChatSearchSheet> {
  final _c = TextEditingController();
  Timer? _debounce;
  bool _busy = false;
  String _q = '';
  List<ChatContact> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _search(v));
  }

  Future<void> _search(String v) async {
    final q = v.trim();
    setState(() {
      _q = q;
      _busy = true;
    });
    try {
      if (q.isEmpty) {
        setState(() {
          _results = const [];
          _busy = false;
        });
        return;
      }
      final list = await widget.chat.searchProfiles(q, limit: 30);
      if (!mounted) return;
      setState(() {
        _results = list.where((e) => e.uid != widget.me.id).toList(growable: false);
      });
    } catch (e) {
      debugPrint('ThixChatSearchSheet: search failed err=$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Rechercher', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _c,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Nom / THIX ID / @handle',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _busy && _results.isEmpty
                    ? const ThixChatLoadingState()
                    : _q.isEmpty
                        ? ThixChatEmptyState(
                            title: 'Recherche',
                            subtitle: 'Tape un nom, THIX ID, ou @handle.',
                            icon: Icons.manage_search_rounded,
                          )
                        : _results.isEmpty
                            ? ThixChatEmptyState(
                                title: 'Aucun résultat',
                                subtitle: 'Essaie une autre recherche.',
                                icon: Icons.search_off_rounded,
                              )
                            : ListView.separated(
                                itemCount: _results.length,
                                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, i) {
                                  final r = _results[i];
                                  return ThixChatListTile(
                                    title: r.displayName,
                                    subtitle: r.thixId.isEmpty ? r.uid : r.thixId,
                                    time: null,
                                    leadingIcon: Icons.person_rounded,
                                    onTap: () => context.pop(_SearchPick(uid: r.uid, displayName: r.displayName, thixId: r.thixId)),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPick {
  final String uid;
  final String displayName;
  final String thixId;
  const _SearchPick({required this.uid, required this.displayName, required this.thixId});
}

class ThixChatNewChatSheet extends StatelessWidget {
  final AppUser me;
  final ChatService chat;
  const ThixChatNewChatSheet({super.key, required this.me, required this.chat});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Nouveau chat', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showModalBottomSheet<_SearchPick?>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (_) => ThixStartChatByThixIdSheet(me: me, chat: chat),
                    );
                    if (picked == null) return;
                    if (!context.mounted) return;
                    final other = AppUser(
                      id: picked.uid,
                      thixId: picked.thixId,
                      thixChat: '',
                      thixScore: null,
                      email: '',
                      phone: null,
                      displayName: picked.displayName,
                      accountType: AccountType.personal,
                      photoUrl: null,
                      bio: null,
                      countryOrOrigin: null,
                      contactPhone: null,
                      maritalStatus: null,
                      gender: null,
                      occupation: null,
                      profession: null,
                      dateOfBirth: null,
                      placeOfBirth: null,
                      nationality: null,
                      address: null,
                      fatherName: null,
                      motherName: null,
                      emergencyContactName: null,
                      emergencyContactPhone: null,
                      emergencyContactRelation: null,
                      education: const [],
                      experience: const [],
                      skills: const [],
                      enrollments: const [],
                      languages: const [],
                      biometricsEnabled: true,
                      twoFaEnabled: false,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    try {
                      final chatId = await chat.getOrCreateDirectChat(me: me, other: other);
                      if (!context.mounted) return;
                      context.pop(_NewChatPick(chatId: chatId, otherUid: picked.uid, title: picked.displayName));
                    } catch (e) {
                      debugPrint('NewChatSheet: start by thix id failed err=$e');
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.onSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
                  ),
                  icon: const Icon(Icons.person_search_rounded, size: 18),
                  label: Text('Trouver par THIX ID', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final created = await showModalBottomSheet<_NewChatPick?>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      builder: (_) => ThixGroupComposerSheet(me: me, chat: chat),
                    );
                    if (created == null) return;
                    if (!context.mounted) return;
                    context.pop(created);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(Icons.group_add_rounded, size: 18, color: scheme.onPrimary),
                  label: Text('Créer un groupe', style: context.textStyles.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tu peux aussi lancer un chat depuis la recherche (loupe) ou depuis tes contacts récents ci-dessous.',
                style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70), height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: StreamBuilder<List<ChatContact>>(
                  stream: chat.streamRecentContacts(uid: me.id, limit: 12),
                  builder: (context, snap) {
                    final list = snap.data ?? const <ChatContact>[];
                    if (list.isEmpty) {
                      return ThixChatEmptyState(
                        title: 'Suggestions',
                        subtitle: 'Tes contacts récents apparaîtront ici.',
                        icon: Icons.auto_awesome_rounded,
                      );
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        final c = list[i];
                        return ThixChatListTile(
                          title: c.displayName,
                          subtitle: c.thixId.isEmpty ? 'Contact' : c.thixId,
                          time: null,
                          onTap: () async {
                            try {
                              final other = AppUser(
                                id: c.uid,
                                thixId: c.thixId,
                                thixChat: '',
                                thixScore: null,
                                email: '',
                                phone: null,
                                displayName: c.displayName,
                                accountType: AccountType.personal,
                                photoUrl: null,
                                bio: null,
                                countryOrOrigin: null,
                                contactPhone: null,
                                maritalStatus: null,
                                gender: null,
                                occupation: null,
                                profession: null,
                                dateOfBirth: null,
                                placeOfBirth: null,
                                nationality: null,
                                address: null,
                                fatherName: null,
                                motherName: null,
                                emergencyContactName: null,
                                emergencyContactPhone: null,
                                emergencyContactRelation: null,
                                education: const [],
                                experience: const [],
                                skills: const [],
                                enrollments: const [],
                                languages: const [],
                                biometricsEnabled: true,
                                twoFaEnabled: false,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              final chatId = await chat.getOrCreateDirectChat(me: me, other: other);
                              if (!context.mounted) return;
                              context.pop(_NewChatPick(chatId: chatId, otherUid: c.uid, title: c.displayName));
                            } catch (e) {
                              debugPrint('NewChatSheet: open direct failed err=$e');
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewChatPick {
  final String chatId;
  final String otherUid;
  final String title;
  const _NewChatPick({required this.chatId, required this.otherUid, required this.title});
}

class ThixGroupComposerSheet extends StatefulWidget {
  final AppUser me;
  final ChatService chat;
  const ThixGroupComposerSheet({super.key, required this.me, required this.chat});

  @override
  State<ThixGroupComposerSheet> createState() => _ThixGroupComposerSheetState();
}

class _ThixGroupComposerSheetState extends State<ThixGroupComposerSheet> {
  final _title = TextEditingController();
  final _q = TextEditingController();
  Timer? _debounce;
  bool _busy = false;
  List<ChatContact> _results = const [];
  final Set<String> _selected = <String>{};

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    _q.dispose();
    super.dispose();
  }

  Future<void> _search(String v) async {
    final q = v.trim();
    setState(() => _busy = true);
    try {
      if (q.isEmpty) {
        setState(() => _results = const []);
        return;
      }
      final list = await widget.chat.searchProfiles(q, limit: 30);
      if (!mounted) return;
      setState(() => _results = list.where((e) => e.uid != widget.me.id).toList(growable: false));
    } catch (e) {
      debugPrint('ThixGroupComposerSheet: search failed err=$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final title = _title.text.trim().isEmpty ? 'Groupe' : _title.text.trim();
    if (_selected.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoute au moins 1 membre.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final chatId = await widget.chat.createGroup(me: widget.me, title: title, memberUids: _selected.toList(growable: false));
      if (!mounted) return;
      context.pop(_NewChatPick(chatId: chatId, otherUid: widget.me.id, title: title));
    } catch (e) {
      debugPrint('ThixGroupComposerSheet: createGroup failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur création groupe.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.86,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Nouveau groupe', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Nom du groupe', prefixIcon: Icon(Icons.badge_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _q,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 250), () => _search(v));
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher des membres…',
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: _busy && _results.isEmpty
                    ? const ThixChatLoadingState()
                    : _results.isEmpty
                        ? ThixChatEmptyState(title: 'Membres', subtitle: 'Cherche des utilisateurs et coche-les.', icon: Icons.group_rounded)
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, i) {
                              final r = _results[i];
                              final selected = _selected.contains(r.uid);
                              return Material(
                                color: scheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                                ),
                                child: InkWell(
                                  onTap: () => setState(() => selected ? _selected.remove(r.uid) : _selected.add(r.uid)),
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      children: [
                                        Checkbox(value: selected, onChanged: (_) => setState(() => selected ? _selected.remove(r.uid) : _selected.add(r.uid))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(r.displayName, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              const SizedBox(height: 4),
                                              Text(r.thixId.isEmpty ? r.uid : r.thixId, style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70)), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary),
                  label: Text(_busy ? '...' : 'Créer', style: context.textStyles.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Meeting / Money composers
// =============================================================================
class ThixMeetingComposerSheet extends StatefulWidget {
  final Future<void> Function(String title, DateTime at, int durationMinutes, String? location, String? note) onSubmit;
  const ThixMeetingComposerSheet({super.key, required this.onSubmit});

  @override
  State<ThixMeetingComposerSheet> createState() => _ThixMeetingComposerSheetState();
}

class _ThixMeetingComposerSheetState extends State<ThixMeetingComposerSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _note = TextEditingController();
  DateTime _when = DateTime.now().add(const Duration(minutes: 30));
  int _duration = 30;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _when,
    );
    if (date == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (t == null) return;
    setState(() => _when = DateTime(date.year, date.month, date.day, t.hour, t.minute));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        _title.text.trim().isEmpty ? 'Meeting' : _title.text.trim(),
        _when,
        _duration,
        _location.text.trim().isEmpty ? null : _location.text.trim(),
        _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('ThixMeetingComposerSheet: submit failed err=$e');
      _snack('Erreur meeting.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.80,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Créer un meeting', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titre', prefixIcon: Icon(Icons.event_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: _location, decoration: const InputDecoration(labelText: 'Lieu (optionnel)', prefixIcon: Icon(Icons.place_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: _note, minLines: 1, maxLines: 3, decoration: const InputDecoration(labelText: 'Note (optionnel)', prefixIcon: Icon(Icons.notes_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.md),
              Material(
                color: scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quand', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(_when.toLocal().toString().substring(0, 16), style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.7))),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _pickTime,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.onSurface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.schedule_rounded, size: 18),
                        label: const Text('Choisir'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(child: Text('Durée (min)', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800))),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 15, label: Text('15')),
                      ButtonSegment(value: 30, label: Text('30')),
                      ButtonSegment(value: 60, label: Text('60')),
                    ],
                    selected: {_duration},
                    onSelectionChanged: _busy ? null : (s) => setState(() => _duration = s.first),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(_busy ? '...' : 'Envoyer', style: context.textStyles.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThixMoneyComposerSheet extends StatefulWidget {
  final Future<void> Function(
    String senderPhone,
    String receiverPhone,
    String network,
    String amount,
    String currency,
    String? note,
    String password,
  ) onSubmit;
  const ThixMoneyComposerSheet({super.key, required this.onSubmit});

  @override
  State<ThixMoneyComposerSheet> createState() => _ThixMoneyComposerSheetState();
}

class _ThixMoneyComposerSheetState extends State<ThixMoneyComposerSheet> {
  final _sender = TextEditingController();
  final _receiver = TextEditingController();
  final _network = TextEditingController();
  final _amount = TextEditingController();
  final _currency = TextEditingController(text: 'XOF');
  final _note = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _sender.dispose();
    _receiver.dispose();
    _network.dispose();
    _amount.dispose();
    _currency.dispose();
    _note.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        _sender.text,
        _receiver.text,
        _network.text,
        _amount.text,
        _currency.text,
        _note.text.trim().isEmpty ? null : _note.text.trim(),
        _password.text,
      );
      if (mounted) context.pop();
    } catch (e) {
      debugPrint('ThixMoneyComposerSheet: submit failed err=$e');
      _snack('Erreur transfert.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.86,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Transfert (sans wallet)', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
                  _ThreadAction(icon: Icons.close_rounded, tooltip: 'Fermer', onTap: () => context.pop()),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Numéro expéditeur + numéro destinataire + réseau, puis confirmation par mot de passe.',
                style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70), height: 1.45),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(controller: _sender, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro expéditeur', prefixIcon: Icon(Icons.phone_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: _receiver, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro destinataire', prefixIcon: Icon(Icons.phone_android_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: _network, decoration: const InputDecoration(labelText: 'Réseau (ex: Orange / MTN)', prefixIcon: Icon(Icons.cell_tower_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(child: TextField(controller: _amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Montant', prefixIcon: Icon(Icons.money_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)))),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 92,
                    child: TextField(controller: _currency, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Devise', contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(controller: _note, minLines: 1, maxLines: 2, decoration: const InputDecoration(labelText: 'Note (optionnel)', prefixIcon: Icon(Icons.edit_note_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10))),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe de confirmation', prefixIcon: Icon(Icons.lock_rounded), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(_busy ? '...' : 'Envoyer', style: context.textStyles.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IncomingCallSheet extends StatelessWidget {
  final String kind;
  final String callerId;
  final VoidCallback onDecline;
  final VoidCallback onAccept;
  const _IncomingCallSheet({required this.kind, required this.callerId, required this.onDecline, required this.onAccept});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isVideo = kind == 'video';
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.42,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border(top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppPremiumGradients.thixNavyToGold(scheme),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(isVideo ? Icons.videocam_rounded : Icons.call_rounded, size: 18, color: scheme.onPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appel entrant', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'De: $callerId',
                          style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isVideo ? 'Quelqu’un t’appelle en vidéo.' : 'Quelqu’un t’appelle en audio.',
                style: context.textStyles.bodyMedium?.copyWith(color: scheme.onSurface.withValues(alpha: 0.70), height: 1.45),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onSurface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.9)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.call_end_rounded, size: 18),
                      label: Text('Refuser', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: Icon(Icons.call_rounded, size: 18, color: scheme.onPrimary),
                      label: Text('Accepter', style: context.textStyles.labelLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
