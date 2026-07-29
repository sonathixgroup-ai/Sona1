// lib/presentation/dashboard/user_dashboard_page.dart

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

// =============================================================================
// STATE MANAGEMENT: CONTRÔLEUR HAUTE PERFORMANCE (SANS STREAM)
// =============================================================================

class DashboardCache {
  static final DashboardCache _i = DashboardCache._();
  DashboardCache._();
  factory DashboardCache() => _i;
  
  ThixProfile? lastProfile;
  DateTime? lastFetch;
  
  bool get isStale => lastFetch == null || DateTime.now().difference(lastFetch!).inMinutes > 5;
}

class UserDashboardCtrl extends ChangeNotifier {
  final ProfileService profileService;
  final UserService userService;
  final DocumentService docsService;

  bool loading = true;
  String? error;
  ThixProfile? profile;
  AppUser? mergedUser;
  int score = 0;

  UserDashboardCtrl({
    required this.profileService,
    required this.userService,
    required this.docsService,
  });

  Future<void> init(AppUser authUser) async {
    unawaited(userService.logSecurityEvent(uid: authUser.id, type: 'dashboard_open', label: 'Ouverture dashboard').catchError((_) {}));
    unawaited(profileService.ensureProfileExists(user: authUser).catchError((_) {}));

    if (!DashboardCache().isStale && DashboardCache().lastProfile != null) {
      profile = DashboardCache().lastProfile;
      _mergeAndCompute(authUser);
      loading = false;
      notifyListeners();
      unawaited(refreshSilently(authUser));
      return;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      profile = await profileService.fetchPublicProfileByUserId(authUser.id);
      profile ??= ThixProfile.fallback(userId: authUser.id, thixId: authUser.thixId, displayName: authUser.displayName);
      
      DashboardCache().lastProfile = profile;
      DashboardCache().lastFetch = DateTime.now();
      
      _mergeAndCompute(authUser);
    } catch (e) {
      error = 'Impossible de charger les données du profil.';
      debugPrint('UserDashboardCtrl init error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSilently(AppUser authUser) async {
    try {
      final freshProfile = await profileService.fetchPublicProfileByUserId(authUser.id);
      if (freshProfile != null) {
        profile = freshProfile;
        DashboardCache().lastProfile = freshProfile;
        DashboardCache().lastFetch = DateTime.now();
        _mergeAndCompute(authUser);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Silent refresh error: $e');
    }
  }

  void _mergeAndCompute(AppUser authUser) {
    if (profile == null) return;
    
    mergedUser = authUser.copyWith(
      displayName: profile!.displayName,
      photoUrl: profile!.photoUrl,
      bio: profile!.bio,
      countryOrOrigin: profile!.countryOrOrigin,
      occupation: profile!.occupation,
      profession: profile!.profession,
      thixChat: profile!.thixChat,
      languages: profile!.languages,
    );

    score = authUser.thixScore ?? _computeScore(authUser, profile!);
  }

  int _computeScore(AppUser u, ThixProfile p) {
    var pts = 0;
    if (u.displayName.trim().isNotEmpty) pts += 10;
    if ((p.bio ?? '').trim().length > 40) pts += 15;
    if ((p.occupation ?? '').trim().isNotEmpty) pts += 10;
    if (p.education.isNotEmpty) pts += 20;
    if (p.experience.isNotEmpty) pts += 20;
    if (p.skills.isNotEmpty) pts += 15;
    if (p.languages.isNotEmpty) pts += 10;
    return pts.clamp(0, 100);
  }
}

// =============================================================================
// INTERFACE UTILISATEUR (UI) - CLASSE RENOMMÉE
// =============================================================================

class ThixUserDashboardPage extends StatefulWidget {
  const ThixUserDashboardPage({super.key});
  @override 
  State<ThixUserDashboardPage> createState() => _ThixUserDashboardPageState();
}

class _ThixUserDashboardPageState extends State<ThixUserDashboardPage> {
  late final ProfileService _profileService;
  late final UserService _userService;
  late final DocumentService _docsService;
  late final UserDashboardCtrl _ctrl;
  
  final _docFilter = ValueNotifier<String>('Tous');

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _userService = UserService(Supabase.instance.client);
    _docsService = DocumentService();
    
    _ctrl = UserDashboardCtrl(
      profileService: _profileService,
      userService: _userService,
      docsService: _docsService,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = context.read<AuthController>().currentUser;
      if (me != null) {
        _ctrl.init(me);
      }
    });
  }

  @override
  void dispose() {
    _docFilter.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    if (me == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0D2CC1))));
    }

    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: DefaultTabController(
        length: 7,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Consumer<UserDashboardCtrl>(
            builder: (context, ctrl, _) {
              if (ctrl.loading && ctrl.profile == null) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF0D2CC1)));
              }

              if (ctrl.error != null && ctrl.profile == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ctrl.error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: () => ctrl.init(me), child: const Text('Réessayer'))
                    ],
                  ),
                );
              }

              final profile = ctrl.profile!;
              final mergedUser = ctrl.mergedUser!;
              final score = ctrl.score;

              return SafeArea(
                child: Stack(
                  children: [
                    const DashboardBackground(),
                    RefreshIndicator(
                      color: const Color(0xFF0D2CC1),
                      onRefresh: () => ctrl.refreshSilently(me),
                      child: Column(
                        children: [
                          DashboardTopBar(
                            user: mergedUser, 
                            score: score,
                            onBack: () => context.go(AppRoutes.home),
                            onOpenSettings: () => context.push(AppRoutes.settings),
                            onLogout: () async { 
                              await context.read<AuthController>().signOut(); 
                              if (context.mounted) context.go(AppRoutes.home); 
                            },
                            onEditProfile: () async {
                              await ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: me);
                              if (context.mounted) ctrl.refreshSilently(me);
                            },
                            onDownloadCv: () => DefaultTabController.of(context).animateTo(4),
                            onShareProfile: () => ShareProfileSheet.show(context, profile),
                          ),
                          const DashboardTabsHeader(),
                          Expanded(
                            child: TabBarView(
                              children: [
                                KeepAliveWrapper(child: ProfileTab(authUser: me, profile: profile, score: score, profileService: _profileService, userService: _userService)),
                                KeepAliveWrapper(child: ValueListenableBuilder(valueListenable: _docFilter, builder: (_, filter, __) => DocumentsTab(uid: me.id, docs: _docsService, userService: _userService, filter: filter, onChangeFilter: (v) => _docFilter.value = v))),
                                KeepAliveWrapper(child: ExperienceSkillsTab(profile: profile, profileService: _profileService)),
                                KeepAliveWrapper(child: FormationsTab(user: me, userService: _userService)),
                                KeepAliveWrapper(child: CvTab(user: mergedUser)),
                                KeepAliveWrapper(child: PaymentsTab(uid: me.id, userService: _userService, user: me)),
                                KeepAliveWrapper(child: SecurityTab(uid: me.id, user: me, userService: _userService)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 18, 
                      right: 18, 
                      child: GestureDetector(onTap: () => context.push(AppRoutes.chat), child: const ChatFab())
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => ThixIdentitySheets.showQrScanSheet(context),
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            label: Text(
              "Scanner ID", 
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)
            ),
            backgroundColor: const Color(0xFF0D2CC1),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET OPTIMISATION (CONSERVATION D'ÉTAT)
// =============================================================================

class KeepAliveWrapper extends StatefulWidget { 
  final Widget child; 
  const KeepAliveWrapper({super.key, required this.child}); 
  @override 
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState(); 
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin { 
  @override 
  bool get wantKeepAlive => true; 
  
  @override 
  Widget build(BuildContext context) { 
    super.build(context); 
    return widget.child; 
  } 
}
