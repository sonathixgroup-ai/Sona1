// lib/presentation/home/home_page.dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/common/full_screen_message.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/notification_service.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/services/thix_id_service.dart';
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/widgets/language_sheet.dart';
import 'package:thix_id/l10n/locale_controller.dart';

// ============================================================================
// CONSTANTES DE DESIGN
// ============================================================================
class AppColors {
  static const Color primaryBlue = Color(0xFF1877F2);
  static const Color darkNavy = Color(0xFF111827);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrayBg = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color goldBadge = Color(0xFFFBBF24);
  static const Color successGreen = Color(0xFF059669);
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color darkText = Color(0xFF111827);
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowSecondary = Color(0x0A000000);
  static const Color premiumSoftStart = Color(0xFFEAF2FF);
  static const Color premiumSoftEnd = Color(0xFFFFFFFF);
  static const Color premiumAccent = Color(0xFF0B3B8F);
  static const Color domainMedia = Color(0xFF7C3AED);
  static const Color domainMarket = Color(0xFFF97316);
  static const Color domainLearning = Color(0xFF2563EB);
  static const Color domainJobs = Color(0xFF16A34A);
  static const Color domainInfo = Color(0xFF0284C7);
  static const Color domainOpportunity = Color(0xFFF59E0B);
  static const Color domainEvents = Color(0xFFEF4444);
  static const Color domainNetwork = Color(0xFF4F46E5);
  static const Color domainHealth = Color(0xFFE11D48);
  static const Color domainMoney = Color(0xFF059669);
  static const Color domainGov = Color(0xFF334155);
  static const Color domainReservation = Color(0xFF0D9488);
}
class AppSpacing {
  static const double xs = 4; static const double s = 8; static const double m = 12; static const double l = 16; static const double xl = 20; static const double xxl = 24; static const double xxxl = 28;
}
class AppRadius {
  static const double searchBar = 24; static const double mainCard = 22; static const double serviceCard = 18; static const double button = 14; static const double bottomNav = 30; static const double full = 999;
}
class AppShadows {
  static List<BoxShadow> main = [BoxShadow(color: AppColors.shadowLight, blurRadius: 20, offset: const Offset(0, 4))];
  static List<BoxShadow> secondary = [BoxShadow(color: AppColors.shadowSecondary, blurRadius: 8, offset: const Offset(0, 2))];
}

