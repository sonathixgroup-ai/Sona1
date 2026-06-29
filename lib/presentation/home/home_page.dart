import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/common/full_screen_message.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import 'package:thix_id/presentation/emergency/emergency_overlay.dart';
import 'package:thix_id/services/firestore_user_service.dart';
import 'package:thix_id/services/notification_service.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/services/thix_id_service.dart';

// ============================================================================
// CONSTANTES DE DESIGN – STYLE MIXX AMÉLIORÉ (NIVEAU FACEBOOK)
// ============================================================================

class AppColors {
  // Social/pro bright palette (aligned with global theme).
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

  // Premium card (more luminous)
  static const Color premiumSoftStart = Color(0xFFEAF2FF); // light blue tint
  static const Color premiumSoftEnd = Color(0xFFFFFFFF); // pure white
  static const Color premiumAccent = Color(0xFF0B3B8F);

  // Domain colors (icons)
  static const Color domainMedia = Color(0xFF7C3AED); // purple
  static const Color domainMarket = Color(0xFFF97316); // orange
  static const Color domainLearning = Color(0xFF2563EB); // blue
  static const Color domainJobs = Color(0xFF16A34A); // green
  static const Color domainInfo = Color(0xFF0284C7); // sky
  static const Color domainOpportunity = Color(0xFFF59E0B); // amber
  static const Color domainEvents = Color(0xFFEF4444); // red
  static const Color domainNetwork = Color(0xFF4F46E5); // indigo
  static const Color domainHealth = Color(0xFFE11D48); // rose
  static const Color domainMoney = Color(0xFF059669); // emerald
  static const Color domainGov = Color(0xFF334155); // slate
  static const Color domainReservation = Color(0xFF0D9488); // teal

  // Bottom bar (match capture)
  static const Color bottomNavBlue = Color(0xFF0B3B8F);
  static const Color bottomNavInactive = Color(0x99FFFFFF);
  static const Color bottomNavActive = goldBadge;
  static const Color bottomNavCenterIcon = Color(0xFF111827);
}

class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double huge = 32;
}

class AppRadius {
  static const double searchBar = 24;
  static const double mainCard = 22;
  static const double serviceCard = 18;
  static const double button = 14;
  static const double bottomNav = 30;
  static const double avatar = 50;
  static const double qrContainer = 16;
}

