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
// INTERFACE UTILISATEUR (UI) - DESIGN MODERNE
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

              return Stack(
                children: [
                  // 1. COVER PHOTO (Background Image) - Dégradé vers le bas
                  Positioned(
                    top: 0, left: 0, right: 0,
                    height: 380,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          // Image par défaut si l'utilisateur n'a pas de cover
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
                              Colors.black.withValues(alpha: 0.15), // Assombrit légèrement le haut
                              Colors.transparent,
                              bgColor, // Se fond parfaitement avec le fond du Scaffold
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. CONTENU PRINCIPAL
                  SafeArea(
                    child: RefreshIndicator(
                      color: const Color(0xFF0D2CC1),
                      onRefresh: () => ctrl.refreshSilently(me),
                      child: Column(
                        children: [
                          // App Bar en Glassmorphism
                          _buildModernTopBar(context, profile, me),
                          
                          // Avatar et Informations Modernes
                          _buildModernProfileInfo(mergedUser, score),
                          
                          const SizedBox(height: 16),

                          // Header des Tabs (Original préservé)
                          const DashboardTabsHeader(),
                          
                          // Vues des Tabs
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
                  ),
                  
                  // Bouton Chat Flottant
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12, 
                    right: 80, 
                    child: GestureDetector(onTap: () => context.push(AppRoutes.chat), child: _buildGlassButton(Icons.chat_bubble_outline_rounded, () => context.push(AppRoutes.chat)))
                  ),
                ],
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

  // --- Composants UI Modernes ---

  Widget _buildModernTopBar(BuildContext context, ThixProfile profile, AppUser me) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildGlassButton(Icons.arrow_back_rounded, () => context.go(AppRoutes.home)),
          Row(
            children: [
              _buildGlassButton(Icons.edit_rounded, () async {
                await ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: me);
                if (context.mounted) _ctrl.refreshSilently(me);
              }),
              const SizedBox(width: 12),
              _buildGlassButton(Icons.settings_rounded, () => context.push(AppRoutes.settings)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGlassButton(IconData icon, VoidCallback onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildModernProfileInfo(AppUser user, int score) {
    final bioText = (user.bio != null && user.bio!.isNotEmpty) ? user.bio! : "Complétez votre biographie...";
    final locationText = (user.countryOrOrigin != null && user.countryOrOrigin!.isNotEmpty) ? user.countryOrOrigin! : "Localisation inconnue";
    
    return Column(
      children: [
        const SizedBox(height: 20),
        // Avatar avec bordure et badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF3B82F6), // Bordure bleue façon image de référence
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty) 
                    ? NetworkImage(user.photoUrl!) 
                    : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            // Petit badge (Score)
            Positioned(
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '$score pts',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Nom propre et élégant
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.public, size: 16, color: Color(0xFF3B82F6)), // Icône globe
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Petite Bio avec Emoji
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            "🌙 $bioText",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Informations secondaires (Localisation, Profession)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              locationText,
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Icon(Icons.work_outline_rounded, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(
              (user.profession != null && user.profession!.isNotEmpty) ? user.profession! : "Profession",
              style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
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