// ============================================================================
// PAGE PRINCIPALE
// ============================================================================
class HomePagePremium extends StatefulWidget {
  const HomePagePremium({super.key});
  @override State<HomePagePremium> createState() => _HomePagePremiumState();
}
class _HomePagePremiumState extends State<HomePagePremium> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  late AnimationController _animationController;
  final PageController _headlinesController = PageController();
  final _counters = NotificationCountersService();
  final _profileService = ProfileService();
  static final RegExp _uidLikeRegex = RegExp(r'^[A-Za-z0-9_-]{20,}$');

  @override void initState() { super.initState(); _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this); WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _animationController.forward(); }); }
  @override void dispose() { _searchController.dispose(); _animationController.dispose(); _headlinesController.dispose(); super.dispose(); }

  Future<void> _handleHomeSearchVerify() async {
    final l10n = AppLocalizations.of(context);
    final raw = _searchController.text.trim();
    if (raw.isEmpty) { await FullScreenMessage.showError(context, title: l10n.t('home_required_id_title'), message: l10n.t('home_required_id_msg')); return; }
    final normalized = ThixIdService.normalize(raw);
    final isThix = normalized.startsWith('THIX-');
    final isUid = _uidLikeRegex.hasMatch(raw);
    if (!isThix && !isUid) { await FullScreenMessage.showError(context, title: l10n.t('home_invalid_id_title'), message: l10n.t('home_invalid_id_msg')); return; }
    setState(() => _searching = true);
    try {
      ThixProfile? profile;
      if (isThix) { profile = await _profileService.fetchPublicProfileByThixId(normalized); } else { profile = await _profileService.fetchPublicProfileByUserId(raw); }
      if (!mounted) return;
      if (profile == null) { await FullScreenMessage.showError(context, title: l10n.t('home_profile_not_found_title'), message: l10n.t('home_profile_not_found_msg')); return; }
      final thix = profile.thixId.trim().toUpperCase();
      if (thix.isNotEmpty) { context.push('${AppRoutes.publicProfile}?thixId=$thix'); } else { await ThixIdentitySheets.showVerifySheet(context, initialUidOrThixId: profile.userId); }
    } catch (e) { if (!mounted) return; await FullScreenMessage.showError(context, title: l10n.t('home_verify_error_title'), message: l10n.t('home_verify_error_msg')); } finally { if (mounted) { setState(() => _searching = false); } }
  }

  // --- NAVIGATION PROFIL ---
  void _onProfileTap() {
    HapticFeedback.mediumImpact();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      context.push(AppRoutes.login);
    } else {
      // Dashboard est dans la branche 3 du shell → go() pour basculer de branche
      context.go(AppRoutes.userDashboard);
    }
  }

  Future<void> _openThixAi() async { final auth = context.read<AuthController>(); if (auth.isAuthenticated) { context.push('/thix_ia'); return; } context.push(AppRoutes.login); }
  // Chat est dans la branche 2 → go() pour basculer de branche sans créer de doublon
  Future<void> _openThixChat() async { final auth = context.read<AuthController>(); if (auth.isAuthenticated) { context.go(AppRoutes.chat); } else { context.push(AppRoutes.login); } }
  
  Future<void> _openEmergency() async { 
    final auth = context.read<AuthController>(); 
    if (auth.isAuthenticated) { 
      context.push('/thix-urgent'); 
      return; 
    } 
    if (!mounted) return; 
    context.push(AppRoutes.login); 
  }
  
  void _openDocumentVault() { final auth = context.read<AuthController>(); if (auth.isAuthenticated) { context.push(AppRoutes.vault); } else { context.push(AppRoutes.login); } }
  void _openScanQr() => ThixIdentitySheets.showQrScanSheet(context);
  void _openMiniApps() { final l10n = AppLocalizations.of(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.t('home_mini_apps_coming_soon')))); }

  Future<void> _handleRequestAccount(BuildContext context) async {
    final auth = context.read<AuthController>();
    final res = await showModalBottomSheet<_AccountRequestChoice>(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const AccountRequestSheet());
    switch (res) { case _AccountRequestChoice.personal: if (auth.isAuthenticated) { await auth.signOut(); } if (context.mounted) { context.push(AppRoutes.personalReg); } return; case null: return; }
  }

  void _handleServiceTap(String serviceKey) {
    switch (serviceKey) {
      case 'thixMedia': context.push(AppRoutes.thixMedia); break;
      case 'thixMarket': context.push(AppRoutes.thixMarket); break;
      case 'formations': context.push(AppRoutes.trainingHome); break;
      case 'emplois': context.push(AppRoutes.jobs); break;
      case 'thixInfo': context.push(AppRoutes.thixInfo); break;
      case 'opportunites': context.push(AppRoutes.opportunities); break;
      case 'evenements': context.push('/thix-event'); break;
      // Réseau Pro est dans la branche 1 → go() pour basculer sans empiler
      case 'reseauPro': context.go(AppRoutes.network); break;
      case 'thixSante': context.push(AppRoutes.thixSante); break;
      case 'thixMoney': context.push(AppRoutes.thixMoney); break;
      case 'monPays': context.push(AppRoutes.monPays); break;
      case 'reservation': context.push(AppRoutes.reservation); break;
      case 'thixUrgent': context.push(AppRoutes.thixUrgent); break;
      default: break;
    }
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final safeTop = MediaQuery.paddingOf(context).top;
    final displayName = (auth.currentUser?.displayName.trim().isNotEmpty ?? false) ? auth.currentUser!.displayName.trim() : (auth.currentUser?.email.trim().isNotEmpty ?? false) ? auth.currentUser!.email.trim() : 'THIX ID';
    final photoUrl = auth.currentUser?.photoUrl;
    final badgeCountsStream = auth.currentUser == null ? Stream.value(SectionBadgeCounts.zero) : _counters.streamCounts(auth.currentUser!.id);
    
    return Scaffold(
      backgroundColor: AppColors.lightGrayBg,
      body: Stack(children: [
        const _HomeSoftBackground(),
        CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverPersistentHeader(pinned: true, delegate: _PinnedHeaderDelegate(safeTop: safeTop, displayName: displayName, photoUrl: photoUrl, isAuthenticated: auth.isAuthenticated, onProfileTap: _onProfileTap, onAccountRequest: () => _handleRequestAccount(context))),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: _SearchBarOverlay(controller: _searchController, isSearching: _searching, onVerify: _handleHomeSearchVerify))),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: _HeadlinesCarousel(controller: _headlinesController, uid: auth.currentUser?.id, onThixInfoTap: () => _handleServiceTap('thixInfo'), onOpportunityTap: () => _handleServiceTap('opportunites')))),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: _QuickActionsRow(onScanTap: _openThixAi, onDocumentTap: _openDocumentVault, onChatTap: _openThixChat, onSecurityTap: _openEmergency))),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s)),
          SliverToBoxAdapter(child: StreamBuilder<SectionBadgeCounts>(stream: badgeCountsStream, builder: (context, snap) { final counts = snap.data ?? SectionBadgeCounts.zero; return _ServicesConstellation(counts: counts, onServiceTap: _handleServiceTap, onHomeTap: () => context.go(AppRoutes.home), onMiniAppsTap: _openMiniApps); })),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: _PremiumStatusCard())),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl), child: _PersonalisedSection())),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl + 24)),
        ]),
        if (_searching) Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.4), child: const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))),
      ]),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double safeTop; final String displayName; final String? photoUrl; final bool isAuthenticated; final VoidCallback onProfileTap; final VoidCallback onAccountRequest;
  _PinnedHeaderDelegate({required this.safeTop, required this.displayName, required this.photoUrl, required this.isAuthenticated, required this.onProfileTap, required this.onAccountRequest});
  double _headerExtent() => safeTop + 92; @override double get maxExtent => _headerExtent(); @override double get minExtent => _headerExtent();
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) { return Container(decoration: BoxDecoration(color: AppColors.lightGrayBg, boxShadow: overlapsContent ? AppShadows.secondary : const []), child: _PremiumHeader(safeTop: safeTop, displayName: displayName, photoUrl: photoUrl, isAuthenticated: isAuthenticated, onProfileTap: onProfileTap, onAccountRequest: onAccountRequest)); }
  @override bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) { return safeTop != oldDelegate.safeTop || displayName != oldDelegate.displayName || photoUrl != oldDelegate.photoUrl || isAuthenticated != oldDelegate.isAuthenticated || onProfileTap != oldDelegate.onProfileTap || onAccountRequest != oldDelegate.onAccountRequest; }
}