class AppShadows {
  static List<BoxShadow> main = [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> secondary = [
    BoxShadow(
      color: AppColors.shadowSecondary,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

class HomePagePremium extends StatefulWidget {
  const HomePagePremium({super.key});

  @override
  State<HomePagePremium> createState() => _HomePagePremiumState();
}

class _HomePagePremiumState extends State<HomePagePremium>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  late AnimationController _animationController;
  final PageController _headlinesController = PageController();
  Timer? _headlinesTimer;

  final _notifications = NotificationService();
  final _counters = NotificationCountersService();

  static final RegExp _uidLikeRegex = RegExp(r'^[A-Za-z0-9_-]{20,}$');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animationController.forward();
      _headlinesTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_headlinesController.hasClients) return;
        final next = (_headlinesController.page?.round() ?? 0) == 0 ? 1 : 0;
        _headlinesController.animateToPage(
          next,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOutCubic,
        );
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _headlinesTimer?.cancel();
    _headlinesController.dispose();
    super.dispose();
  }

  Future<void> _handleHomeSearchVerify() async {
    final raw = _searchController.text.trim();
    if (raw.isEmpty) {
      await FullScreenMessage.showError(
        context,
        title: 'Identifiant requis',
        message: 'Saisissez un THIX ID puis appuyez sur Vérifier.',
      );
      return;
    }

    final normalized = ThixIdService.normalize(raw);
    final isThix = normalized.startsWith('THIX-') && ThixIdService.isValid(normalized);
    final isUid = _uidLikeRegex.hasMatch(raw);

    if (!isThix && !isUid) {
      await FullScreenMessage.showError(
        context,
        title: 'Identifiant invalide',
        message: 'Format THIX ID incorrect.',
      );
      return;
    }

    setState(() => _searching = true);

    try {
      final userService = context.read<FirestoreUserService>();
      AppUser? user;

      if (isThix) {
        user = await userService.fetchUserByThixId(normalized);
      } else {
        user = await userService.fetchUserByUid(raw);
      }

      if (!mounted) return;

      if (user == null) {
        await FullScreenMessage.showError(
          context,
          title: 'Profil introuvable',
          message: 'Aucun profil trouvé.',
        );
        return;
      }

      final thix = user.thixId.trim().toUpperCase();
      if (thix.isNotEmpty && ThixIdService.isValid(thix)) {
        context.push('${AppRoutes.publicProfile}?thixId=$thix');
      } else {
        await ThixIdentitySheets.showVerifySheet(
          context,
          initialUidOrThixId: user.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await FullScreenMessage.showError(
        context,
        title: 'Erreur',
        message: "Impossible d'effectuer la vérification.",
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _onProfileTap() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      final t = auth.currentUser?.accountType;
      context.go(t == AccountType.enterprise ? AppRoutes.enterpriseDashboard : AppRoutes.userDashboard);
    } else {
      context.push(AppRoutes.login);
    }
  }

  Future<void> _openThixAi() async {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      context.go(AppRoutes.chat);
      return;
    }
    context.push(AppRoutes.login);
  }

  Future<void> _openEmergency() async {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      await EmergencyOverlay.show(context);
      return;
    }
    if (!mounted) return;
    context.push(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final safeTop = MediaQuery.paddingOf(context).top;
    final displayName = (auth.currentUser?.displayName.trim().isNotEmpty ?? false)
        ? auth.currentUser!.displayName.trim()
        : (auth.currentUser?.email.trim().isNotEmpty ?? false)
            ? auth.currentUser!.email.trim()
            : 'Nathan';
    final badgeCountsStream = auth.currentUser == null
        ? Stream.value(SectionBadgeCounts.zero)
        : _counters.streamCounts(auth.currentUser!.id);

    return Scaffold(
      backgroundColor: AppColors.lightGrayBg,
      body: Stack(
        children: [
          const _HomeSoftBackground(),
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  safeTop: safeTop,
                  displayName: displayName,
                  isAuthenticated: auth.isAuthenticated,
                  onProfileTap: _onProfileTap,
                  onAccountRequest: () {},
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _SearchBarOverlay(
                    controller: _searchController,
                    isSearching: _searching,
                    onVerify: _handleHomeSearchVerify,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _HeadlinesCarousel(
                    controller: _headlinesController,
                    onThixInfoTap: () => context.push(AppRoutes.thixInfo),
                    onOpportunityTap: () => context.push(AppRoutes.opportunities),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _QuickActionsRow(
                    onScanTap: _openThixAi,
                    onNfcTap: () => ThixIdentitySheets.showNfcScanSheet(context),
                    onChatTap: () => context.go(AppRoutes.chat),
                    onSecurityTap: _openEmergency,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                sliver: SliverToBoxAdapter(
                  child: StreamBuilder<SectionBadgeCounts>(
                    stream: badgeCountsStream,
                    builder: (context, snap) {
                      final counts = snap.data ?? SectionBadgeCounts.zero;
                      return _SectionCage(
                        title: 'Mes services',
                        child: _ServicesGrid(
                          counts: counts,
                          onServiceTap: (serviceKey) {
                            switch (serviceKey) {
                              case 'thixMedia':
                                context.push(AppRoutes.thixMedia);
                                break;
                              case 'thixMarket':
                                context.push(AppRoutes.thixMarket);
                                break;
                              case 'formations':
                                context.push(AppRoutes.trainingHome);
                                break;
                              case 'emplois':
                                context.push(AppRoutes.jobs);
                                break;
                              case 'thixInfo':
                                context.push(AppRoutes.thixInfo);
                                break;
                              case 'opportunites':
                                context.push(AppRoutes.opportunities);
                                break;
                              case 'evenements':
                                context.push(AppRoutes.events);
                                break;
                              case 'reseauPro':
                                context.push(AppRoutes.network);
                                break;
                              case 'thixSante':
                                context.push(AppRoutes.thixSante);
                                break;
                              case 'thixMoney':
                                context.push(AppRoutes.thixMoney);
                                break;
                              case 'reservation':
                                context.push(AppRoutes.reservation);
                                break;
                              default:
                                break;
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _PremiumStatusCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _PersonalisedSection(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl + 20)),
            ],
          ),
          if (_searching)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryBlue),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _FloatingBottomNav(onScanTap: () => ThixIdentitySheets.showQrScanSheet(context)),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double safeTop;
  final String displayName;
  final bool isAuthenticated;
  final VoidCallback onProfileTap;
  final VoidCallback onAccountRequest;

  _PinnedHeaderDelegate({
    required this.safeTop,
    required this.displayName,
    required this.isAuthenticated,
    required this.onProfileTap,
    required this.onAccountRequest,
  });

  double _headerExtent() => safeTop + 92;

  @override
  double get maxExtent => _headerExtent();

  @override
  double get minExtent => _headerExtent();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrayBg,
        boxShadow: overlapsContent
            ? [
                const BoxShadow(
                  color: AppColors.shadowSecondary,
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: _PremiumHeader(
        safeTop: safeTop,
        displayName: displayName,
        isAuthenticated: isAuthenticated,
        onProfileTap: onProfileTap,
        onAccountRequest: onAccountRequest,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return safeTop != oldDelegate.safeTop ||
        displayName != oldDelegate.displayName ||
        isAuthenticated != oldDelegate.isAuthenticated;
  }
}

class _HomeSoftBackground extends StatelessWidget {
  const _HomeSoftBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF7F9FF), AppColors.lightGrayBg],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -220,
              right: -180,
              child: _SoftBlob(size: 420, colors: const [Color(0x2A003BFF), Color(0x1400214F)]),
            ),
            Positioned(
              top: -120,
              left: -220,
              child: _SoftBlob(size: 360, colors: const [Color(0x1F003BFF), Color(0x1200214F)]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;
  const _SoftBlob({required this.size, required this.colors});
  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
        ),
      ),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final double safeTop;
  final String displayName;
  final bool isAuthenticated;
  final VoidCallback onProfileTap;
  final VoidCallback onAccountRequest;
  const _PremiumHeader({required this.safeTop, required this.displayName, required this.isAuthenticated, required this.onProfileTap, required this.onAccountRequest});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, safeTop + 10, AppSpacing.xl, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder, width: 0.5), boxShadow: AppShadows.secondary),
                child: const Icon(Icons.menu_rounded, color: AppColors.darkText, size: 18),
              ),
              const SizedBox(width: AppSpacing.m),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Welcome Back', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                  Text(displayName, style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder, width: 0.5), boxShadow: AppShadows.secondary), child: const Icon(Icons.search_rounded, color: AppColors.darkText, size: 18)),
              const SizedBox(width: AppSpacing.s),
              GestureDetector(
                onTap: () => NotificationsSheet.show(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder, width: 0.5), boxShadow: AppShadows.secondary),
                  child: Stack(
                    children: [
                      const Center(child: Icon(Icons.notifications_none_rounded, color: AppColors.darkText, size: 18)),
                      Positioned(right: 7, top: 7, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.white, width: 2), boxShadow: AppShadows.secondary, image: const DecorationImage(image: NetworkImage('https://i.pravatar.cc/150?img=11'), fit: BoxFit.cover)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchBarOverlay extends StatefulWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onVerify;
  const _SearchBarOverlay({required this.controller, required this.isSearching, required this.onVerify});
  @override
  State<_SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<_SearchBarOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.searchBar), boxShadow: AppShadows.secondary),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isSearching,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Rechercher un THIX ID...', hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              style: const TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          GestureDetector(
            onTap: widget.isSearching ? null : widget.onVerify,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.darkNavy]),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Text('Vérifier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const Icon(Icons.tune_rounded, size: 22, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _HeadlinesCarousel extends StatelessWidget {
  final PageController controller;
  final VoidCallback onThixInfoTap;
  final VoidCallback onOpportunityTap;

  const _HeadlinesCarousel({
    required this.controller,
    required this.onThixInfoTap,
    required this.onOpportunityTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = <({String title, String subtitle, IconData icon, VoidCallback onTap})>[
      (
        title: 'THIX INFO LIVE',
        subtitle: 'Actus vérifiées et alertes en temps réel',
        icon: Icons.newspaper_rounded,
        onTap: onThixInfoTap,
      ),
      (
        title: 'OPPORTUNITÉS',
        subtitle: 'Emplois, formations et missions disponibles',
        icon: Icons.trending_up_rounded,
        onTap: onOpportunityTap,
      ),
    ];

    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: controller,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _PressableScale(
              onTap: item.onTap,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryBlue, AppColors.darkNavy],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.mainCard),
                  boxShadow: AppShadows.main,
                ),
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.subtitle,
                            style: const TextStyle(
                              color: Color(0xE6FFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.premiumSoftStart, AppColors.premiumSoftEnd]), border: Border.all(color: AppColors.cardBorder, width: 0.7), borderRadius: BorderRadius.circular(AppRadius.mainCard), boxShadow: AppShadows.main),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.l),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.premiumAccent, size: 26),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Membre Premium', style: TextStyle(color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                Text('Score de confiance : 98%', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            decoration: BoxDecoration(color: AppColors.darkText, borderRadius: BorderRadius.circular(AppRadius.button)),
            child: const Text('Voir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onNfcTap;
  final VoidCallback onChatTap;
  final VoidCallback onSecurityTap;
  const _QuickActionsRow({required this.onScanTap, required this.onNfcTap, required this.onChatTap, required this.onSecurityTap});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Center(child: _QuickActionItem(icon: Icons.smart_toy_rounded, label: 'THIX IA', backgroundColor: AppColors.goldBadge, iconColor: AppColors.bottomNavCenterIcon, labelColor: AppColors.darkText, onTap: onScanTap))),
        Expanded(child: Center(child: _QuickActionItem(icon: Icons.nfc_rounded, label: 'NFC', backgroundColor: AppColors.goldBadge, iconColor: AppColors.bottomNavCenterIcon, labelColor: AppColors.darkText, onTap: onNfcTap))),
        Expanded(child: Center(child: _QuickActionItem(icon: Icons.forum_rounded, label: 'THIX CHAT', backgroundColor: AppColors.goldBadge, iconColor: AppColors.bottomNavCenterIcon, labelColor: AppColors.darkText, onTap: onChatTap))),
        Expanded(child: Center(child: _QuickActionItem(icon: Icons.emergency_rounded, label: 'URGENCE', backgroundColor: AppColors.dangerRed, iconColor: AppColors.white, labelColor: AppColors.dangerRed, onTap: onSecurityTap))),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;
  const _QuickActionItem({required this.icon, required this.label, required this.backgroundColor, required this.iconColor, required this.labelColor, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 14, offset: const Offset(0, 8))]), child: Icon(icon, color: iconColor, size: 26)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});
  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(scale: _pressed ? 0.96 : 1, duration: const Duration(milliseconds: 120), child: widget.child),
    );
  }
}

class _SectionCage extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCage({required this.title, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

class _ServicesGrid extends StatelessWidget {
  final SectionBadgeCounts counts;
  final ValueChanged<String> onServiceTap;
  const _ServicesGrid({required this.counts, required this.onServiceTap});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _PersonalisedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _FloatingBottomNav extends StatelessWidget {
  final VoidCallback onScanTap;
  const _FloatingBottomNav({required this.onScanTap});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
