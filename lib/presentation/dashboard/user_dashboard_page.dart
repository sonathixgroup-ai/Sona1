import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

// Services & Models
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/services/user_service.dart';
import '../../nav.dart';
import '../../theme.dart';
import '../common/thix_identity_sheets.dart';
import '../common/notifications_sheet.dart';

// Tes nouveaux composants extraits
import 'tabs/profile_tab.dart';
import 'tabs/documents_tab.dart';
import 'tabs/experience_skills_tab.dart';
import 'tabs/formations_tab.dart';
import 'tabs/cv_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/security_tab.dart';
import 'editors/profile_editor_sheet.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
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

  int _computeFallbackScore(AppUser u) {
    var points = 0;
    if (u.displayName.trim().isNotEmpty) points += 10;
    if ((u.bio ?? '').trim().isNotEmpty) points += 10;
    if ((u.occupation ?? '').trim().isNotEmpty) points += 10;
    if ((u.countryOrOrigin ?? '').trim().isNotEmpty) points += 8;
    if ((u.contactPhone ?? '').trim().isNotEmpty || (u.phone ?? '').trim().isNotEmpty) points += 8;
    if ((u.dateOfBirth ?? '').trim().isNotEmpty) points += 8;
    if ((u.nationality ?? '').trim().isNotEmpty) points += 8;
    if (u.education.isNotEmpty) points += 10;
    if (u.experience.isNotEmpty) points += 10;
    if (u.skills.isNotEmpty) points += 10;
    if (u.languages.isNotEmpty) points += 6;
    if (u.thixChat.trim().isNotEmpty) points += 8;
    return points.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    if (me == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text('Connexion requise', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white))),
      );
    }

    // Sécurité : redirection automatique pour les comptes Enterprise
    if (me.accountType == AccountType.enterprise) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go(AppRoutes.enterpriseDashboard);
      });
      return const SizedBox.shrink();
    }

    return StreamBuilder<ThixProfile?>(
      stream: _profileService.streamMyProfile(me.id),
      builder: (context, snap) {
        final profile = snap.data ?? ThixProfile.fallback(userId: me.id, thixId: me.thixId, displayName: me.displayName);
        final uid = me.id;
        final thixScore = me.thixScore ?? _computeFallbackScore(me);

        return DefaultTabController(
          length: 7,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              child: Stack(
                children: [
                  const _DashboardBackground(),
                  Column(
                    children: [
                      _DashboardTopBar(
                        // (Même logique qu'avant pour passer les propriétés)
                        user: me.copyWith(
                          displayName: profile.displayName,
                          photoUrl: profile.photoUrl,
                          bio: profile.bio,
                          countryOrOrigin: profile.countryOrOrigin,
                          occupation: profile.occupation,
                          thixChat: profile.thixChat,
                          languages: profile.languages,
                        ),
                        score: thixScore,
                        onBack: () => context.go(AppRoutes.home),
                        onOpenSettings: () => context.push(AppRoutes.settings),
                        onLogout: () async {
                          await context.read<AuthController>().signOut();
                          if (context.mounted) context.go(AppRoutes.home);
                        },
                        onEditProfile: () => ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: me),
                        onDownloadCv: () {
                          DefaultTabController.of(context).animateTo(4);
                        },
                        onShareProfile: () { /* Logique de modal de partage conservée ici ou extraite */ },
                      ),
                      
                      const _DashboardTabs(),
                      
                      // C'EST ICI QUE LA MAGIE OPÈRE : Les onglets sont maintenant appelés proprement
                      Expanded(
                        child: TabBarView(
                          children: [
                            ProfileTab(authUser: me, profile: profile, score: thixScore, profileService: _profileService, userService: _userService),
                            DocumentsTab(uid: uid, docs: _docs, userService: _userService, filter: _docFilter, onChangeFilter: (v) => setState(() => _docFilter = v)),
                            ExperienceSkillsTab(uid: uid, profile: profile, profileService: _profileService),
                            FormationsTab(uid: uid, user: me, userService: _userService),
                            CvTab(user: me.copyWith(/* fusion des données */)),
                            PaymentsTab(uid: uid, userService: _userService, user: me),
                            SecurityTab(uid: uid, user: me, userService: _userService),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 18,
                    right: 18,
                    child: GestureDetector(
                      onTap: () => context.push(AppRoutes.chat),
                      child: const _ChatFab(),
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => ThixIdentitySheets.showQrScanSheet(context),
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF123B7A)),
              label: Text("Scanner mon ID", style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF123B7A))),
              backgroundColor: LightModeColors.accent,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// CLASSES DE STRUCTURE SPÉCIFIQUES AU DASHBOARD (Conservées ici)
// ---------------------------------------------------------------------------

class _DashboardBackground extends StatelessWidget { /* ... */ }
class _DashboardTopBar extends StatelessWidget { /* ... */ }
class _HeaderIdentityCard extends StatelessWidget { /* ... */ }
class _DashboardTabs extends StatelessWidget { /* ... */ }
class _ChatFab extends StatelessWidget { /* ... */ }
// Et les autres petits widgets (_TopIconButton, _VerifiedPill, etc.) qui ne 
// sont utilisés QUE dans la top bar.
