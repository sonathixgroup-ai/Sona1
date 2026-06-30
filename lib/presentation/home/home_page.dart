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
  static const double sm = 10;
  static const double m = 12;
  static const double md = 14;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double huge = 32;
}

class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 16;
  static const double searchBar = 24;
  static const double mainCard = 22;
  static const double serviceCard = 18;
  static const double button = 14;
  static const double bottomNav = 30;
  static const double avatar = 50;
  static const double qrContainer = 16;
  static const double full = 999;
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

// ============================================================================
// PAGE PRINCIPALE – HOMEPAGE STYLE FACEBOOK (HEADER BLANC, SERVICES PLATS)
// ============================================================================

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
  late ValueNotifier<int> _headlineIndex;
  Timer? _headlinesTimer;

  final _notifications = NotificationService();
  final _counters = NotificationCountersService();

  static final RegExp _uidLikeRegex = RegExp(r'^[A-Za-z0-9_-]{20,}$');

  @override
  void initState() {
    super.initState();

    // Performance: keep initState extremely light.
    // We start animations/timers after the first frame so the initial paint is faster.
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headlineIndex = ValueNotifier<int>(0);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _animationController.forward();
      _headlinesTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        _headlineIndex.value = _headlineIndex.value == 0 ? 1 : 0;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _headlinesTimer?.cancel();
    _headlineIndex.dispose();
    super.dispose();
  }

  Future<void> _handleHomeSearchVerify() async {
    final raw = _searchController.text.trim();

    if (raw.isEmpty) {
      await FullScreenMessage.showError(
        context,
        title: 'Identifiant requis',
        message: "Saisissez un THIX ID puis appuyez sur Vérifier.",
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
      // Performance/architecture: reuse the app-wide instance instead of
      // creating a new service (which can create extra clients/streams).
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
          message: "Aucun profil trouvé.",
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
      if (mounted) {
        setState(() => _searching = false);
      }
    }
  }

  void _onProfileTap() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      final t = auth.currentUser?.accountType;
      context.go(
        t == AccountType.enterprise
            ? AppRoutes.enterpriseDashboard
            : AppRoutes.userDashboard,
      );
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

  Future<void> _handleRequestAccount(BuildContext context) async {
    final auth = context.read<AuthController>();
    final res = await showModalBottomSheet<_AccountRequestChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AccountRequestSheet(),
    );

    switch (res) {
      case _AccountRequestChoice.personal:
        if (auth.isAuthenticated) {
          await auth.signOut();
        }
        if (context.mounted) {
          context.push(AppRoutes.personalReg);
        }
        return;

      case _AccountRequestChoice.enterprise:
        if (auth.isAuthenticated) {
          await auth.signOut();
        }
        if (context.mounted) {
          context.push(AppRoutes.enterpriseReg);
        }
        return;

      case null:
        return;
    }
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
                  onAccountRequest: () => _handleRequestAccount(context),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),

              // Barre de recherche
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

              // Bannière passante (THIX Info / Opportunity)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _HeadlinesCarousel(
                    headlineIndex: _headlineIndex,
                    onThixInfoTap: () => context.push(AppRoutes.thixInfo),
                    onOpportunityTap: () => context.push(AppRoutes.opportunities),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),

              // Actions rapides (4 boutons)
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

              // Mes services (encadré + spacing réduit)
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
                              case 'servicesGov':
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

              // Carte Premium (repositionnée)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _PremiumStatusCard(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.m)),

              // Section personnalisée
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
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _FloatingBottomNav(
        onScanTap: () => ThixIdentitySheets.showQrScanSheet(context),
      ),
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

// ============================================================================
// COMPOSANTS (STYLE FACEBOOK)
// ============================================================================

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
              child: _SoftBlob(
                size: 420,
                colors: const [Color(0x2A003BFF), Color(0x1400214F)],
              ),
            ),
            Positioned(
              top: -120,
              left: -220,
              child: _SoftBlob(
                size: 360,
                colors: const [Color(0x1F003BFF), Color(0x1200214F)],
              ),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }
}

// ---- HEADER (Facebook-style) ----
class _PremiumHeader extends StatelessWidget {
  final double safeTop;
  final String displayName;
  final bool isAuthenticated;
  final VoidCallback onProfileTap;
  final VoidCallback onAccountRequest;

