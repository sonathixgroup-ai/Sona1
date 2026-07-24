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

/// Singleton cache pour éviter de re-fetch le profil 7 fois
class DashboardCache {
  static final DashboardCache _i = DashboardCache._();
  DashboardCache._();
  factory DashboardCache() => _i;
  ThixProfile? lastProfile;
  DateTime? lastFetch;
  bool get isStale => lastFetch == null || DateTime.now().difference(lastFetch!).inMinutes > 5;
}

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});
  @override State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  late final UserService _userService;
  late final DocumentService _docs;
  late final ProfileService _profileService;
  final _docFilter = ValueNotifier<String>('Tous');
  StreamSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _userService = UserService(Supabase.instance.client);
    _docs = DocumentService();
    _profileService = ProfileService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthController>().currentUser;
      if (me == null) return;
      // Log non-bloquant
      unawaited(_userService.logSecurityEvent(uid: me.id, type: 'dashboard_open', label: 'Ouverture dashboard').catchError((_) {}));
      unawaited(_profileService.ensureProfileExists(user: me).catchError((_) {}));
    });
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _docFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    if (me == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // GUARD PROD - Jamais afficher perso à une entreprise
    if (me.accountType == AccountType.enterprise) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.enterpriseDashboard);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<ThixProfile?>(
      stream: _profileService.streamMyProfile(me.id).handleError((_) => DashboardCache().lastProfile),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && DashboardCache().lastProfile == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profile = snap.data?? DashboardCache().lastProfile?? ThixProfile.fallback(userId: me.id, thixId: me.thixId, displayName: me.displayName);
        if (snap.hasData) { DashboardCache().lastProfile = snap.data; DashboardCache().lastFetch = DateTime.now(); }

        // Merge une seule fois - pas dans chaque build de tab
        final mergedUser = me.copyWith(
          displayName: profile.displayName, photoUrl: profile.photoUrl, bio: profile.bio,
          countryOrOrigin: profile.countryOrOrigin, occupation: profile.occupation,
          thixChat: profile.thixChat, languages: profile.languages,
        );
        final score = me.thixScore?? _computeScore(me, profile);

        return DefaultTabController(
          length: 7,
          child: Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Stack(children: [
                const DashboardBackground(),
                Column(children: [
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
                        KeepAliveWrapper(child: ProfileTab(authUser: me, profile: profile, score: score, profileService: _profileService)),
                        KeepAliveWrapper(child: ValueListenableBuilder(valueListenable: _docFilter, builder: (_, filter, __) => DocumentsTab(uid: me.id, docs: _docs, userService: _userService, filter: filter, onChangeFilter: (v) => _docFilter.value = v))),
                        KeepAliveWrapper(child: ExperienceSkillsTab(profile: profile, profileService: _profileService)),
                        KeepAliveWrapper(child: FormationsTab(user: me, userService: _userService)),
                        KeepAliveWrapper(child: CvTab(user: mergedUser)),
                        KeepAliveWrapper(child: PaymentsTab(uid: me.id, userService: _userService, user: me)),
                        KeepAliveWrapper(child: SecurityTab(uid: me.id, user: me, userService: _userService)),
                      ],
                    ),
                  ),
                ]),
                Positioned(top: 18, right: 18, child: GestureDetector(onTap: () => context.push(AppRoutes.chat), child: const ChatFab())),
              ]),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => ThixIdentitySheets.showQrScanSheet(context),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF123B7A)),
              label: Text("Scanner ID", style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w900)),
              backgroundColor: LightModeColors.accent,
            ),
          ),
        );
      },
    );
  }

  int _computeScore(AppUser u, ThixProfile p) {
    var pts = 0;
    if (u.displayName.trim().isNotEmpty) pts += 10;
    if ((p.bio?? '').trim().length > 40) pts += 15;
    if ((p.occupation?? '').trim().isNotEmpty) pts += 10;
    if (p.education.isNotEmpty) pts += 20;
    if (p.experience.isNotEmpty) pts += 20;
    if (p.skills.isNotEmpty) pts += 15;
    if (p.languages.isNotEmpty) pts += 10;
    return pts.clamp(0, 100);
  }
}

// Garde les tabs vivants - évite re-fetch à chaque swipe (crucial à 1M users)
class KeepAliveWrapper extends StatefulWidget { final Widget child; const KeepAliveWrapper({super.key, required this.child}); @override State<KeepAliveWrapper> createState() => _KeepAliveWrapperState(); }
class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin { @override bool get wantKeepAlive => true; @override Widget build(BuildContext context) { super.build(context); return widget.child; } }
