import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/presentation/common/parcours_form.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import 'package:thix_id/presentation/common/trainings_editor_sheet.dart';
import 'package:thix_id/presentation/common/upload_document_preview.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/firestore_user_service.dart';
import 'package:thix_id/services/profile_service.dart';
import '../../theme.dart';
import '../../nav.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final profileService = context.watch<ProfileService>();
    final firestoreService = context.watch<FirestoreUserService>();

    return Scaffold(
      body: StreamBuilder<AppUser>(
        stream: authController.currentUserStream,
        builder: (context, authSnap) {
          if (!authSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final authUser = authSnap.data!;
          return StreamBuilder<ThixProfile?>(
            stream: profileService.streamMyProfile(authUser.id),
            builder: (context, profileSnap) {
              final profile = profileSnap.data ?? ThixProfile.empty(userId: authUser.id);

              return Stack(
                children: [
                  const _DashboardBackground(),
                  SafeArea(
                    child: Column(
                      children: [
                        _DashboardTopBar(
                          user: authUser,
                          profile: profile,
                          onBack: () => context.pop(),
                          onOpenSettings: () => context.push(AppRoutes.settings),
                          onLogout: () async {
                            await authController.signOut();
                            if (mounted) context.go(AppRoutes.home);
                          },
                          onEditProfile: () => _ProfileEditorSheet.show(
                            context,
                            profile: profile,
                            profileService: profileService,
                            authUser: authUser,
                          ),
                          onDownloadCv: () => _downloadCV(context, profile),
                          onShareProfile: () => _shareProfile(context, profile),
                        ),
                        _DashboardTabs(
                          currentTab: _currentTab,
                          onTabChanged: (i) => setState(() => _currentTab = i),
                        ),
                        Expanded(
                          child: _buildCurrentTab(
                            context,
                            _currentTab,
                            authUser,
                            profile,
                            profileService,
                            firestoreService,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentTab(
    BuildContext context,
    int tab,
    AppUser authUser,
    ThixProfile profile,
    ProfileService profileService,
    FirestoreUserService firestoreService,
  ) {
    switch (tab) {
      case 0: // Profil
        return _ProfileTab(authUser: authUser, profile: profile, profileService: profileService);
      case 1: // Documents
        return const Center(child: Text("📄 Documents - À implémenter"));
      case 2: // Expériences
        return const Center(child: Text("💼 Expériences - À implémenter"));
      case 3: // Formations
        return const Center(child: Text("🎓 Formations - À implémenter"));
      case 4: // CV
        return const Center(child: Text("📋 CV Numérique - À implémenter"));
      case 5: // Paiements
        return const Center(child: Text("💰 Paiements - À implémenter"));
      case 6: // Sécurité
        return const Center(child: Text("🔒 Sécurité - À implémenter"));
      default:
        return const SizedBox();
    }
  }

  Future<void> _downloadCV(BuildContext context, ThixProfile profile) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du CV PDF en cours...')),
    );
  }

  Future<void> _shareProfile(BuildContext context, ThixProfile profile) async {
    await Share.share('Découvrez mon THIX ID : \( {profile.thixId}\nhttps://thixid.com/ \){profile.thixId}');
  }
}

// ==================== BACKGROUND & TOP BAR ====================

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.35,
          colors: [Color(0xFF0F2B4A), Color(0xFF0A2F5C)],
        ),
      ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  final AppUser user;
  final ThixProfile profile;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onLogout;
  final VoidCallback onEditProfile;
  final VoidCallback onDownloadCv;
  final VoidCallback onShareProfile;

  const _DashboardTopBar({
    super.key,
    required this.user,
    required this.profile,
    required this.onBack,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onEditProfile,
    required this.onDownloadCv,
    required this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    final verified = (user.registrationStatus ?? '').toLowerCase() == 'verified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D62), Color(0xFF0F2B4A)],
        ),
      ),
      child: Column(
        children: [
          // Top Navigation
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: onBack),
              const Spacer(),
              Text('THIX ID', style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.notifications_rounded, color: Colors.white), onPressed: () => NotificationsSheet.show(context)),
              IconButton(icon: const Icon(Icons.settings_rounded, color: Colors.white), onPressed: onOpenSettings),
              IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: onLogout),
            ],
          ),
          const SizedBox(height: 12),
          _HeaderIdentityCard(
            user: user,
            profile: profile,
            verified: verified,
            onEditProfile: onEditProfile,
            onDownloadCv: onDownloadCv,
            onShareProfile: onShareProfile,
          ),
        ],
      ),
    );
  }
}

// ==================== TABS ====================

class _DashboardTabs extends StatelessWidget {
  final int currentTab;
  final Function(int) onTabChanged;

  const _DashboardTabs({super.key, required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A2F5C),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TabBar(
        isScrollable: true,
        onTap: onTabChanged,
        labelColor: LightModeColors.accent,
        unselectedLabelColor: Colors.white70,
        indicator: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
        ),
        tabs: const [
          Tab(text: 'Profil'),
          Tab(text: 'Docs'),
          Tab(text: 'Exp'),
          Tab(text: 'Formations'),
          Tab(text: 'CV'),
          Tab(text: 'Paiements'),
          Tab(text: 'Sécurité'),
        ],
      ),
    );
  }
}

// ==================== PROFILE TAB (Principal) ====================

class _ProfileTab extends StatelessWidget {
  final AppUser authUser;
  final ThixProfile profile;
  final ProfileService profileService;

  const _ProfileTab({
    super.key,
    required this.authUser,
    required this.profile,
    required this.profileService,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ... Tu peux remettre ici les DashboardCard que tu veux garder

          const SizedBox(height: 20),
          Text("Politique de confidentialité & Conditions d'utilisation",
              style: context.textStyles.bodySmall?.copyWith(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ==================== PROFILE EDITOR SHEET (Corrigé) ====================

class _ProfileEditorSheet extends StatelessWidget {
  static void show(BuildContext context, {required ThixProfile profile, required ProfileService profileService, required AppUser authUser}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditorSheet(profile: profile, profileService: profileService, authUser: authUser),
    );
  }

  final ThixProfile profile;
  final ProfileService profileService;
  final AppUser authUser;

  const _ProfileEditorSheet({super.key, required this.profile, required this.profileService, required this.authUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: const Center(child: Text("Éditeur de Profil - Version simplifiée")),
    );
  }
}
