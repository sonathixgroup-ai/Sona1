import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/nav.dart';
import 'package:thix_id/presentation/common/full_screen_message.dart';
import 'package:thix_id/presentation/common/alert_info_sheet.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import 'package:thix_id/services/firestore_user_service.dart';
import 'package:thix_id/services/notification_service.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/services/thix_id_service.dart';

// ============================================================================
// CONSTANTES DE DESIGN – INSPIRÉ DE "MIXX" (FINTECH PREMIUM)
// ============================================================================

class AppColors {
  static const Color primaryBlue = Color(0xFF003BFF);
  static const Color darkNavy = Color(0xFF02134F);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrayBg = Color(0xFFF5F6FA);
  static const Color textSecondary = Color(0xFF7B8190);
  static const Color cardBorder = Color(0xFFE9ECF3);
  static const Color goldBadge = Color(0xFFF7C948);
  static const Color successGreen = Color(0xFF1BC47D);
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color darkText = Color(0xFF1A1A2E);
  static const Color shadowLight = Color(0x0F000000); // avec opacité 0.06
  static const Color shadowSecondary = Color(0x0A000000); // 0.04
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
// PAGE PRINCIPALE – HOMEPAGE PREMIUM (STYLE MIXX)
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
  double _scrollOffset = 0;

  final _notifications = NotificationService();
  final _counters = NotificationCountersService();

  static final RegExp _uidLikeRegex = RegExp(r'^[A-Za-z0-9_-]{20,}$');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
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
      final userService = FirestoreUserService();
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
    final badgeCountsStream = auth.currentUser == null
        ? Stream.value(SectionBadgeCounts.zero)
        : _counters.streamCounts(auth.currentUser!.id);

    return Scaffold(
      backgroundColor: AppColors.lightGrayBg,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _scrollOffset = notification.metrics.pixels;
                });
              }
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _PremiumHeader(
                    safeTop: safeTop,
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

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),

                // Carte Premium Status (style mixx)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _PremiumStatusCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),

                // Carte THIX Pass
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _ThixPassCard(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),

                // Actions rapides (4 boutons)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _QuickActionsRow(
                      onScanTap: () => ThixIdentitySheets.showQrScanSheet(context),
                      onNfcTap: () => ThixIdentitySheets.showNfcScanSheet(context),
                      onDocumentsTap: () {},
                      onSecurityTap: () {},
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),

                // Grille des services (4x3)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  sliver: SliverToBoxAdapter(
                    child: StreamBuilder<SectionBadgeCounts>(
                      stream: badgeCountsStream,
                      builder: (context, snap) {
                        final counts = snap.data ?? SectionBadgeCounts.zero;
                        return _ServicesGrid(
                          counts: counts,
                          onServiceTap: (serviceKey) {
                            // Gestion des onTap pour chaque service
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
                                AlertInfoSheet.show(context);
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
                                // TODO: à implémenter
                                break;
                              case 'reservation':
                                context.push(AppRoutes.reservation);
                                break;
                              default:
                                break;
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.l)),

                // Bannière promotionnelle
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: _PromoBanner(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl + 20)),
              ],
            ),
          ),
          if (_searching)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
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

// ============================================================================
// COMPOSANTS (STYLE MIXX)
// ============================================================================

// ---- HEADER ----
class _PremiumHeader extends StatelessWidget {
  final double safeTop;
  final VoidCallback onProfileTap;
  final VoidCallback onAccountRequest;