// BACKGROUND
class _HomeSoftBackground extends StatelessWidget { const _HomeSoftBackground(); @override Widget build(BuildContext context) { return IgnorePointer(child: RepaintBoundary(child: Stack(children: [Positioned(top: -80, left: -40, child: _SoftBlob(size: 220, colors: [AppColors.primaryBlue.withValues(alpha: 0.16), Colors.transparent])), Positioned(top: 120, right: -60, child: _SoftBlob(size: 180, colors: [AppColors.domainOpportunity.withValues(alpha: 0.14), Colors.transparent])), Positioned(bottom: 30, left: -50, child: _SoftBlob(size: 200, colors: [AppColors.domainNetwork.withValues(alpha: 0.12), Colors.transparent]))]))); } }
class _SoftBlob extends StatelessWidget { final double size; final List<Color> colors; const _SoftBlob({required this.size, required this.colors}); @override Widget build(BuildContext context) { return ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: colors)))); } }

// HEADER
class _PremiumHeader extends StatelessWidget {
  final double safeTop; final String displayName; final String? photoUrl; final bool isAuthenticated; final VoidCallback onProfileTap; final VoidCallback onAccountRequest;
  const _PremiumHeader({required this.safeTop, required this.displayName, required this.photoUrl, required this.isAuthenticated, required this.onProfileTap, required this.onAccountRequest});
  @override Widget build(BuildContext context) {
    final trimmedPhoto = (photoUrl ?? '').trim();
    final localeCode = context.select<LocaleController, String>((c) => c.locale.languageCode);
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, safeTop + 10, AppSpacing.xl, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // RETRAIT du GestureDetector sur le texte d'accueil
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            const _RotatingGreeting(),
            Row(children: [Flexible(child: Text(displayName, style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.3), overflow: TextOverflow.ellipsis)), const SizedBox(width: 8), if (isAuthenticated) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.premiumAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)), child: Text(AppLocalizations.of(context).t('home_premium_member'), style: const TextStyle(color: AppColors.premiumAccent, fontSize: 10, fontWeight: FontWeight.w800))) else GestureDetector(onTap: onAccountRequest, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)), child: const Text('Créer un compte', style: TextStyle(color: AppColors.primaryBlue, fontSize: 10, fontWeight: FontWeight.w800))))]),
          ]),
        ),
        Row(children: [
          Material(color: Colors.white, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: () { HapticFeedback.lightImpact(); showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => const LanguageSheet()); }, child: Padding(padding: const EdgeInsets.all(10), child: Text(localeCode.toUpperCase(), style: const TextStyle(color: AppColors.darkText, fontSize: 11, fontWeight: FontWeight.w800))))),
          const SizedBox(width: 10),
          // CLIC UNIQUEMENT SUR L'AVATAR
          GestureDetector(
            onTap: onProfileTap, 
            child: Container(
              width: 40, height: 40, 
              padding: const EdgeInsets.all(2), 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white, 
                border: Border.all(color: AppColors.primaryBlue, width: 2), 
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))]
              ), 
              child: ClipOval(
                child: trimmedPhoto.isNotEmpty 
                  ? Image.network(trimmedPhoto, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.lightGrayBg, child: const Icon(Icons.person_rounded))) 
                  : Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1), 
                      child: const Icon(Icons.person_rounded, color: AppColors.primaryBlue)
                    )
              )
            ),
          ),
        ])
      ]),
    );
  }
}

