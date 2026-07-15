import 'dart:async';
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
import 'package:thix_id/presentation/emergency/emergency_overlay.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/notification_service.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/services/thix_id_service.dart';

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

// ============================================================================
// PAGE PRINCIPALE – HOMEPAGE STYLE FACEBOOK
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
  final PageController _headlinesController = PageController();

  final _notifications = NotificationService();
  final _counters = NotificationCountersService();
  final _profileService = ProfileService();

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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _headlinesController.dispose();
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
    final isThix = normalized.startsWith('THIX-');
    final isUid = _uidLikeRegex.hasMatch(raw);

    if (!isThix && !isUid) {
      await FullScreenMessage.showError(
        context,
        title: 'Identifiant invalide',
        message: 'Format THIX ID ou identifiant unique incorrect.',
      );
      return;
    }

    setState(() => _searching = true);

    try {
      ThixProfile? profile;

      if (isThix) {
        profile = await _profileService.fetchPublicProfileByThixId(normalized);
      } else {
        profile = await _profileService.fetchPublicProfileByUserId(raw);
      }

      if (!mounted) return;

      if (profile == null) {
        await FullScreenMessage.showError(
          context,
          title: 'Profil introuvable',
          message: "Aucune identité THIX active correspondante trouvée.",
        );
        return;
      }

      final thix = profile.thixId.trim().toUpperCase();

      if (thix.isNotEmpty) {
        context.push('${AppRoutes.publicProfile}?thixId=$thix');
      } else {
        await ThixIdentitySheets.showVerifySheet(
          context,
          initialUidOrThixId: profile.userId,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await FullScreenMessage.showError(
        context,
        title: 'Erreur',
        message: "Impossible d'effectuer la vérification de l'identifiant.",
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
      context.go(AppRoutes.userDashboard);
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

  Future<void> _openThixChat() async {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      context.push(AppRoutes.chat);
    } else {
      context.push(AppRoutes.login);
    }
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

  // ✅ Nouveau : NFC remplacé par Document -> ouvre le coffre-fort documents.
  void _openDocumentVault() {
    final auth = context.read<AuthController>();
    if (auth.isAuthenticated) {
      context.push(AppRoutes.vault);
    } else {
      context.push(AppRoutes.login);
    }
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
            : 'Bonjour';
    // ✅ Photo réelle de l'utilisateur (même source que le Dashboard).
    final photoUrl = auth.currentUser?.photoUrl;
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
                  photoUrl: photoUrl,
                  isAuthenticated: auth.isAuthenticated,
                  onProfileTap: _onProfileTap,
                  onAccountRequest: () => _handleRequestAccount(context),
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
                    uid: auth.currentUser?.id,
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
                    onDocumentTap: _openDocumentVault, // ✅ remplace NFC
                    onChatTap: _openThixChat,
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
                                context.push('/thix-event');
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
                              case 'monPays':
                                context.push(AppRoutes.monPays);
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

              // ✅ Espace supplémentaire pour ne pas cacher le contenu
              // derrière le bouton flottant (plus de bottomNavigationBar fixe).
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl + 130)),
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
          // ✅ Bouton flottant unique (QR scan + menu extensible).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ExpandableNavFab(
              onScanTap: () => ThixIdentitySheets.showQrScanSheet(context),
              onHomeTap: () => context.go(AppRoutes.home),
              onMiniAppsTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mini Apps — bientôt disponible.')),
                );
              },
              onDocumentsTap: _openDocumentVault,
              onProfileTap: _onProfileTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double safeTop;
  final String displayName;
  final String? photoUrl;
  final bool isAuthenticated;
  final VoidCallback onProfileTap;
  final VoidCallback onAccountRequest;

  _PinnedHeaderDelegate({
    required this.safeTop,
    required this.displayName,
    required this.photoUrl,
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
        photoUrl: photoUrl,
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
        photoUrl != oldDelegate.photoUrl ||
        isAuthenticated != oldDelegate.isAuthenticated;
  }
}

// ============================================================================
// COMPOSANTS
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

class _PremiumHeader extends StatelessWidget {
  final double safeTop;
  final String displayName;
  final String? photoUrl;
  final bool isAuthenticated;
  final VoidCallback onProfileTap;
  final VoidCallback onAccountRequest;

  const _PremiumHeader({
    required this.safeTop,
    required this.displayName,
    required this.photoUrl,
    required this.isAuthenticated,
    required this.onProfileTap,
    required this.onAccountRequest,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedPhoto = (photoUrl ?? '').trim();
    return Padding(
      // ✅ Le menu "3 barres" a été retiré.
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, safeTop + 10, AppSpacing.xl, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                    image: DecorationImage(
                      image: trimmedPhoto.isNotEmpty
                          ? NetworkImage(trimmedPhoto) as ImageProvider
                          : const AssetImage(
                              'assets/images/African_businessman_in_suit_grayscale_1775573970767.jpg',
                            ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
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

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onDocumentTap; // ✅ remplace onNfcTap
  final VoidCallback onChatTap;
  final VoidCallback onSecurityTap;

  const _QuickActionsRow({
    required this.onScanTap,
    required this.onDocumentTap,
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
              icon: Icons.folder_shared_rounded,
              label: 'Document',
              backgroundColor: AppColors.goldBadge,
              iconColor: AppColors.bottomNavCenterIcon,
              labelColor: AppColors.darkText,
              onTap: onDocumentTap, // ✅ ouvre le vault
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

class _ServicesGrid extends StatelessWidget {
  final SectionBadgeCounts counts;
  final Function(String) onServiceTap;

  const _ServicesGrid({
    required this.counts,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    final services = [
      {'key': 'thixMedia', 'icon': Icons.play_circle_filled, 'title': 'THIX MEDIA', 'color': AppColors.domainMedia},
      {'key': 'thixMarket', 'icon': Icons.storefront_rounded, 'title': 'THIX Market', 'color': AppColors.domainMarket},
      {'key': 'formations', 'icon': Icons.school_rounded, 'title': 'Formations', 'color': AppColors.domainLearning, 'badge': counts.formations},
      {'key': 'emplois', 'icon': Icons.work_rounded, 'title': 'Emplois', 'color': AppColors.domainJobs, 'badge': counts.jobs},
      {'key': 'thixInfo', 'icon': Icons.newspaper_rounded, 'title': 'THIX INFO', 'color': AppColors.domainInfo, 'badge': counts.info},
      {'key': 'opportunites', 'icon': Icons.lightbulb_rounded, 'title': 'Opportunités', 'color': AppColors.domainOpportunity},
      {'key': 'evenements', 'icon': Icons.event_rounded, 'title': 'Événements', 'color': AppColors.domainEvents, 'badge': counts.events},
      {'key': 'reseauPro', 'icon': Icons.groups_rounded, 'title': 'Réseau Pro', 'color': AppColors.domainNetwork},
      {'key': 'thixSante', 'icon': Icons.local_hospital_rounded, 'title': 'THIX Santé', 'color': AppColors.domainHealth},
      {'key': 'thixMoney', 'icon': Icons.account_balance_wallet_rounded, 'title': 'Thix Money', 'color': AppColors.domainMoney},
      {'key': 'monPays', 'icon': Icons.flag, 'title': 'Mon Pays', 'color': AppColors.domainGov},
      {'key': 'reservation', 'icon': Icons.confirmation_number_rounded, 'title': 'Réservation', 'color': AppColors.domainReservation},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.02,
      ),
      itemCount: services.length,
      itemBuilder: (ctx, index) {
        final service = services[index];
        final badge = service['badge'] as int?;
        return _ServiceCard(
          icon: service['icon'] as IconData,
          title: service['title'] as String,
          color: service['color'] as Color,
          badgeCount: badge,
          onTap: () => onServiceTap(service['key'] as String),
        );
      },
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;
  final int? badgeCount;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.color,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.badgeCount != null && widget.badgeCount! > 0)
                  Positioned(
                    top: -8,
                    right: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.badgeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCage extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        border: Border.all(color: AppColors.cardBorder, width: 0.6),
        boxShadow: AppShadows.secondary,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.grid_view_rounded, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// CAROUSEL "À LA UNE" — connecté (THIX Info + Opportunity + Notification prioritaire)
// ============================================================================

class _HeadlinesCarousel extends StatefulWidget {
  final PageController controller;
  final String? uid;
  final VoidCallback onThixInfoTap;
  final VoidCallback onOpportunityTap;

  const _HeadlinesCarousel({
    required this.controller,
    required this.uid,
    required this.onThixInfoTap,
    required this.onOpportunityTap,
  });

  @override
  State<_HeadlinesCarousel> createState() => _HeadlinesCarouselState();
}

class _HeadlinesCarouselState extends State<_HeadlinesCarousel> {
  late final Stream<List<Map<String, dynamic>>> _articlesStream;
  late final Stream<List<Map<String, dynamic>>> _opportunitiesStream;
  Stream<List<Map<String, dynamic>>>? _priorityNotifStream;
  Timer? _autoTimer;
  int _cardCount = 0;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;

    // NOTE: adapte les noms de table/colonnes ci-dessous si ton schéma
    // Supabase utilise des noms différents (ex: 'articles' au lieu de
    // 'thix_info_articles', 'featured' au lieu de 'is_featured', etc.)
    try {
      _articlesStream = client
          .from('thix_info_articles')
          .stream(primaryKey: ['id'])
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(5);
    } catch (_) {
      _articlesStream = Stream.value(const <Map<String, dynamic>>[]);
    }

    try {
      _opportunitiesStream = client
          .from('opportunities')
          .stream(primaryKey: ['id'])
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(5);
    } catch (_) {
      _opportunitiesStream = Stream.value(const <Map<String, dynamic>>[]);
    }

    final uid = widget.uid;
    if (uid != null && uid.trim().isNotEmpty) {
      try {
        _priorityNotifStream = client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(5);
      } catch (_) {
        _priorityNotifStream = null;
      }
    }

    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!widget.controller.hasClients || _cardCount <= 1) return;
      final current = widget.controller.page?.round() ?? 0;
      final next = (current + 1) % _cardCount;
      widget.controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _priorityNotifStream,
      builder: (context, notifSnap) {
        final notifs = (notifSnap.data ?? const <Map<String, dynamic>>[])
            .where((n) => (n['priority'] == true) || (n['is_priority'] == true))
            .toList(growable: false);
        final priorityNotif = notifs.isEmpty ? null : notifs.first;

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _articlesStream,
          builder: (context, articleSnap) {
            final articles = articleSnap.data ?? const <Map<String, dynamic>>[];

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _opportunitiesStream,
              builder: (context, oppSnap) {
                final opportunities = oppSnap.data ?? const <Map<String, dynamic>>[];

                final cards = <Widget>[];

                // ✅ Priorité : une notification (si elle existe) passe en 1ère carte.
                if (priorityNotif != null) {
                  cards.add(
                    _HeadlineCard(
                      label: 'Notification prioritaire',
                      title: (priorityNotif['title'] as String?) ??
                          (priorityNotif['message'] as String?) ??
                          'Nouvelle notification',
                      imageUrl: priorityNotif['image_url'] as String?,
                      icon: Icons.priority_high_rounded,
                      accent: AppColors.dangerRed,
                      onTap: () => NotificationsSheet.show(context),
                    ),
                  );
                }

                for (final a in articles) {
                  cards.add(
                    _HeadlineCard(
                      label: 'À la une • THIX Info',
                      title: (a['title'] as String?) ?? 'Actualité THIX Info',
                      imageUrl: a['image_url'] as String?,
                      icon: Icons.newspaper_rounded,
                      accent: AppColors.domainInfo,
                      onTap: widget.onThixInfoTap,
                    ),
                  );
                }

                for (final o in opportunities) {
                  cards.add(
                    _HeadlineCard(
                      label: 'À la une • Opportunity',
                      title: (o['title'] as String?) ?? 'Nouvelle opportunité',
                      imageUrl: o['image_url'] as String?,
                      icon: Icons.lightbulb_rounded,
                      accent: AppColors.domainOpportunity,
                      onTap: widget.onOpportunityTap,
                    ),
                  );
                }

                if (cards.isEmpty) {
                  cards.addAll([
                    _HeadlineCard(
                      label: 'À la une • THIX Info',
                      title: 'Nouvelles, annonces et mises à jour',
                      icon: Icons.newspaper_rounded,
                      accent: AppColors.domainInfo,
                      onTap: widget.onThixInfoTap,
                    ),
                    _HeadlineCard(
                      label: 'À la une • Opportunity',
                      title: 'Opportunités pro à saisir maintenant',
                      icon: Icons.lightbulb_rounded,
                      accent: AppColors.domainOpportunity,
                      onTap: widget.onOpportunityTap,
                    ),
                  ]);
                }

                _cardCount = cards.length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 104,
                      child: PageView(controller: widget.controller, children: cards),
                    ),
                    if (cards.length > 1) ...[
                      const SizedBox(height: 8),
                      _CarouselDots(controller: widget.controller, count: cards.length),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CarouselDots extends StatefulWidget {
  final PageController controller;
  final int count;

  const _CarouselDots({required this.controller, required this.count});

  @override
  State<_CarouselDots> createState() => _CarouselDotsState();
}

class _CarouselDotsState extends State<_CarouselDots> {
  int _page = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!widget.controller.hasClients) return;
    final p = widget.controller.page?.round() ?? 0;
    if (p != _page && mounted) setState(() => _page = p);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePage = widget.count == 0 ? 0 : _page.clamp(0, widget.count - 1);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.count, (i) {
        final active = i == activePage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.premiumAccent : AppColors.cardBorder,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _HeadlineCard extends StatelessWidget {
  final String label;
  final String title;
  final IconData icon;
  final Color accent;
  final String? imageUrl;
  final VoidCallback onTap;

  const _HeadlineCard({
    required this.label,
    required this.title,
    required this.icon,
    required this.accent,
    this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.mainCard),
          border: Border.all(color: AppColors.cardBorder, width: 0.6),
          boxShadow: AppShadows.main,
        ),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                image: hasImage
                    ? DecorationImage(image: NetworkImage(imageUrl!.trim()), fit: BoxFit.cover)
                    : null,
              ),
              child: hasImage ? null : Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _PersonalisedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      _MiniRoundAction(icon: Icons.account_balance_wallet_rounded, label: 'Top Up'),
      _MiniRoundAction(icon: Icons.shopping_cart_rounded, label: 'Buy'),
      _MiniRoundAction(icon: Icons.shield_rounded, label: 'Secure'),
      _MiniRoundAction(icon: Icons.local_atm_rounded, label: 'Cash out'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personnalisé pour vous',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            for (final item in items)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: item,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MiniRoundAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniRoundAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.cardBorder, width: 0.5),
              boxShadow: AppShadows.secondary,
            ),
            child: Icon(icon, size: 20, color: AppColors.darkText),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOUTON FLOTTANT UNIQUE — QR SCAN + MENU EXTENSIBLE (remplace l'ancienne bottom bar)
// ============================================================================

class _NavSatelliteData {
  final IconData icon;
  final String label;
  const _NavSatelliteData({required this.icon, required this.label});
}

class _ExpandableNavFab extends StatefulWidget {
  final VoidCallback onScanTap;
  final VoidCallback onHomeTap;
  final VoidCallback onMiniAppsTap;
  final VoidCallback onDocumentsTap;
  final VoidCallback onProfileTap;

  const _ExpandableNavFab({
    required this.onScanTap,
    required this.onHomeTap,
    required this.onMiniAppsTap,
    required this.onDocumentsTap,
    required this.onProfileTap,
  });

  @override
  State<_ExpandableNavFab> createState() => _ExpandableNavFabState();
}

class _ExpandableNavFabState extends State<_ExpandableNavFab> {
  bool _expanded = false;
  Timer? _collapseTimer;

  static const double _centralBottom = 14;
  static const double _centralSize = 60;
  static const double _satSize = 46;
  static const double _satGap = 12;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _armAutoCollapse() {
    _collapseTimer?.cancel();
    // ✅ Repli automatique après 10 secondes d'inactivité.
    _collapseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _expanded = false);
    });
  }

  void _expand() {
    HapticFeedback.mediumImpact();
    setState(() => _expanded = true);
    _armAutoCollapse();
  }

  void _collapse() {
    _collapseTimer?.cancel();
    if (mounted) setState(() => _expanded = false);
  }

  void _runSatellite(VoidCallback action) {
    _collapse();
    action();
  }

  void _handleCentralTap() {
    if (_expanded) {
      // Le bouton central sert aussi à refermer le menu.
      _collapse();
    } else {
      // ✅ Fonctionne directement comme scanner QR.
      widget.onScanTap();
    }
  }

  void _handleCentralLongPress() {
    if (_expanded) {
      _armAutoCollapse();
    } else {
      _expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    final items = <_NavSatelliteData>[
      const _NavSatelliteData(icon: Icons.home_filled, label: 'Home'),
      const _NavSatelliteData(icon: Icons.apps_rounded, label: 'Mini Apps'),
      const _NavSatelliteData(icon: Icons.folder_rounded, label: 'Documents'),
      const _NavSatelliteData(icon: Icons.person_outline_rounded, label: 'Profil'),
    ];
    final actions = <VoidCallback>[
      widget.onHomeTap,
      widget.onMiniAppsTap,
      widget.onDocumentsTap,
      widget.onProfileTap,
    ];

    final totalHeight = _centralBottom +
        _centralSize +
        (items.length * (_satSize + _satGap)) +
        bottomSafe +
        30;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavSatellite(
              visible: _expanded,
              bottomOffset:
                  bottomSafe + _centralBottom + _centralSize + _satGap + i * (_satSize + _satGap),
              order: i,
              icon: items[i].icon,
              label: items[i].label,
              onTap: () => _runSatellite(actions[i]),
            ),
          Positioned(
            bottom: bottomSafe + _centralBottom,
            child: GestureDetector(
              onTap: _handleCentralTap,
              onLongPress: _handleCentralLongPress,
              child: AnimatedRotation(
                turns: _expanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  width: _centralSize,
                  height: _centralSize,
                  decoration: BoxDecoration(
                    color: AppColors.goldBadge,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    _expanded ? Icons.close_rounded : Icons.qr_code_scanner_rounded,
                    color: AppColors.bottomNavCenterIcon,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSatellite extends StatelessWidget {
  final bool visible;
  final double bottomOffset;
  final int order;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavSatellite({
    required this.visible,
    required this.bottomOffset,
    required this.order,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: Duration(milliseconds: 200 + order * 40),
      curve: Curves.easeOutBack,
      bottom: visible ? bottomOffset : bottomOffset - 24,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Duration(milliseconds: 160 + order * 40),
        child: IgnorePointer(
          ignoring: !visible,
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardBorder, width: 0.6),
                    boxShadow: AppShadows.main,
                  ),
                  child: Icon(icon, color: AppColors.premiumAccent, size: 20),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkNavy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
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

// ============================================================================
// FEUILLE DE DEMANDE DE COMPTE
// ============================================================================

enum _AccountRequestChoice { personal, enterprise }

class AccountRequestSheet extends StatelessWidget {
  const AccountRequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _OptionButton(
              icon: Icons.person_outline,
              title: 'Compte Personnel',
              subtitle: 'Pour un profil individuel',
              onTap: () {
                Navigator.pop(context, _AccountRequestChoice.personal);
              },
            ),
            const SizedBox(height: AppSpacing.m),
            _OptionButton(
              icon: Icons.business_outlined,
              title: 'Compte Entreprise',
              subtitle: 'Pour une organisation',
              onTap: () {
                Navigator.pop(context, _AccountRequestChoice.enterprise);
              },
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
          color: AppColors.lightGrayBg,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.darkText.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.darkText, size: 20),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
