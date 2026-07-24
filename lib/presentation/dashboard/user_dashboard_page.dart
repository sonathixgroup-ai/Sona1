import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import '../../nav.dart';
import '../../theme.dart';
import 'dashboard_ui.dart';
import 'dashboard_tabs.dart';
import 'dashboard_editors.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});
  @override State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final _userService = UserService(Supabase.instance.client);
  final _docs = DocumentService();
  final _profileService = ProfileService();
  String _docFilter = 'Tous';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthController>().currentUser;
      if (me != null) {
        unawaited(_userService.logSecurityEvent(uid: me.id, type: 'dashboard_open', label: 'Ouverture du dashboard'));
        unawaited(_profileService.ensureProfileExists(user: me));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    if (me == null) return const Scaffold(body: Center(child: Text('Connexion requise')));
    if (me.accountType == AccountType.enterprise) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go(AppRoutes.enterpriseDashboard));
      return const SizedBox.shrink();
    }

    return StreamBuilder<ThixProfile?>(
      stream: _profileService.streamMyProfile(me.id),
      builder: (context, snap) {
        final profile = snap.data ?? ThixProfile.fallback(userId: me.id, thixId: me.thixId, displayName: me.displayName);
        final mergedUser = me.copyWith(
          displayName: profile.displayName, photoUrl: profile.photoUrl, bio: profile.bio,
          countryOrOrigin: profile.countryOrOrigin, occupation: profile.occupation,
          thixChat: profile.thixChat, languages: profile.languages,
        );
        final score = me.thixScore ?? _computeScore(me);

        return DefaultTabController(
          length: 7,
          child: Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  const DashboardBackground(),
                  Column(
                    children: [
                      DashboardTopBar(
                        user: mergedUser, score: score,
                        onBack: () => context.go(AppRoutes.home),
                        onOpenSettings: () => context.push(AppRoutes.settings),
                        onLogout: () async { await context.read<AuthController>().signOut(); if(context.mounted) context.go(AppRoutes.home); },
                        onEditProfile: () => ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: me),
                        onDownloadCv: () => DefaultTabController.of(context).animateTo(4),
                        onShareProfile: () => ShareProfileSheet.show(context, profile),
                      ),
                      const DashboardTabsHeader(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ProfileTab(authUser: me, profile: profile, score: score, profileService: _profileService, userService: _userService),
                            DocumentsTab(uid: me.id, docs: _docs, userService: _userService, filter: _docFilter, onChangeFilter: (v) => setState(()=> _docFilter = v)),
                            ExperienceSkillsTab(profile: profile, profileService: _profileService),
                            FormationsTab(user: me, userService: _userService),
                            CvTab(user: mergedUser),
                            PaymentsTab(uid: me.id, userService: _userService, user: me),
                            SecurityTab(uid: me.id, user: me, userService: _userService),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(top: 18, right: 18, child: GestureDetector(onTap: () => context.push(AppRoutes.chat), child: const ChatFab())),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => ThixIdentitySheets.showQrScanSheet(context),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF123B7A)),
              label: Text("Scanner mon ID", style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF123B7A))),
              backgroundColor: LightModeColors.accent,
            ),
          ),
        );
      },
    );
  }

  int _computeScore(AppUser u) {
    var p=0;
    if(u.displayName.trim().isNotEmpty) p+=10;
    if((u.bio??'').trim().isNotEmpty) p+=10;
    if((u.occupation??'').trim().isNotEmpty) p+=10;
    if(u.education.isNotEmpty) p+=20;
    if(u.experience.isNotEmpty) p+=20;
    if(u.skills.isNotEmpty) p+=10;
    if(u.languages.isNotEmpty) p+=10;
    return p.clamp(0,100);
  }
}