class _RotatingGreeting extends StatefulWidget { const _RotatingGreeting(); @override State<_RotatingGreeting> createState() => _RotatingGreetingState(); }
class _RotatingGreetingState extends State<_RotatingGreeting> { static const List<Map<String, String>> _greetings = [{'lang': 'Lingala', 'text': 'Mbote'}, {'lang': 'Kiswahili', 'text': 'Jambo'}, {'lang': 'Français', 'text': 'Bonjour'}, {'lang': 'English', 'text': 'Hello'}]; int _index = 0; Timer? _timer; @override void initState() { super.initState(); _timer = Timer.periodic(const Duration(seconds: 3), (_) { if (mounted) setState(() => _index = (_index + 1) % _greetings.length); }); } @override void dispose() { _timer?.cancel(); super.dispose(); } @override Widget build(BuildContext context) { final item = _greetings[_index]; return Text('${item['text']} • ${item['lang']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)); } }

// SEARCH BAR 
class _SearchBarOverlay extends StatefulWidget { final TextEditingController controller; final bool isSearching; final VoidCallback onVerify; const _SearchBarOverlay({required this.controller, required this.isSearching, required this.onVerify}); @override State<_SearchBarOverlay> createState() => _SearchBarOverlayState(); }
class _SearchBarOverlayState extends State<_SearchBarOverlay> {
  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 58, padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: AppShadows.secondary),
      child: Row(children: [
        const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary), const SizedBox(width: 10),
        Expanded(child: TextField(controller: widget.controller, enabled: !widget.isSearching, textAlignVertical: TextAlignVertical.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkText), decoration: InputDecoration(border: InputBorder.none, hintText: l10n.t('home_search_placeholder'), hintStyle: const TextStyle(color: AppColors.textSecondary)), onSubmitted: (_) => widget.onVerify())),
        const SizedBox(width: 8),
        GestureDetector(onTap: widget.isSearching ? null : widget.onVerify, child: Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 18), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.premiumAccent]), borderRadius: BorderRadius.circular(20)), alignment: Alignment.center, child: Text(l10n.t('home_verify_btn'), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)))) ,
        IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded, size: 22, color: AppColors.textSecondary)),
      ]),
    );
  }
}
class _PremiumStatusCard extends StatelessWidget { const _PremiumStatusCard({super.key}); @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context); return Container(height: 84, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.mainCard), boxShadow: AppShadows.secondary), child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.premiumAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.workspace_premium_rounded, color: AppColors.premiumAccent)), const SizedBox(width: AppSpacing.m), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.t('home_premium_member'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkText)), const Text('THIX ID', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))])), const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)]))); } }

