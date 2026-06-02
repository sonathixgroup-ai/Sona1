import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
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

import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/l10n/locale_controller.dart';

/// Palette Ultra-Premium Institutionnelle - THIX ID 2026
class ThixPremiumColors {
  static const Color primaryDark = Color(0xFF0A1128);
  static const Color primaryElectric = Color(0xFF1C2541);
  static const Color accentBlue = Color(0xFF001F54);
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color goldDark = Color(0xFFAA7C11);
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color grayDark = Color(0xFF111827);
  static const Color grayMedium = Color(0xFF4B5563);
  static const Color grayLight = Color(0xFFE5E7EB);
}

enum _AccountRequestChoice { personal, enterprise }

// ==================== BOUTON D'OPTION POUR LA FEUILLE DE COMPTE ====================
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: ThixPremiumColors.grayLight),
          borderRadius: BorderRadius.circular(14),
          color: ThixPremiumColors.backgroundLight.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ThixPremiumColors.primaryDark.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: ThixPremiumColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ThixPremiumColors.primaryDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: ThixPremiumColors.grayMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: ThixPremiumColors.goldDark),
          ],
        ),
      ),
    );
  }
}

// ==================== FEUILLE DE DEMANDE DE COMPTE ====================
class AccountRequestSheet extends StatelessWidget {
  const AccountRequestSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ThixPremiumColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 35,
              height: 4,
              decoration: BoxDecoration(
                color: ThixPremiumColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ThixPremiumColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            _OptionButton(
              icon: Icons.person_outline,
              title: 'Compte Personnel',
              subtitle: 'Pour un profil individuel',
              onTap: () {
                Navigator.pop(context, _AccountRequestChoice.personal);
              },
            ),
            const SizedBox(height: 12),
            _OptionButton(
              icon: Icons.business_outlined,
              title: 'Compte Entreprise',
              subtitle: 'Pour une organisation',
              onTap: () {
                Navigator.pop(context, _AccountRequestChoice.enterprise);
              },
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ==================== PAGE PRINCIPALE ====================
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
      backgroundColor: ThixPremiumColors.backgroundLight,
      extendBody: true,
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
              physics: const NeverScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _PremiumHeader(
                    safeTop: safeTop,
                    onProfileTap: _onProfileTap,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Scanner un QR',
                            subtitle: 'Scannez en sécurité',
                            icon: Icons.qr_code_scanner_rounded,
                            backgroundColor: Colors.white,
                            iconColor: ThixPremiumColors.goldPrimary,
                            onTap: () {
                              ThixIdentitySheets.showQrScanSheet(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Lire via NFC',
                            subtitle: 'Approchez l\'appareil',
                            icon: Icons.fingerprint_rounded,
                            backgroundColor: Colors.white,
                            iconColor: ThixPremiumColors.primaryDark,
                            onTap: () {
                              ThixIdentitySheets.showNfcScanSheet(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _NotificationPreviewCard(
                      onTap: () {
                        if (!auth.isAuthenticated) {
                          context.push(AppRoutes.login);
                          return;
                        }
                        NotificationsSheet.show(context);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 0)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Thix services',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ThixPremiumColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Tout voir',
                            style: TextStyle(
                              color: ThixPremiumColors.goldDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: StreamBuilder<SectionBadgeCounts>(
                      stream: badgeCountsStream,
                      builder: (context, snap) {
                        final counts = snap.data ?? SectionBadgeCounts.zero;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                          childAspectRatio: 0.92,
                          children: [
                            _ServiceCard(
  icon: Icons.play_circle_filled,
  title: 'THIX MEDIA',
  iconBackgroundColor: Colors.blue.shade50,
  iconColor: Colors.blue,
  onTap: () => context.push(AppRoutes.thixMedia),
),
                            _ServiceCard(
  icon: Icons.storefront_rounded,
  title: 'THIX Market',
  iconBackgroundColor: const Color(0xFFFFF5E8),
  iconColor: const Color(0xFFFF9800),
  onTap: () => context.push(AppRoutes.thixMarket),
),

                            _ServiceCard(
                              icon: Icons.school_rounded,
                              title: 'Formations',
                              iconBackgroundColor: const Color(0xFFEAF3FF),
                              iconColor: const Color(0xFF0057D9),
                              badgeCount: counts.formations,
                              onTap: () => context.push(AppRoutes.trainingHome),
                            ),
                            _ServiceCard(
                              icon: Icons.work_rounded,
                              title: 'Emplois',
                              iconBackgroundColor: const Color(0xFFE9FFF2),
                              iconColor: const Color(0xFF00A86B),
                              badgeCount: counts.jobs,
                              onTap: () => context.push(AppRoutes.jobs),
                            ),
                            _ServiceCard(
                              icon: Icons.newspaper_rounded,
                              title: 'THIX INFO',
                              iconBackgroundColor: const Color(0xFFFFF3E6),
                              iconColor: const Color(0xFFFF9800),
                              badgeCount: counts.info,
                              onTap: () => AlertInfoSheet.show(context),
                            ),
                            _ServiceCard(
                              icon: Icons.lightbulb_rounded,
                              title: 'Opportunités',
                              iconBackgroundColor: const Color(0xFFFFF8E7),
                              iconColor: const Color(0xFFD4AF37),
                              onTap: () => context.push(AppRoutes.opportunities),
                            ),
                            _ServiceCard(
                              icon: Icons.event_rounded,
                              title: 'Événements',
                              iconBackgroundColor: const Color(0xFFFFEEF1),
                              iconColor: const Color(0xFFE63946),
                              badgeCount: counts.events,
                              onTap: () => context.push(AppRoutes.events),
                            ),
                            _ServiceCard(
                              icon: Icons.groups_rounded,
                              title: 'Réseau Pro',
                              iconBackgroundColor: const Color(0xFFEFF7FF),
                              iconColor: const Color(0xFF0077B6),
                              onTap: () => context.push(AppRoutes.network),
                            ),
                            _ServiceCard(
                              icon: Icons.local_hospital_rounded,
                              title: 'THIX Santé',
                              iconBackgroundColor: const Color(0xFFFFEEF1),
                              iconColor: const Color(0xFFE63946),
                              onTap: () => context.push(AppRoutes.thixSante),
                            ),
                            _ServiceCard(
                              icon: Icons.account_balance_wallet_rounded,
                              title: 'Thix Money',
                              iconBackgroundColor: const Color(0xFFE9FFF2),
                              iconColor: const Color(0xFF00A86B),
                              onTap: () => context.push(AppRoutes.thixMoney),
                            ),
                            _ServiceCard(
                              icon: Icons.account_balance_rounded,
                              title: 'Services Gov',
                              iconBackgroundColor: const Color(0xFFEAF3FF),
                              iconColor: const Color(0xFF0057D9),
                              onTap: () {},
                            ),
                            _ServiceCard(
                              icon: Icons.confirmation_number_rounded,
                              title: 'Réservation',
                              iconBackgroundColor: const Color(0xFFF8F1FF),
                              iconColor: const Color(0xFF9C27B0),
                              onTap: () => context.push(AppRoutes.reservation),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverToBoxAdapter(
                    child: _MissionBanner(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: (safeTop + 155 - _scrollOffset).clamp(safeTop + 8, safeTop + 155),
            left: 16,
            right: 16,
            child: Opacity(
              opacity: (1.0 - (_scrollOffset / 100)).clamp(0.0, 1.0),
              child: _SearchBarOverlay(
                controller: _searchController,
                isSearching: _searching,
                onVerify: _handleHomeSearchVerify,
              ),
            ),
          ),
          if (_searching)
            Positioned.fill(
              child: Container(
                color: ThixPremiumColors.primaryDark.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: ThixPremiumColors.goldPrimary,
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

// ==================== HEADER PREMIUM ====================
class _PremiumHeader extends StatelessWidget {
  final double safeTop;
  final VoidCallback onProfileTap;
  const _PremiumHeader({required this.safeTop, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.primaryElectric],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
        ),
        Positioned(
          right: -35,
          top: -15,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ThixPremiumColors.goldPrimary.withOpacity(0.04),
                width: 1,
              ),
            ),
          ),
        ),
        Positioned(
          right: -15,
          bottom: -5,
          child: Icon(
            Icons.fingerprint_rounded,
            size: 100,
            color: ThixPremiumColors.goldPrimary.withOpacity(0.03),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, safeTop + 4, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          gradient: const LinearGradient(
                            colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldLight],
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(1.1),
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: ThixPremiumColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Icon(
                              Icons.fingerprint_rounded,
                              color: ThixPremiumColors.goldPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'THIX ID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Identité Sécurisée.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ThixPremiumColors.goldPrimary.withOpacity(0.5),
                          width: 1,
                        ),
                        color: ThixPremiumColors.primaryDark,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: ThixPremiumColors.goldPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Bienvenue !',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Que voulez-vous faire aujourd’hui ?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== BARRE DE RECHERCHE ====================
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ThixPremiumColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ThixPremiumColors.grayLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: ThixPremiumColors.primaryDark.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Icon(Icons.search_rounded, color: ThixPremiumColors.grayMedium, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isSearching,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Rechercher un THIX ID...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
              style: const TextStyle(
                color: ThixPremiumColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.isSearching ? null : widget.onVerify,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Vérifier',
                    style: TextStyle(
                      color: ThixPremiumColors.primaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: ThixPremiumColors.primaryDark,
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CARTE ACTION RAPIDE ====================
class _QuickActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _controller.forward();
  void _onTapUp(_) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ThixPremiumColors.grayLight),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ThixPremiumColors.primaryDark.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ThixPremiumColors.primaryDark,
                      ),
                    ),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: ThixPremiumColors.grayMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CARTE APERÇU NOTIFICATIONS ====================
class _NotificationPreviewCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NotificationPreviewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ThixPremiumColors.grayLight),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThixPremiumColors.primaryDark.withOpacity(0.06),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: ThixPremiumColors.primaryDark,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ThixPremiumColors.primaryDark,
                    ),
                  ),
                  Text(
                    'Nouvelles mises à jour disponibles',
                    style: TextStyle(
                      fontSize: 11,
                      color: ThixPremiumColors.grayMedium,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: ThixPremiumColors.goldDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CARTE SERVICE ====================
class _ServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color iconBackgroundColor;
  final Color iconColor;
  final int? badgeCount;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.iconBackgroundColor,
    required this.iconColor,
    this.badgeCount,
    required this.onTap,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard>
    with SingleTickerProviderStateMixin {
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ThixPremiumColors.grayLight, width: 0.8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width:  24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.iconBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 18),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ThixPremiumColors.primaryDark,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.badgeCount != null && widget.badgeCount! > 0)
                Positioned(
                  top: -2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ThixPremiumColors.goldDark, ThixPremiumColors.goldPrimary],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.badgeCount}',
                      style: const TextStyle(
                        color: ThixPremiumColors.primaryDark,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
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

// ==================== BANNIÈRE MISSION ====================
class _MissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.accentBlue],
        ),
        border: Border.all(
          color: ThixPremiumColors.goldPrimary.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ThixPremiumColors.goldPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'NOTRE MISSION',
                    style: TextStyle(
                      color: ThixPremiumColors.goldLight,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Construisons l\'avenir de la jeunesse.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Accédez à des opportunités et un réseau engagé.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.shield_outlined,
            size: 50,
            color: ThixPremiumColors.goldPrimary.withOpacity(0.15),
          ),
        ],
      ),
    );
  }
}

// ==================== NAVIGATION BASSE FLOTTANTE ====================
class _FloatingBottomNav extends StatelessWidget {
  final VoidCallback onScanTap;
  const _FloatingBottomNav({required this.onScanTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: ThixPremiumColors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_filled, label: 'Accueil', active: true, onTap: () {}),
              _NavItem(icon: Icons.grid_view_rounded, label: 'Services', onTap: () {}),
              GestureDetector(
                onTap: onScanTap,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [ThixPremiumColors.primaryDark, ThixPremiumColors.accentBlue],
                    ),
                    border: Border.all(
                      color: ThixPremiumColors.goldPrimary.withOpacity(0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: ThixPremiumColors.goldPrimary,
                    size: 22,
                  ),
                ),
              ),
              _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', onTap: () {}),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', onTap: () {}),
            ],
          ),
        ),
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
            color: active ? ThixPremiumColors.primaryDark : ThixPremiumColors.grayMedium,
            size: 20,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: active ? ThixPremiumColors.primaryDark : ThixPremiumColors.grayMedium,
            ),
          ),
        ],
      ),
    );
  }
}
