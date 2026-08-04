// lib/presentation/dashboard/user_dashboard_page.dart

import 'dart:async';
import 'dart:ui';
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
// INTERFACE UTILISATEUR (UI) - DESIGN COMPACT ET MODERNE
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

    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: DefaultTabController(
        length: 7,
        child: Scaffold(
          backgroundColor: bgColor,
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

              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // En-tête Compact (Cover + Avatar + Infos + Actions alignées)
                          _buildCompactHeader(context, profile, mergedUser, score, me),
                          const SizedBox(height: 8),
                          // Header des Tabs
                          const DashboardTabsHeader(),
                        ],
                      ),
                    ),
                  ];
                },
                body: RefreshIndicator(
                  color: const Color(0xFF0D2CC1),
                  onRefresh: () => ctrl.refreshSilently(me),
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

  // --- En-tête Compact et Moderne (Style Facebook / Tout intégré) ---

  Widget _buildCompactHeader(BuildContext context, ThixProfile profile, AppUser me, int score, AppUser authUser) {
    const double coverHeight = 160.0;
    const double avatarRadius = 38.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Cover Photo avec dégradé et bouton de chargement de photo de couverture
        Container(
          height: coverHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1000&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassButton(Icons.arrow_back_rounded, () => context.go(AppRoutes.home)),
                    Row(
                      children: [
                        // Bouton d'édition fonctionnel
                        _buildGlassButton(Icons.edit_rounded, () async {
                          await ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: authUser);
                          if (context.mounted) _ctrl.refreshSilently(authUser);
                        }),
                        const SizedBox(width: 8),
                        // Bouton Chat aligné
                        _buildGlassButton(Icons.chat_bubble_outline_rounded, () => context.push(AppRoutes.chat)),
                        const SizedBox(width: 8),
                        // Bouton Paramètres / Déconnexion fonctionnel
                        _buildGlassButton(Icons.settings_rounded, () => context.push(AppRoutes.settings)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bouton de chargement de photo background (Couverture) positionné en bas à droite de la cover
        Positioned(
          top: coverHeight - 36,
          right: 16,
          child: GestureDetector(
            onTap: () async {
              // Action pour changer la photo de couverture
              await ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: authUser);
              if (context.mounted) _ctrl.refreshSilently(authUser);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text("Modifier couverture", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),

        // 2. Informations du Profil (Avatar superposé)
        Container(
          margin: EdgeInsets.only(top: coverHeight - 45),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar avec badge score
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: (me.photoUrl != null && me.photoUrl!.isNotEmpty) 
                              ? NetworkImage(me.photoUrl!) 
                              : null,
                          child: (me.photoUrl == null || me.photoUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 35, color: Colors.white)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Text(
                            '$score pts',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  me.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: Color(0xFF3B82F6)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (me.profession != null && me.profession!.isNotEmpty) ? me.profession! : "Membre Thix ID",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),

              // Bio compacte
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  (me.bio != null && me.bio!.isNotEmpty) ? me.bio! : "Aucune biographie pour le moment.",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Localisation
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    (me.countryOrOrigin != null && me.countryOrOrigin!.isNotEmpty) ? me.countryOrOrigin! : "Non spécifié",
                    style: TextStyle(fontSize: 11.5, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
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