// QUICK ACTIONS 
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onScanTap; final VoidCallback onDocumentTap; final VoidCallback onChatTap; final VoidCallback onSecurityTap;
  const _QuickActionsRow({required this.onScanTap, required this.onDocumentTap, required this.onChatTap, required this.onSecurityTap});
  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(children: [
      Expanded(child: Center(child: _QuickActionItem(icon: Icons.smart_toy_rounded, label: l10n.t('quickThixIA'), accent: AppColors.premiumAccent, onTap: onScanTap))),
      Expanded(child: Center(child: _QuickActionItem(icon: Icons.folder_shared_rounded, label: 'THIX DOC', accent: AppColors.domainLearning, onTap: onDocumentTap))),
      Expanded(child: Center(child: _QuickActionItem(icon: Icons.forum_rounded, label: l10n.t('quickChat'), accent: AppColors.domainNetwork, onTap: onChatTap))),
      Expanded(child: Center(child: _QuickActionItem(icon: Icons.emergency_rounded, label: 'THIX SOS', accent: AppColors.dangerRed, onTap: onSecurityTap))),
    ]);
  }
}
class _QuickActionItem extends StatelessWidget { final IconData icon; final String label; final Color accent; final VoidCallback onTap; const _QuickActionItem({required this.icon, required this.label, required this.accent, required this.onTap}); @override Widget build(BuildContext context) { return _PressableScale(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: accent, size: 28)), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkText))])); } }
class _PressableScale extends StatefulWidget { final Widget child; final VoidCallback onTap; const _PressableScale({required this.child, required this.onTap}); @override State<_PressableScale> createState() => _PressableScaleState(); }
class _PressableScaleState extends State<_PressableScale> { bool _pressed = false; void _setPressed(bool v) { if (_pressed == v) return; setState(() => _pressed = v); } @override Widget build(BuildContext context) { return GestureDetector(onTap: widget.onTap, onTapDown: (_) => _setPressed(true), onTapUp: (_) => _setPressed(false), onTapCancel: () => _setPressed(false), child: AnimatedScale(scale: _pressed ? 0.94 : 1, duration: const Duration(milliseconds: 120), child: widget.child)); } }