  const _PremiumHeader({
    required this.safeTop,
    required this.displayName,
    required this.isAuthenticated,
    required this.onProfileTap,
    required this.onAccountRequest,
  });

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
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 0.5),
                  boxShadow: AppShadows.secondary,
                ),
                child: const Icon(Icons.menu_rounded, color: AppColors.darkText, size: 18),
              ),
              const SizedBox(width: AppSpacing.m),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder, width: 0.5),
                  boxShadow: AppShadows.secondary,
                ),
                child: const Icon(Icons.search_rounded, color: AppColors.darkText, size: 18),
              ),
              const SizedBox(width: AppSpacing.s),
              GestureDetector(
                onTap: () => NotificationsSheet.show(context),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder, width: 0.5),
                    boxShadow: AppShadows.secondary,
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.darkText,
                          size: 18,
                        ),
                      ),
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.dangerRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                    boxShadow: AppShadows.secondary,
                    image: const DecorationImage(
                      image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- BARRE DE RECHERCHE ----
class _SearchBarOverlay extends StatefulWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onVerify;

  const _SearchBarOverlay({
    required this.controller,
    required this.isSearching,
    required this.onVerify,
  });

  @override
  State<_SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<_SearchBarOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.searchBar),
        boxShadow: AppShadows.secondary,
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isSearching,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Rechercher un THIX ID...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.isSearching ? null : widget.onVerify,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.s),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.darkNavy],
                ),
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Text(
                'Vérifier',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          const Icon(Icons.tune_rounded, size: 22, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

// ---- CAROUSEL DE HEADLINES ----
class _HeadlinesCarousel extends StatelessWidget {
  final ValueNotifier<int> headlineIndex;
  final VoidCallback onThixInfoTap;
  final VoidCallback onOpportunityTap;

  const _HeadlinesCarousel({
    required this.headlineIndex,
    required this.onThixInfoTap,
    required this.onOpportunityTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: headlineIndex,
      builder: (context, index, _) {
        final headlines = [
          {'title': 'THIX Info', 'icon': Icons.newspaper_rounded, 'onTap': onThixInfoTap},
          {'title': 'Opportunités', 'icon': Icons.lightbulb_rounded, 'onTap': onOpportunityTap},
        ];
        final headline = headlines[index % headlines.length];
        return GestureDetector(
          onTap: headline['onTap'] as VoidCallback,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.premiumSoftStart, AppColors.premiumSoftEnd],
              ),
              borderRadius: BorderRadius.circular(AppRadius.mainCard),
              boxShadow: AppShadows.main,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(headline['icon'] as IconData, size: 32, color: AppColors.premiumAccent),
                  const SizedBox(height: 8),
                  Text(
                    headline['title'] as String,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---- CARTE STATUT PREMIUM ----
class _PremiumStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.premiumSoftStart, AppColors.premiumSoftEnd],
        ),
        border: Border.all(color: AppColors.cardBorder, width: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        boxShadow: AppShadows.main,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.l),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.premiumAccent, size: 26),
          const SizedBox(width: AppSpacing.m),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Membre Premium',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Score de confiance : 98%',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.darkText,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Text(
              'Voir',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- ACTIONS RAPIDES ----
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onNfcTap;
  final VoidCallback onChatTap;
  final VoidCallback onSecurityTap;

  const _QuickActionsRow({
    required this.onScanTap,
    required this.onNfcTap,
    required this.onChatTap,
    required this.onSecurityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: _QuickActionItem(
              icon: Icons.smart_toy_rounded,
              label: 'THIX IA',
              backgroundColor: AppColors.goldBadge,
              iconColor: AppColors.bottomNavCenterIcon,
              labelColor: AppColors.darkText,
              onTap: onScanTap,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: _QuickActionItem(
              icon: Icons.nfc_rounded,
              label: 'NFC',
              backgroundColor: AppColors.goldBadge,
              iconColor: AppColors.bottomNavCenterIcon,
              labelColor: AppColors.darkText,
              onTap: onNfcTap,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: _QuickActionItem(
              icon: Icons.forum_rounded,
              label: 'THIX CHAT',
              backgroundColor: AppColors.goldBadge,
              iconColor: AppColors.bottomNavCenterIcon,
              labelColor: AppColors.darkText,
              onTap: onChatTap,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: _QuickActionItem(
              icon: Icons.emergency_rounded,
              label: 'URGENCE',
              backgroundColor: AppColors.dangerRed,
              iconColor: AppColors.white,
              labelColor: AppColors.dangerRed,
              onTap: onSecurityTap,
            ),
          ),
        ),
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

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
                color: labelColor,
              ),
              textAlign: TextAlign.center,
            ),
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

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

// ---- GRILLE DE SERVICES ----
class _ServicesGrid extends StatelessWidget {
  final SectionBadgeCounts counts;
  final Function(String) onServiceTap;

  const _ServicesGrid({
    required this.counts,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.m,
      crossAxisSpacing: AppSpacing.m,
      children: [
        _ServiceCard(icon: Icons.play_circle_filled, title: 'THIX Media', color: AppColors.domainMedia, onTap: () => onServiceTap('thixMedia')),
        _ServiceCard(icon: Icons.storefront_rounded, title: 'Market', color: AppColors.domainMarket, onTap: () => onServiceTap('thixMarket')),
        _ServiceCard(icon: Icons.school_rounded, title: 'Formations', color: AppColors.domainLearning, badge: counts.formations, onTap: () => onServiceTap('formations')),
        _ServiceCard(icon: Icons.work_rounded, title: 'Emplois', color: AppColors.domainJobs, badge: counts.jobs, onTap: () => onServiceTap('emplois')),
        _ServiceCard(icon: Icons.newspaper_rounded, title: 'THIX Info', color: AppColors.domainInfo, badge: counts.info, onTap: () => onServiceTap('thixInfo')),
        _ServiceCard(icon: Icons.lightbulb_rounded, title: 'Opportunités', color: AppColors.domainOpportunity, badge: counts.opportunities, onTap: () => onServiceTap('opportunites')),
        _ServiceCard(icon: Icons.event_rounded, title: 'Événements', color: AppColors.domainEvents, badge: counts.events, onTap: () => onServiceTap('evenements')),
        _ServiceCard(icon: Icons.people_rounded, title: 'Réseau Pro', color: AppColors.domainNetwork, onTap: () => onServiceTap('reseauPro')),
        _ServiceCard(icon: Icons.favorite_rounded, title: 'THIX Santé', color: AppColors.domainHealth, onTap: () => onServiceTap('thixSante')),
        _ServiceCard(icon: Icons.attach_money_rounded, title: 'THIX Money', color: AppColors.domainMoney, onTap: () => onServiceTap('thixMoney')),
        _ServiceCard(icon: Icons.domain_rounded, title: 'Services Gov', color: AppColors.domainGov, onTap: () => onServiceTap('servicesGov')),
        _ServiceCard(icon: Icons.calendar_today_rounded, title: 'Réservation', color: AppColors.domainReservation, onTap: () => onServiceTap('reservation')),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.serviceCard),
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
          boxShadow: AppShadows.secondary,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 6),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            if (badge > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- SECTION CAGE ----
class _SectionCage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCage({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: AppShadows.secondary,
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

// ---- SECTION PERSONNALISÉE ----
class _PersonalisedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
        boxShadow: AppShadows.secondary,
      ),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions pour vous',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightGrayBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(
              child: Text('Contenu personnalisé en cours de chargement...'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- BOTTOM NAVIGATION FLOTTANTE ----
class _FloatingBottomNav extends StatelessWidget {
  final VoidCallback onScanTap;

  const _FloatingBottomNav({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.bottomNavBlue,
        boxShadow: AppShadows.main,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Accueil', onTap: () {}),
          _NavItem(icon: Icons.explore_rounded, label: 'Explorer', onTap: () {}),
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.goldBadge,
                shape: BoxShape.circle,
                boxShadow: AppShadows.main,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.bottomNavCenterIcon, size: 26),
            ),
          ),
          _NavItem(icon: Icons.message_rounded, label: 'Messages', onTap: () {}),
          _NavItem(icon: Icons.person_rounded, label: 'Profil', onTap: () {}),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.bottomNavInactive, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.bottomNavInactive,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- ACCOUNT REQUEST SHEET ----
enum _AccountRequestChoice { personal, enterprise }

class AccountRequestSheet extends StatelessWidget {
  const AccountRequestSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.lg),
          topRight: Radius.circular(AppRadius.lg),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Type de compte',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _AccountRequestChoice.personal),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            ),
            child: const Text('Compte Personnel'),
          ),
          const SizedBox(height: AppSpacing.m),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _AccountRequestChoice.enterprise),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.premiumAccent,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
            ),
            child: const Text('Compte Entreprise'),
          ),
          const SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  }
}