  const _PremiumHeader({
    required this.safeTop,
    required this.onProfileTap,
    required this.onAccountRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, safeTop + AppSpacing.s, AppSpacing.xl, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkNavy, AppColors.darkNavy],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hamburger + Titre
              Row(
                children: [
                  const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  const Text(
                    'THIX ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              // Notifications + Avatar
              Row(
                children: [
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.dangerRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.l),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
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
          const SizedBox(height: AppSpacing.m),
          const Text(
            'Bonjour Nathan 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          const Text(
            'Votre identité numérique, votre pouvoir.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
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
          colors: [AppColors.darkNavy, AppColors.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        boxShadow: AppShadows.main,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.l),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: AppColors.goldBadge, size: 28),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Membre Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Score de confiance : 98%',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
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

// ---- CARTE THIX PASS ----
class _ThixPassCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        boxShadow: AppShadows.secondary,
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          // Partie gauche : info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Text(
                      'THIX PASS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: AppColors.successGreen, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Vérifié',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'ID: THIX-1234-5678',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Text(
                  'Exp: 31/12/2026',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text(
                    'Voir le pass',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.l),
          // QR Code
          Expanded(
            flex: 1,
            child: Container(
              height: 120,
              width: 120,
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.qrContainer),
                border: Border.all(color: AppColors.cardBorder, width: 0.5),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: 100,
                  color: AppColors.darkText.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- ACTIONS RAPIDES (4 boutons) ----
class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onScanTap;
  final VoidCallback onNfcTap;
  final VoidCallback onDocumentsTap;
  final VoidCallback onSecurityTap;

  const _QuickActionsRow({
    required this.onScanTap,
    required this.onNfcTap,
    required this.onDocumentsTap,
    required this.onSecurityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _QuickActionItem(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scanner QR',
          onTap: onScanTap,
        ),
        _QuickActionItem(
          icon: Icons.nfc_rounded,
          label: 'NFC',
          onTap: onNfcTap,
        ),
        _QuickActionItem(
          icon: Icons.folder_rounded,
          label: 'Documents',
          onTap: onDocumentsTap,
        ),
        _QuickActionItem(
          icon: Icons.shield_rounded,
          label: 'Sécurité',
          onTap: onSecurityTap,
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.serviceCard),
          boxShadow: AppShadows.secondary,
          border: Border.all(color: AppColors.cardBorder, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.primaryBlue),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- GRILLE DE SERVICES (4x3) ----
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
      {'key': 'thixMedia', 'icon': Icons.play_circle_filled, 'title': 'THIX MEDIA', 'color': AppColors.primaryBlue},
      {'key': 'thixMarket', 'icon': Icons.storefront_rounded, 'title': 'THIX Market', 'color': AppColors.primaryBlue},
      {'key': 'formations', 'icon': Icons.school_rounded, 'title': 'Formations', 'color': AppColors.primaryBlue, 'badge': counts.formations},
      {'key': 'emplois', 'icon': Icons.work_rounded, 'title': 'Emplois', 'color': AppColors.successGreen, 'badge': counts.jobs},
      {'key': 'thixInfo', 'icon': Icons.newspaper_rounded, 'title': 'THIX INFO', 'color': AppColors.primaryBlue, 'badge': counts.info},
      {'key': 'opportunites', 'icon': Icons.lightbulb_rounded, 'title': 'Opportunités', 'color': AppColors.goldBadge},
      {'key': 'evenements', 'icon': Icons.event_rounded, 'title': 'Événements', 'color': AppColors.dangerRed, 'badge': counts.events},
      {'key': 'reseauPro', 'icon': Icons.groups_rounded, 'title': 'Réseau Pro', 'color': AppColors.primaryBlue},
      {'key': 'thixSante', 'icon': Icons.local_hospital_rounded, 'title': 'THIX Santé', 'color': AppColors.dangerRed},
      {'key': 'thixMoney', 'icon': Icons.account_balance_wallet_rounded, 'title': 'Thix Money', 'color': AppColors.successGreen},
      {'key': 'servicesGov', 'icon': Icons.account_balance_rounded, 'title': 'Services Gov', 'color': AppColors.primaryBlue},
      {'key': 'reservation', 'icon': Icons.confirmation_number_rounded, 'title': 'Réservation', 'color': AppColors.primaryBlue},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
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
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            boxShadow: AppShadows.secondary,
            border: Border.all(color: AppColors.cardBorder, width: 0.5),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Positioned(
                  top: 4,
                  right: 4,
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
        ),
      ),
    );
  }
}

// ---- BANNIÈRE PROMO ----
class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.darkNavy, AppColors.primaryBlue],
        ),
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        boxShadow: AppShadows.main,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Équipez-vous',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'Rejoignez le programme THIX ELITE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  child: const Center(
                    child: Text(
                      'En savoir plus',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.l),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.phone_iphone_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- BOTTOM NAVIGATION (FLOATING IN CURVED) ----
class _FloatingBottomNav extends StatelessWidget {
  final VoidCallback onScanTap;

  const _FloatingBottomNav({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.bottomNav),
        boxShadow: AppShadows.main,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_filled, label: 'Accueil', active: true, onTap: () {}),
          _NavItem(icon: Icons.grid_view_rounded, label: 'Services', onTap: () {}),
          // Bouton central
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.darkNavy],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', onTap: () {}),
          _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', onTap: () {}),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? AppColors.primaryBlue : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.primaryBlue : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FEUILLE DE DEMANDE DE COMPTE (inchangée)
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
                color: AppColors.darkText.withOpacity(0.06),
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