class _ServiceNodeData { final String key; final IconData icon; final String title; final Color color; final int? badge; const _ServiceNodeData({required this.key, required this.icon, required this.title, required this.color, this.badge}); }
class _HubMenuItemData { final IconData icon; final String label; final VoidCallback onTap; const _HubMenuItemData({required this.icon, required this.label, required this.onTap}); }
class _ServicesConstellation extends StatefulWidget { final SectionBadgeCounts counts; final void Function(String key) onServiceTap; final VoidCallback onHomeTap; final VoidCallback onMiniAppsTap; const _ServicesConstellation({required this.counts, required this.onServiceTap, required this.onHomeTap, required this.onMiniAppsTap}); @override State<_ServicesConstellation> createState() => _ServicesConstellationState(); }
class _ServicesConstellationState extends State<_ServicesConstellation> with TickerProviderStateMixin {
  late final AnimationController _shineController; late final AnimationController _pulseController; bool _menuExpanded = false; Timer? _collapseTimer;
  static const double _stageHeight = 360; static const double _hubRadius = 34; static const double _hubMenuRadius = 58; static const double _hubMenuNodeSize = 30;
  @override void initState() { super.initState(); _shineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(); _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true); }
  @override void dispose() { _shineController.dispose(); _pulseController.dispose(); _collapseTimer?.cancel(); super.dispose(); }
  void _armAutoCollapse() { _collapseTimer?.cancel(); _collapseTimer = Timer(const Duration(seconds: 10), () { if (mounted) setState(() => _menuExpanded = false); }); }
  void _toggleHubMenu() { HapticFeedback.mediumImpact(); setState(() => _menuExpanded = !_menuExpanded); if (_menuExpanded) { _armAutoCollapse(); } else { _collapseTimer?.cancel(); } }
  void _runHubItem(VoidCallback action) { _collapseTimer?.cancel(); setState(() => _menuExpanded = false); action(); }
  
  List<_ServiceNodeData> _nodes(AppLocalizations l10n) {
    final c = widget.counts;
    return [
      _ServiceNodeData(key: 'thixMedia', icon: Icons.play_circle_filled, title: 'TDIA', color: AppColors.domainMedia),
      _ServiceNodeData(key: 'thixMarket', icon: Icons.storefront_rounded, title: l10n.t('serviceMarket'), color: AppColors.domainMarket),
      _ServiceNodeData(key: 'formations', icon: Icons.school_rounded, title: l10n.t('serviceFormations'), color: AppColors.domainLearning, badge: c.formations),
      _ServiceNodeData(key: 'emplois', icon: Icons.work_rounded, title: l10n.t('serviceEmplois'), color: AppColors.domainJobs, badge: c.jobs),
      _ServiceNodeData(key: 'thixInfo', icon: Icons.newspaper_rounded, title: 'THIX MEDIA', color: AppColors.domainInfo, badge: c.info),
      _ServiceNodeData(key: 'opportunites', icon: Icons.lightbulb_rounded, title: l10n.t('serviceOpportunites'), color: AppColors.domainOpportunity),
      _ServiceNodeData(key: 'evenements', icon: Icons.event_rounded, title: l10n.t('serviceEvenements'), color: AppColors.domainEvents, badge: c.events),
      _ServiceNodeData(key: 'reseauPro', icon: Icons.groups_rounded, title: l10n.t('serviceReseauPro'), color: AppColors.domainNetwork),
      _ServiceNodeData(key: 'thixSante', icon: Icons.local_hospital_rounded, title: l10n.t('serviceSante'), color: AppColors.domainHealth),
      _ServiceNodeData(key: 'thixMoney', icon: Icons.account_balance_wallet_rounded, title: l10n.t('serviceMoney'), color: AppColors.domainMoney),
      _ServiceNodeData(key: 'monPays', icon: Icons.flag, title: l10n.t('serviceMonPays'), color: AppColors.domainGov),
      _ServiceNodeData(key: 'reservation', icon: Icons.confirmation_number_rounded, title: l10n.t('serviceReservation'), color: AppColors.domainReservation)
    ];
  }

  Offset _polar(Offset center, double angleDeg, double radius) { final rad = angleDeg * math.pi / 180; return center + Offset(radius * math.cos(rad), radius * math.sin(rad)); }
  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nodes = _nodes(l10n);
    final hubItems = <_HubMenuItemData>[_HubMenuItemData(icon: Icons.home_filled, label: l10n.t('hub_home'), onTap: () => _runHubItem(widget.onHomeTap)), _HubMenuItemData(icon: Icons.apps_rounded, label: l10n.t('hub_mini_apps'), onTap: () => _runHubItem(widget.onMiniAppsTap))];
    return Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.hub_rounded, color: AppColors.darkText), const SizedBox(width: 8), const Text('THIX Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkText)), const Spacer(), IconButton(onPressed: _toggleHubMenu, icon: Icon(_menuExpanded ? Icons.close_rounded : Icons.more_horiz_rounded, color: AppColors.darkText))]), if (_menuExpanded) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.m), child: Wrap(spacing: 10, runSpacing: 10, children: [for (final item in hubItems) ActionChip(avatar: Icon(item.icon, size: 18), label: Text(item.label), onPressed: item.onTap)])), Container(padding: const EdgeInsets.all(AppSpacing.l), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.mainCard), boxShadow: AppShadows.secondary), child: Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [for (final node in nodes) SizedBox(width: 92, child: _ConstellationNode(data: node, onTap: () => widget.onServiceTap(node.key)))]))]));
  }
}
class _HubSatelliteButton extends StatelessWidget { final bool visible; final int order; final double size; final IconData icon; final String label; final VoidCallback onTap; const _HubSatelliteButton({required this.visible, required this.order, required this.size, required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) { return AnimatedOpacity(opacity: visible ? 1 : 0, duration: Duration(milliseconds: 140 + (order * 40)), child: IgnorePointer(ignoring: !visible, child: GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [Container(width: size, height: size, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppShadows.secondary), child: Icon(icon, size: size * 0.5, color: AppColors.darkText)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700))])))); } }
class _RadialBranchesPainter extends CustomPainter { final Offset center; final List<Offset> nodeOffsets; final double shineProgress; _RadialBranchesPainter({required this.center, required this.nodeOffsets, required this.shineProgress}); @override void paint(Canvas canvas, Size size) { final base = Paint()..color = AppColors.cardBorder..strokeWidth = 1.5; final shine = Paint()..color = AppColors.primaryBlue.withValues(alpha: 0.18 + (0.18 * shineProgress))..strokeWidth = 2.2; for (final node in nodeOffsets) { canvas.drawLine(center, node, base); canvas.drawLine(center, Offset.lerp(center, node, 0.35 + (0.15 * shineProgress))!, shine); } } @override bool shouldRepaint(covariant _RadialBranchesPainter oldDelegate) { return center != oldDelegate.center || nodeOffsets != oldDelegate.nodeOffsets || shineProgress != oldDelegate.shineProgress; } }
class _ConstellationNode extends StatefulWidget { final _ServiceNodeData data; final VoidCallback onTap; const _ConstellationNode({required this.data, required this.onTap}); @override State<_ConstellationNode> createState() => _ConstellationNodeState(); }
class _ConstellationNodeState extends State<_ConstellationNode> with SingleTickerProviderStateMixin { late AnimationController _controller; late Animation<double> _scale; @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true); _scale = Tween<double>(begin: 1, end: 1.04).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); } @override void dispose() { _controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) { return GestureDetector(onTap: widget.onTap, child: ScaleTransition(scale: _scale, child: Stack(clipBehavior: Clip.none, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), decoration: BoxDecoration(color: widget.data.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: widget.data.color.withValues(alpha: 0.18))), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(widget.data.icon, color: widget.data.color, size: 24), const SizedBox(height: 8), Text(widget.data.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.darkText))])), if ((widget.data.badge ?? 0) > 0) Positioned(right: -4, top: -4, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.dangerRed, borderRadius: BorderRadius.circular(999)), child: Text('${widget.data.badge}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800))))]))); } }

// HEADLINES CAROUSEL
class _HeadlinesCarousel extends StatefulWidget { final PageController controller; final String? uid; final VoidCallback onThixInfoTap; final VoidCallback onOpportunityTap; const _HeadlinesCarousel({required this.controller, required this.uid, required this.onThixInfoTap, required this.onOpportunityTap}); @override State<_HeadlinesCarousel> createState() => _HeadlinesCarouselState(); }
class _HeadlinesCarouselState extends State<_HeadlinesCarousel> { late final Stream<List<Map<String, dynamic>>> _articlesStream; late final Stream<List<Map<String, dynamic>>> _opportunitiesStream; @override void initState() { super.initState(); _articlesStream = Stream.value([{'title': 'THIX ID', 'imageUrl': null}]); _opportunitiesStream = Stream.value([{'title': 'THIX ID'}]); } @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context); return SizedBox(height: 176, child: StreamBuilder<List<Map<String, dynamic>>>(stream: _articlesStream, builder: (context, articleSnap) { return StreamBuilder<List<Map<String, dynamic>>>(stream: _opportunitiesStream, builder: (context, oppSnap) { final items = <Map<String, dynamic>>[{'label': l10n.t('home_headline_thixinfo_label'), 'title': articleSnap.data?.first['title']?.toString() ?? l10n.t('home_headline_thixinfo_default'), 'icon': Icons.newspaper_rounded, 'accent': AppColors.domainInfo, 'imageUrl': articleSnap.data?.first['imageUrl']?.toString(), 'onTap': widget.onThixInfoTap}, {'label': l10n.t('home_headline_opportunity_label'), 'title': oppSnap.data?.first['title']?.toString() ?? l10n.t('home_headline_opportunity_default'), 'icon': Icons.lightbulb_rounded, 'accent': AppColors.domainOpportunity, 'imageUrl': null, 'onTap': widget.onOpportunityTap}]; return Column(children: [Expanded(child: PageView.builder(controller: widget.controller, itemCount: items.length, itemBuilder: (context, index) { final item = items[index]; return Padding(padding: const EdgeInsets.only(right: 4), child: _HeadlineBanner(label: item['label'] as String, title: item['title'] as String, icon: item['icon'] as IconData, accent: item['accent'] as Color, imageUrl: item['imageUrl'] as String?, height: 160, onTap: item['onTap'] as VoidCallback)); })), const SizedBox(height: 10), _CarouselDots(controller: widget.controller, count: items.length)]); }); })); } }
class _CarouselDots extends StatefulWidget { final PageController controller; final int count; const _CarouselDots({required this.controller, required this.count}); @override State<_CarouselDots> createState() => _CarouselDotsState(); }
class _CarouselDotsState extends State<_CarouselDots> { int _page = 0; @override void initState() { super.initState(); widget.controller.addListener(_onScroll); } void _onScroll() { if (!widget.controller.hasClients) return; final next = widget.controller.page?.round() ?? widget.controller.initialPage; if (_page != next && mounted) setState(() => _page = next); } @override void dispose() { widget.controller.removeListener(_onScroll); super.dispose(); } @override Widget build(BuildContext context) { return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.count, (index) => AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.symmetric(horizontal: 3), width: _page == index ? 18 : 6, height: 6, decoration: BoxDecoration(color: _page == index ? AppColors.primaryBlue : AppColors.cardBorder, borderRadius: BorderRadius.circular(999))))); } }
class _HeadlineBanner extends StatelessWidget { final String label; final String title; final IconData icon; final Color accent; final String? imageUrl; final double height; final VoidCallback onTap; const _HeadlineBanner({required this.label, required this.title, required this.icon, required this.accent, required this.imageUrl, required this.height, required this.onTap}); @override Widget build(BuildContext context) { final hasImage = (imageUrl ?? '').trim().isNotEmpty; return GestureDetector(onTap: onTap, child: Container(height: height, decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.mainCard), gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.8)]), image: hasImage ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken)) : null, boxShadow: AppShadows.secondary), child: Padding(padding: const EdgeInsets.all(AppSpacing.l), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))), const Spacer(), Icon(icon, color: Colors.white, size: 30), const SizedBox(height: 10), Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.1))])))); } }
class _PersonalisedSection extends StatelessWidget { @override Widget build(BuildContext context) { final l10n = AppLocalizations.of(context); final items = [_MiniRoundAction(icon: Icons.account_balance_wallet_rounded, label: l10n.t('home_mini_top_up')), _MiniRoundAction(icon: Icons.shopping_bag_rounded, label: l10n.t('home_mini_buy')), _MiniRoundAction(icon: Icons.shield_moon_rounded, label: l10n.t('home_mini_secure')), _MiniRoundAction(icon: Icons.outbox_rounded, label: l10n.t('home_mini_cash_out'))]; return Container(padding: const EdgeInsets.all(AppSpacing.l), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.mainCard), boxShadow: AppShadows.secondary), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l10n.t('home_personalised_title'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.darkText)), const SizedBox(height: AppSpacing.l), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: items.map((item) => Expanded(child: Center(child: item))).toList())])); } }
class _MiniRoundAction extends StatelessWidget { final IconData icon; final String label; const _MiniRoundAction({required this.icon, required this.label}); @override Widget build(BuildContext context) { return Column(mainAxisSize: MainAxisSize.min, children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.lightGrayBg, borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: AppColors.darkText)), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkText))]); } }

enum _AccountRequestChoice { personal }

class AccountRequestSheet extends StatelessWidget { 
  const AccountRequestSheet({super.key}); 
  @override 
  Widget build(BuildContext context) { 
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white, 
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
      ), 
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl), 
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(width: 35, height: 4, decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2))), 
            const SizedBox(height: AppSpacing.l), 
            Text(l10n.t('account_request_title'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkText)), 
            const SizedBox(height: AppSpacing.xl), 
            _OptionButton(
              icon: Icons.person_outline, 
              title: l10n.t('account_personal'), 
              subtitle: l10n.t('account_personal_desc'), 
              onTap: () { 
                Navigator.pop(context, _AccountRequestChoice.personal); 
              }
            ), 
            const SizedBox(height: AppSpacing.m)
          ]
        )
      )
    ); 
  } 
}

class _OptionButton extends StatelessWidget { 
  final IconData icon; 
  final String title; 
  final String subtitle; 
  final VoidCallback onTap; 
  const _OptionButton({required this.icon, required this.title, required this.subtitle, required this.onTap}); 
  @override 
  Widget build(BuildContext context) { 
    return GestureDetector(
      onTap: onTap, 
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m), 
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder), 
          borderRadius: BorderRadius.circular(14), 
          color: AppColors.lightGrayBg
        ), 
        child: Row(
          children: [
            Container(
              width: 38, 
              height: 38, 
              decoration: BoxDecoration(
                color: AppColors.darkText.withValues(alpha: 0.06), 
                borderRadius: BorderRadius.circular(10)
              ), 
              child: Icon(icon, color: AppColors.darkText, size: 20)
            ), 
            const SizedBox(width: AppSpacing.m), 
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkText)), 
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                ]
              )
            ), 
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary)
          ]
        )
      )
    ); 
  } 
}
