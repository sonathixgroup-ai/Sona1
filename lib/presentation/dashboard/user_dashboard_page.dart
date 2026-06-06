import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:thix_id/auth/auth_controller.dart';
import 'package:thix_id/models/app_user.dart';
import 'package:thix_id/presentation/common/parcours_form.dart';
import 'package:thix_id/presentation/common/date_picker_field.dart';
import 'package:thix_id/presentation/common/trainings_editor_sheet.dart';
import 'package:thix_id/presentation/common/thix_identity_sheets.dart';
import 'package:thix_id/presentation/common/notifications_sheet.dart';
import 'package:thix_id/presentation/common/upload_document_preview.dart';
import 'package:thix_id/services/document_service.dart';
import 'package:thix_id/services/verification_status.dart';
import 'package:thix_id/services/profile_photo_service.dart';
import 'package:thix_id/services/firestore_user_service.dart';
import 'package:thix_id/services/profile_service.dart';
import 'package:thix_id/models/thix_profile.dart';
import 'package:thix_id/services/platform_file_from_path_stub.dart'
    if (dart.library.io) 'package:thix_id/services/platform_file_from_path_io.dart';
import '../../theme.dart';
import '../../nav.dart';

// ============================================================================
// Classes utilitaires
// ============================================================================

class EvidenceFileRef {
  final String storagePathOrUrl;
  final String? label;

  const EvidenceFileRef({required this.storagePathOrUrl, this.label});

  Map<String, dynamic> toJson() => {'storagePathOrUrl': storagePathOrUrl, 'label': label};

  static EvidenceFileRef? tryParse(dynamic data) {
    if (data is Map) {
      final path = (data['storagePathOrUrl'] ?? data['storage_path'] ?? '').toString();
      if (path.isEmpty) return null;
      return EvidenceFileRef(storagePathOrUrl: path, label: (data['label'] ?? '').toString());
    }
    return null;
  }
}

class EducationEntryControllers {
  final TextEditingController institutionC = TextEditingController();
  final TextEditingController degreeC = TextEditingController();
  final TextEditingController levelC = TextEditingController();
  final TextEditingController cityC = TextEditingController();
  final TextEditingController startYearC = TextEditingController();
  final TextEditingController endYearC = TextEditingController();

  void dispose() {
    institutionC.dispose();
    degreeC.dispose();
    levelC.dispose();
    cityC.dispose();
    startYearC.dispose();
    endYearC.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'institution': institutionC.text.trim(),
      'degree': degreeC.text.trim(),
      'level': levelC.text.trim(),
      'city': cityC.text.trim(),
      'startYear': startYearC.text.trim(),
      'endYear': endYearC.text.trim(),
    };
  }

  static EducationEntryControllers fromMap(Map<String, dynamic> map) {
    final c = EducationEntryControllers();
    c.institutionC.text = (map['institution'] ?? '').toString();
    c.degreeC.text = (map['degree'] ?? '').toString();
    c.levelC.text = (map['level'] ?? '').toString();
    c.cityC.text = (map['city'] ?? '').toString();
    c.startYearC.text = (map['startYear'] ?? '').toString();
    c.endYearC.text = (map['endYear'] ?? '').toString();
    return c;
  }
}

class ExperienceEntryControllers {
  final TextEditingController titleC = TextEditingController();
  final TextEditingController companyC = TextEditingController();
  final TextEditingController cityC = TextEditingController();
  final TextEditingController missionsC = TextEditingController();

  void dispose() {
    titleC.dispose();
    companyC.dispose();
    cityC.dispose();
    missionsC.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'title': titleC.text.trim(),
      'company': companyC.text.trim(),
      'city': cityC.text.trim(),
      'missions': missionsC.text.trim(),
    };
  }

  static ExperienceEntryControllers fromMap(Map<String, dynamic> map) {
    final c = ExperienceEntryControllers();
    c.titleC.text = (map['title'] ?? '').toString();
    c.companyC.text = (map['company'] ?? '').toString();
    c.cityC.text = (map['city'] ?? '').toString();
    c.missionsC.text = (map['missions'] ?? '').toString();
    return c;
  }
}

// ============================================================================
// SectionHeader
// ============================================================================

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool showAction;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel = "Action",
    this.showAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: context.textStyles.bodySmall?.copyWith(
                  color: LightModeColors.secondaryText,
                ),
              ),
            ],
          ),
          if (showAction)
            TextButton(
              onPressed: () {},
              child: Text(
                actionLabel,
                style: context.textStyles.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const DashboardProfileStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: context.textStyles.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: LightModeColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: LightModeColors.secondaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: LightModeColors.hint, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color textColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(color: textColor),
      ),
    );
  }
}

class DocRow extends StatelessWidget {
  final String name;
  final String date;
  final String status;
  final Color statusBg;
  final Color statusText;

  const DocRow({
    super.key,
    required this.name,
    required this.date,
    required this.status,
    required this.statusBg,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.insert_drive_file_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  date,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: LightModeColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(label: status, bg: statusBg, textColor: statusText),
        ],
      ),
    );
  }
}

class DashboardInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const DashboardInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, height: 1.35),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class ActivationCalloutCard extends StatelessWidget {
  final VoidCallback onActivate;
  const ActivationCalloutCard({super.key, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: LightModeColors.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [LightModeColors.accent, Color(0xFFE5B13A)]),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.verified_rounded, color: Color(0xFF0A2F5C)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Compte en attente d\'activation', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      'Vos informations sont bien enregistrées. Activez maintenant pour obtenir votre THIX ID officiel.',
                      style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onActivate,
              icon: const Icon(Icons.payments_rounded, color: Color(0xFF0A2F5C)),
              label: const Text('Activer mon compte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LightModeColors.accent,
                foregroundColor: const Color(0xFF0A2F5C),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UserDashboardPage
// ============================================================================

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final _userService = FirestoreUserService();
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
        body: const Center(child: Text('Connexion requise')),
      );
    }

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
        final thixScore = me.thixScore ?? _computeFallbackScore(me);
        final uid = me.id;

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
                        user: me,
                        score: thixScore,
                        onBack: () => context.popOrGo(AppRoutes.home),
                        onOpenSettings: () => context.push(AppRoutes.settings),
                        onLogout: () async {
                          await context.read<AuthController>().signOut();
                          if (context.mounted) context.go(AppRoutes.home);
                        },
                        onEditProfile: () => _ProfileEditorSheet.show(context, profile: profile, profileService: _profileService, authUser: me),
                        onDownloadCv: () {
                          DefaultTabController.of(context).animateTo(4);
                        },
                        onShareProfile: () async {
                          await _shareProfile(context, profile);
                        },
                      ),
                      _DashboardTabs(),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _ProfileTab(
                              authUser: me,
                              profile: profile,
                              score: thixScore,
                              profileService: _profileService,
                              firestoreUserService: _userService,
                            ),
                            _DocumentsTab(
                              uid: uid,
                              docs: _docs,
                              userService: _userService,
                              filter: _docFilter,
                              onChangeFilter: (v) => setState(() => _docFilter = v),
                            ),
                            _ExperienceSkillsTab(uid: uid, profile: profile, profileService: _profileService),
                            _FormationsTab(uid: uid, user: me, userService: _userService),
                            _CvTab(user: me),
                            _PaymentsTab(uid: uid, userService: _userService, user: me),
                            _SecurityTab(uid: uid, user: me, userService: _userService),
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
              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF0A2F5C)),
              label: Text("Scanner mon ID", style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF0A2F5C))),
              backgroundColor: LightModeColors.accent,
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareProfile(BuildContext context, ThixProfile profile) async {
    final thixId = profile.thixId.trim();
    final url = thixId.isEmpty ? '' : 'https://thix.app/public-profile?thixId=${Uri.encodeComponent(thixId)}';
    final text = url.isEmpty ? 'Mon profil THIX ID: $thixId' : 'Mon profil THIX ID: $thixId\n$url';
    try {
      await Share.share(text);
    } catch (e) {
      debugPrint('Share profile failed err=$e');
    }
  }
}

// ============================================================================
// Dashboard Background
// ============================================================================

class _DashboardBackground extends StatelessWidget {
  const _DashboardBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(center: Alignment.center, radius: 1.35, colors: [Color(0xFF0F2B4A), Color(0xFF0A2F5C)]),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Opacity(opacity: 0.028, child: Icon(Icons.fingerprint_rounded, size: 650, color: Theme.of(context).colorScheme.onPrimary)),
        ),
      ],
    );
  }
}

// ============================================================================
// Dashboard Top Bar
// ============================================================================

class _DashboardTopBar extends StatelessWidget {
  final AppUser user;
  final int score;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onLogout;
  final VoidCallback onEditProfile;
  final VoidCallback onDownloadCv;
  final VoidCallback onShareProfile;

  const _DashboardTopBar({
    required this.user,
    required this.score,
    required this.onBack,
    required this.onOpenSettings,
    required this.onLogout,
    required this.onEditProfile,
    required this.onDownloadCv,
    required this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A3D62), Color(0xFF0F2B4A)]),
      ),
      child: Stack(
        children: [
          Positioned(right: -40, top: 12, child: Opacity(opacity: 0.08, child: Icon(Icons.star_rounded, size: 220, color: Colors.white))),
          Positioned(right: 40, bottom: -60, child: Opacity(opacity: 0.06, child: Icon(Icons.star_rounded, size: 260, color: Colors.white))),
          Column(
            children: [
              Row(
                children: [
                  _TopIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                  const Spacer(),
                  Text('THIX ID', style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
                  const Spacer(),
                  _TopIconButton(icon: Icons.notifications_rounded, onTap: () => NotificationsSheet.show(context)),
                  const SizedBox(width: AppSpacing.sm),
                  _TopIconButton(icon: Icons.settings_rounded, onTap: onOpenSettings),
                  const SizedBox(width: AppSpacing.sm),
                  _TopIconButton(icon: Icons.logout_rounded, onTap: () async => onLogout()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _HeaderIdentityCard(
                user: user,
                score: score,
                onEditProfile: onEditProfile,
                onDownloadCv: onDownloadCv,
                onShareProfile: onShareProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap),
    );
  }
}

class _HeaderIdentityCard extends StatelessWidget {
  final AppUser user;
  final int score;
  final VoidCallback onEditProfile;
  final VoidCallback onDownloadCv;
  final VoidCallback onShareProfile;

  const _HeaderIdentityCard({
    required this.user,
    required this.score,
    required this.onEditProfile,
    required this.onDownloadCv,
    required this.onShareProfile,
  });

  @override
  Widget build(BuildContext context) {
    final status = (user.registrationStatus ?? '—').toLowerCase();
    final verified = status == 'paid' || status == 'verified';
    final photoUrl = (user.photoUrl ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: LightModeColors.accent.withValues(alpha: 0.85), width: 3),
                      color: Colors.white.withValues(alpha: 0.10),
                      image: DecorationImage(
                        image: photoUrl.isEmpty ? const AssetImage('assets/images/African_businessman_in_suit_grayscale_1775573970767.jpg') : NetworkImage(photoUrl) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(color: verified ? LightModeColors.success : LightModeColors.accent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F2B4A), width: 3)),
                      alignment: Alignment.center,
                      child: Icon(verified ? Icons.check_rounded : Icons.hourglass_bottom_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: Text(user.thixId, style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        _VerifiedPill(verified: verified, label: verified ? 'Identité Vérifiée' : 'En attente'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (user.bio ?? '').trim().isEmpty ? 'Complétez votre profil pour renforcer votre identité.' : user.bio!.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.86), height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _HeaderActionButton(icon: Icons.edit_rounded, label: 'Modifier Profil', onTap: onEditProfile)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _HeaderActionButton(icon: Icons.download_rounded, label: 'CV Numérique', onTap: onDownloadCv)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _HeaderActionButton(icon: Icons.ios_share_rounded, label: 'Partager', onTap: onShareProfile)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScorePill(score: score),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        ),
      ),
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  final bool verified;
  final String label;
  const _VerifiedPill({required this.verified, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(verified ? Icons.verified_rounded : Icons.hourglass_bottom_rounded, size: 12, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10)),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0, 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [LightModeColors.accent, Color(0xFFE5B13A)]),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights_rounded, color: Color(0xFF0A2F5C), size: 16),
          const SizedBox(width: 6),
          Text('THIX Score: $clamped/100', style: context.textStyles.labelSmall?.copyWith(color: const Color(0xFF0A2F5C), fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ============================================================================
// Dashboard Tabs
// ============================================================================

class _DashboardTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0F2B4A), Color(0xFF0A2F5C)])),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const TabBar(
          isScrollable: true,
          labelColor: LightModeColors.accent,
          unselectedLabelColor: Colors.white70,
          indicator: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.zero),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(icon: Icon(Icons.person_rounded), text: 'Profil'),
            Tab(icon: Icon(Icons.folder_rounded), text: 'Documents'),
            Tab(icon: Icon(Icons.work_rounded), text: 'Expériences'),
            Tab(icon: Icon(Icons.school_rounded), text: 'Formations'),
            Tab(icon: Icon(Icons.description_rounded), text: 'CV'),
            Tab(icon: Icon(Icons.payments_rounded), text: 'Paiements'),
            Tab(icon: Icon(Icons.security_rounded), text: 'Sécurité'),
          ],
        ),
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  const _ChatFab();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [LightModeColors.accent, Color(0xFFE5B13A)]),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 12))],
        border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.forum_rounded, size: 26, color: Color(0xFF0A2F5C)),
    );
  }
}

class _TabScaffold extends StatelessWidget {
  final List<Widget> children;
  const _TabScaffold({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

// ============================================================================
// Profile Tab
// ============================================================================

class _ProfileTab extends StatelessWidget {
  final AppUser authUser;
  final ThixProfile profile;
  final int score;
  final ProfileService profileService;
  final FirestoreUserService firestoreUserService;

  const _ProfileTab({
    required this.authUser,
    required this.profile,
    required this.score,
    required this.profileService,
    required this.firestoreUserService,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 960;
    final user = profile;
    final isActivated = authUser.thixId.trim().toUpperCase() != 'THIX-PENDING';
    final hasActiveTrial = authUser.hasActiveTrial;

    final left = <Widget>[
      if (!isActivated && !hasActiveTrial)
        ActivationCalloutCard(
          onActivate: () {
            final receiptReturn = Uri.encodeComponent(AppRoutes.activationReceipt);
            context.go('${AppRoutes.payment}?returnTo=$receiptReturn');
          },
        ),
      DashboardCard(
        icon: Icons.badge_rounded,
        title: 'Profil Professionnel',
        subtitle: 'Données sécurisées liées à votre THIX ID',
        child: Column(
          children: [
            DashboardInfoRow(label: 'THIX ID', value: user.thixId),
            DashboardInfoRow(label: 'UID', value: authUser.id),
            DashboardInfoRow(label: 'Email', value: authUser.email.isEmpty ? '—' : authUser.email),
            DashboardInfoRow(label: 'Téléphone', value: authUser.phone ?? '—'),
            DashboardInfoRow(label: 'Contact', value: authUser.contactPhone ?? '—'),
            DashboardInfoRow(label: 'Profession / Poste', value: user.occupation?.trim().isEmpty ?? true ? '—' : user.occupation!.trim()),
            DashboardInfoRow(label: 'Localisation', value: user.countryOrOrigin?.trim().isEmpty ?? true ? '—' : user.countryOrOrigin!.trim()),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _ExpandableTextRow(label: 'Bio', text: user.bio ?? '—')),
                const SizedBox(width: AppSpacing.sm),
                _VisibilityToggle(
                  label: 'Public',
                  value: user.visibility.bio,
                  onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(bio: v)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(child: _LanguagesRow(languages: user.languages)),
                const SizedBox(width: AppSpacing.sm),
                _VisibilityToggle(
                  label: 'Public',
                  value: true,
                  onChanged: null,
                  tooltip: 'Les langues sont toujours publiques dans cette version.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthController>().signOut();
                    if (context.mounted) context.go(AppRoutes.home);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Déconnexion'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _ProfileEditorSheet.show(context, profile: user, profileService: profileService, authUser: authUser),
                  icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onPrimary),
                  label: const Text('Modifier Profil'),
                  style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: Theme.of(context).colorScheme.onPrimary, elevation: 0),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      DashboardCard(
        icon: Icons.account_circle_rounded,
        title: 'Identité civile',
        subtitle: 'Informations sensibles (strictement protégées)',
        child: Column(
          children: [
            DashboardInfoRow(label: 'Date de naissance', value: authUser.dateOfBirth ?? '—'),
            DashboardInfoRow(label: 'Lieu de naissance', value: authUser.placeOfBirth ?? '—'),
            DashboardInfoRow(label: 'Nationalité', value: authUser.nationality ?? '—'),
            DashboardInfoRow(label: 'État civil', value: authUser.maritalStatus ?? '—'),
            DashboardInfoRow(label: 'Adresse', value: authUser.address ?? '—'),
            DashboardInfoRow(label: 'Père', value: authUser.fatherName ?? '—'),
            DashboardInfoRow(label: 'Mère', value: authUser.motherName ?? '—'),
            DashboardInfoRow(
              label: "Contact d'urgence",
              value: [authUser.emergencyContactName, authUser.emergencyContactRelation, authUser.emergencyContactPhone].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).join(' • ').isEmpty
                  ? '—'
                  : [authUser.emergencyContactName, authUser.emergencyContactRelation, authUser.emergencyContactPhone].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim()).join(' • '),
            ),
          ],
        ),
      ),
    ];

    final right = <Widget>[
      DashboardCard(
        icon: Icons.school_rounded,
        title: 'Cursus scolaire',
        subtitle: '${user.education.length} entrée(s)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.education.isEmpty)
              Text('Aucune formation enregistrée.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
            else
              ...user.education.take(3).map((e) {
                final inst = (e['institution'] as String?) ?? (e['school'] as String?) ?? (e['org'] as String?) ?? '—';
                final degree = (e['degree'] as String?) ?? (e['title'] as String?) ?? '';
                final city = (e['city'] as String?) ?? '';
                final start = (e['startYear'] as String?) ?? '';
                final end = (e['endYear'] as String?) ?? '';
                final period = [start, end].where((v) => v.trim().isNotEmpty).join('–');
                final meta = [degree, city, period].where((v) => v.trim().isNotEmpty).join(' • ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.school_rounded, color: LightModeColors.secondaryText),
                  title: Text(inst, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                  subtitle: meta.isEmpty ? null : Text(meta, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                );
              }),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => TrainingsEditorSheet.show(context, profile: user, profileService: profileService),
                icon: const Icon(Icons.school_rounded, color: Color(0xFF0A2F5C)),
                label: const Text('Ajouter une formation'),
                style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      DashboardCard(
        icon: Icons.work_history_rounded,
        title: 'Expérience professionnelle',
        subtitle: '${user.experience.length} entrée(s)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.experience.isEmpty)
              Text('Aucune expérience enregistrée.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
            else
              ...user.experience.take(3).map((e) {
                final title = (e['title'] as String?) ?? (e['role'] as String?) ?? '—';
                final company = (e['company'] as String?) ?? (e['org'] as String?) ?? '';
                final city = (e['city'] as String?) ?? '';
                final sector = (e['sector'] as String?) ?? '';
                final meta = [company, city, sector].where((v) => v.trim().isNotEmpty).join(' • ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.work_rounded, color: LightModeColors.secondaryText),
                  title: Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                  subtitle: meta.isEmpty ? null : Text(meta, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                );
              }),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: _VisibilityToggle(
                label: 'Public',
                value: user.visibility.experience,
                onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(experience: v)),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      DashboardCard(
        icon: Icons.insights_rounded,
        title: 'Indice de confiance',
        subtitle: 'THIX Score + conformité de profil',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('THIX Score: $score/100', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: (score.clamp(0, 100)) / 100.0,
                backgroundColor: Colors.black.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(LightModeColors.accent),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Text('Complétez Bio, Compétences, Formations et Documents pour améliorer votre score.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35)),
          ],
        ),
      ),
    ];

    if (!isWide) return _TabScaffold(children: [...left, const SizedBox(height: AppSpacing.md), ...right]);
    return _TabScaffold(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: Column(children: right)),
          ],
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? tooltip;
  const _VisibilityToggle({required this.label, required this.value, required this.onChanged, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: context.textStyles.labelSmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w900)),
        const SizedBox(width: 8),
        Switch(value: value, onChanged: onChanged, activeColor: LightModeColors.success),
      ],
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

class _ExpandableTextRow extends StatefulWidget {
  final String label;
  final String text;
  const _ExpandableTextRow({required this.label, required this.text});

  @override
  State<_ExpandableTextRow> createState() => _ExpandableTextRowState();
}

class _LanguagesRow extends StatelessWidget {
  final List<String> languages;
  const _LanguagesRow({required this.languages});

  @override
  Widget build(BuildContext context) {
    final list = languages.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Langues', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        if (list.isEmpty)
          Text('—', style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: list
                .map(
                  (l) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.full), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Text(l, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _ExpandableTextRowState extends State<_ExpandableTextRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.text.trim();
    final text = raw.isEmpty ? '—' : raw;
    final maxLines = _expanded ? 99 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: text == '—' ? null : () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(_expanded ? 'Voir moins' : 'Voir plus'),
            ),
          ],
        ),
        Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, height: 1.4)),
      ],
    );
  }
}

// ============================================================================
// Documents Tab
// ============================================================================

class _DocumentsTab extends StatelessWidget {
  final String uid;
  final DocumentService docs;
  final FirestoreUserService userService;
  final String filter;
  final ValueChanged<String> onChangeFilter;
  const _DocumentsTab({required this.uid, required this.docs, required this.userService, required this.filter, required this.onChangeFilter});

  static const _filters = ['Tous', 'CIN', 'Passeport', 'Permis', 'Diplôme', 'PreuveAdresse', 'Autre'];

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.folder_special_rounded,
          title: 'Documents',
          subtitle: 'Portefeuille documentaire sécurisé',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filters
                    .map(
                      (f) => ChoiceChip(
                        label: Text(f),
                        selected: filter == f,
                        onSelected: (_) => onChangeFilter(f),
                        selectedColor: LightModeColors.accent.withValues(alpha: 0.18),
                        labelStyle: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: filter == f ? LightModeColors.accent : Theme.of(context).colorScheme.onSurface),
                        side: BorderSide(color: filter == f ? LightModeColors.accent : Theme.of(context).dividerColor),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: docs.streamDocuments(uid),
                builder: (context, snap) {
                  final all = snap.data ?? const <Map<String, dynamic>>[];
                  final filtered = all.where((d) {
                    if (filter == 'Tous') return true;
                    final t = (d['doc_type'] as String?) ?? (d['docType'] as String?) ?? 'Autre';
                    return t == filter;
                  }).toList(growable: false);

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text('Aucun document pour ce filtre.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                    );
                  }

                  return Column(
                    children: filtered.take(8).map((data) {
                      final title = (data['title'] as String?) ?? (data['doc_id'] as String?) ?? (data['docId'] as String?) ?? 'Document';
                      final docId = (data['doc_id'] as String?) ?? (data['docId'] as String?) ?? '';
                      final status = (data['status'] as String?) ?? 'pending';
                      final exp = data['expires_at'];
                      final expiresAt = exp is DateTime ? exp : (exp is String ? DateTime.tryParse(exp) : null);
                      final dateStr = expiresAt == null ? '—' : '${expiresAt.day.toString().padLeft(2, '0')}/${expiresAt.month.toString().padLeft(2, '0')}/${expiresAt.year}';
                      final chip = _DocStatusChip.from(status);
                      return DocRow(
                        name: title,
                        date: docId.isEmpty ? 'Expiration: $dateStr' : '$docId • Exp: $dateStr',
                        status: chip.label,
                        statusBg: chip.bg,
                        statusText: chip.fg,
                      );
                    }).toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await _ConfirmFeeSheet.show(context, title: 'Uploader un document', description: 'Frais institutionnels (simulation): 1 USD par dépôt.', amountLabel: 'Payer 1 USD et continuer');
                  if (confirmed != true) return;
                  try {
                    await userService.addPaymentTransaction(uid: uid, title: 'Dépôt de document', amount: 1, currency: 'USD', method: 'Simulé', status: 'paid');
                  } catch (e) {
                    debugPrint('DocumentsTab: addPaymentTransaction failed err=$e');
                  }
                  if (!context.mounted) return;
                  context.push(AppRoutes.vault);
                },
                icon: const Icon(Icons.upload_rounded, color: Color(0xFF0A2F5C)),
                label: const Text('Uploader un nouveau document (1 USD)'),
                style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DocStatusChip {
  final String label;
  final Color bg;
  final Color fg;
  const _DocStatusChip({required this.label, required this.bg, required this.fg});

  factory _DocStatusChip.from(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'verified') return _DocStatusChip(label: 'Vérifié', bg: const Color(0xFFE6FFFA), fg: LightModeColors.success);
    if (v == 'rejected') return _DocStatusChip(label: 'Rejeté', bg: Colors.red.shade50, fg: Colors.red.shade700);
    return _DocStatusChip(label: 'En attente', bg: LightModeColors.accent.withValues(alpha: 0.15), fg: const Color(0xFF8A6B00));
  }
}

class _ConfirmFeeSheet {
  static Future<bool?> show(BuildContext context, {required String title, required String description, required String amountLabel}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), topRight: Radius.circular(AppRadius.xl)), border: Border.all(color: Theme.of(context).dividerColor)),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(onPressed: () => context.pop(false), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(description, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.4)),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(true),
                  icon: const Icon(Icons.payments_rounded, color: Color(0xFF0A2F5C)),
                  label: Text(amountLabel, style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF0A2F5C), fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: () => context.pop(false), child: const Text('Annuler')),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// Experience & Skills Tab
// ============================================================================

class _ExperienceSkillsTab extends StatelessWidget {
  final String uid;
  final ThixProfile profile;
  final ProfileService profileService;
  const _ExperienceSkillsTab({required this.uid, required this.profile, required this.profileService});

  @override
  Widget build(BuildContext context) {
    final user = profile;
    return _TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.work_history_rounded,
          title: 'Expériences professionnelles',
          subtitle: '${user.experience.length} entrée(s)',
          child: Column(
            children: [
              if (user.experience.isEmpty)
                Text('Aucune expérience. Ajoutez votre parcours professionnel.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
              else
                ...user.experience.map((e) {
                  final title = (e['title'] as String?) ?? (e['titleC'] as String?) ?? '—';
                  final org = (e['org'] as String?) ?? (e['company'] as String?) ?? '';
                  final date = (e['date'] as String?) ?? (e['period'] as String?) ?? '';
                  final tasks = (e['tasks'] as String?) ?? (e['missions'] as String?) ?? '';
                  final meta = [org, date].where((v) => v.trim().isNotEmpty).join(' • ');
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.work_rounded, color: LightModeColors.secondaryText),
                    title: Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                    subtitle: Text(
                      [meta, tasks.trim().isEmpty ? '' : _truncate(tasks, 90)].where((v) => v.trim().isNotEmpty).join('\n'),
                      style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35),
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _ExperienceEditorSheet.show(context, profile: user, profileService: profileService),
                  icon: const Icon(Icons.add_rounded, color: Color(0xFF0A2F5C)),
                  label: const Text('Ajouter une expérience'),
                  style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardCard(
          icon: Icons.psychology_rounded,
          title: 'Compétences',
          subtitle: '${user.skills.length} compétence(s)',
          child: Column(
            children: [
              if (user.skills.isEmpty)
                Text('Aucune compétence. Ajoutez vos compétences clés.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
              else
                ...user.skills.map((s) {
                  final name = (s['name'] as String?) ?? '—';
                  final level = (s['level'] as String?) ?? '—';
                  final details = (s['details'] as String?) ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: LightModeColors.secondaryText, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                              if (details.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(_truncate(details, 110), style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: level, bg: LightModeColors.accent.withValues(alpha: 0.18), textColor: const Color(0xFF0A2F5C)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => _SkillsEditorSheet.show(context, profile: user, profileService: profileService),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Ajouter une compétence'),
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, side: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: _VisibilityToggle(
                  label: 'Public',
                  value: user.visibility.skills,
                  onChanged: (v) => profileService.updateVisibility(userId: user.userId, visibility: user.visibility.copyWith(skills: v)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Formations Tab
// ============================================================================

class _FormationsTab extends StatelessWidget {
  final String uid;
  final AppUser user;
  final FirestoreUserService userService;
  const _FormationsTab({required this.uid, required this.user, required this.userService});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.school_rounded,
          title: 'Formations',
          subtitle: 'Suivi des inscriptions',
          child: Column(
            children: [
              if (user.enrollments.isEmpty)
                Text('Aucune formation en cours. Inscrivez-vous à une formation officielle.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
              else
                ...user.enrollments.map((e) {
                  final title = (e['title'] as String?) ?? 'Formation';
                  final status = (e['status'] as String?) ?? 'En cours';
                  final progress = ((e['progress'] as num?) ?? 0).clamp(0, 100);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900))),
                            const SizedBox(width: 8),
                            StatusChip(
                              label: status,
                              bg: (status.toLowerCase().contains('compl') ? LightModeColors.success : LightModeColors.accent).withValues(alpha: 0.18),
                              textColor: const Color(0xFF0A2F5C),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          child: LinearProgressIndicator(
                            value: progress / 100.0,
                            minHeight: 10,
                            backgroundColor: Colors.black.withValues(alpha: 0.08),
                            valueColor: const AlwaysStoppedAnimation(LightModeColors.accent),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('$progress%', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.education),
                icon: const Icon(Icons.explore_rounded, color: Color(0xFF0A2F5C)),
                label: const Text('Parcourir et s’inscrire'),
                style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CV Tab
// ============================================================================

class _CvTab extends StatefulWidget {
  final AppUser user;
  const _CvTab({required this.user});

  @override
  State<_CvTab> createState() => _CvTabState();
}

class _CvTabState extends State<_CvTab> {
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return _TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.description_rounded,
          title: 'Portfolio / CV',
          subtitle: 'CV numérique généré à partir de votre profil',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(user.displayName, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text([user.occupation, user.countryOrOrigin].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • '), style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                    const SizedBox(height: 10),
                    Text((user.bio ?? '').trim().isEmpty ? 'Bio non renseignée.' : user.bio!.trim(), maxLines: 5, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(height: 1.35)),
                    const SizedBox(height: 12),
                    Text('Expériences', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    if (user.experience.isEmpty)
                      Text('—', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
                    else
                      ...user.experience.take(3).map((e) {
                        final title = (e['title'] as String?) ?? '—';
                        final org = (e['org'] as String?) ?? (e['company'] as String?) ?? '';
                        final tasks = (e['tasks'] as String?) ?? (e['missions'] as String?) ?? '';
                        final suffix = org.trim().isEmpty ? '' : ' — $org';
                        final tasksSuffix = tasks.trim().isEmpty ? '' : '\n   ${_truncate(tasks, 90)}';
                        return Text('• $title$suffix$tasksSuffix', style: context.textStyles.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface, height: 1.4));
                      }),
                    const SizedBox(height: 12),
                    Text('Langues', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(user.languages.isEmpty ? '—' : user.languages.join(' • '), style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _exporting
                      ? null
                      : () async {
                          setState(() => _exporting = true);
                          try {
                            final bytes = await _DigitalCvPdf.build(user);
                            if (!mounted) return;
                            await Printing.layoutPdf(onLayout: (_) async => bytes);
                          } catch (e) {
                            debugPrint('CV export failed err=$e');
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export PDF impossible.')));
                          } finally {
                            if (mounted) setState(() => _exporting = false);
                          }
                        },
                  icon: _exporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0A2F5C)))
                      : const Icon(Icons.download_rounded, color: Color(0xFF0A2F5C)),
                  label: Text('Télécharger CV Numérique (PDF)', style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF0A2F5C), fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Sur Web, un dialogue d’impression/export s’ouvre. Sur mobile, vous pouvez enregistrer/imprimer.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DigitalCvPdf {
  static Future<Uint8List> build(AppUser u) async {
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont();
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        build: (_) {
          return [
            pw.Text('THIX ID — CV Numérique', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(u.displayName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(u.thixId, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 8),
            pw.Text([u.occupation, u.countryOrOrigin].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • ')),
            pw.SizedBox(height: 10),
            pw.Text('Bio', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text((u.bio ?? '').trim().isEmpty ? '—' : u.bio!.trim()),
            pw.SizedBox(height: 12),
            pw.Text('Expériences', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (u.experience.isEmpty) pw.Text('—') else ...u.experience.map((e) {
              final title = (e['title'] as String?) ?? '';
              final org = (e['org'] as String?) ?? (e['company'] as String?) ?? '';
              final date = (e['date'] as String?) ?? (e['period'] as String?) ?? '';
              final tasks = (e['tasks'] as String?) ?? (e['missions'] as String?) ?? '';
              final line = [title, org, date].where((v) => v.trim().isNotEmpty).join(' • ');
              final detail = tasks.trim().isEmpty ? '' : ' — ${_truncate(tasks, 140)}';
              return pw.Bullet(text: (line + detail).trim().isEmpty ? '—' : (line + detail));
            }).toList(growable: false),
            pw.SizedBox(height: 12),
            pw.Text('Formations', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (u.education.isEmpty) pw.Text('—') else ...u.education.map((e) {
              final inst = (e['institution'] as String?) ?? '';
              final degree = (e['degree'] as String?) ?? '';
              final period = (e['period'] as String?) ?? '';
              final line = [inst, degree, period].where((v) => v.trim().isNotEmpty).join(' • ');
              return pw.Bullet(text: line.trim().isEmpty ? '—' : line);
            }).toList(growable: false),
            pw.SizedBox(height: 12),
            pw.Text('Compétences', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (u.skills.isEmpty) pw.Text('—') else ...u.skills.map((s) {
              final n = (s['name'] as String?) ?? '';
              final l = (s['level'] as String?) ?? '';
              final details = (s['details'] as String?) ?? '';
              final line = [n, l].where((v) => v.trim().isNotEmpty).join(' — ');
              final detail = details.trim().isEmpty ? '' : ' (${_truncate(details, 110)})';
              return pw.Bullet(text: (line + detail).trim().isEmpty ? '—' : (line + detail));
            }).toList(growable: false),
            pw.SizedBox(height: 12),
            pw.Text('Langues', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(u.languages.isEmpty ? '—' : u.languages.join(' • ')),
          ];
        },
      ),
    );
    return doc.save();
  }
}

// ============================================================================
// Payments Tab
// ============================================================================

class _PaymentsTab extends StatelessWidget {
  final String uid;
  final FirestoreUserService userService;
  final AppUser user;
  const _PaymentsTab({required this.uid, required this.userService, required this.user});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.payments_rounded,
          title: 'Historique des Paiements',
          subtitle: 'Transactions liées à votre identité',
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: userService.streamPayments(uid),
            builder: (context, snap) {
              final list = snap.data ?? const <Map<String, dynamic>>[];
              if (list.isEmpty) {
                return Text('Aucune transaction enregistrée.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText));
              }
              return Column(
                children: list.take(15).map((data) {
                  final title = (data['title'] as String?) ?? (data['tx_ref'] as String?) ?? 'Transaction';
                  final amount = data['amount'];
                  final currency = (data['currency'] as String?) ?? 'USD';
                  final method = (data['method'] as String?) ?? '—';
                  final status = (data['status'] as String?) ?? 'paid';
                  final created = data['created_at'];
                  final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
                  final dateStr = dt == null ? '—' : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
                  final amountStr = '${(amount is num ? amount.toStringAsFixed(2) : amount?.toString() ?? '0.00')} $currency';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(status == 'paid' ? Icons.check_circle_rounded : Icons.hourglass_bottom_rounded, color: status == 'paid' ? LightModeColors.success : LightModeColors.accent),
                    title: Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                    subtitle: Text('$dateStr • $method', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(amountStr, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Reçu (PDF)',
                          onPressed: () async {
                            try {
                              final bytes = await _ReceiptPdf.build(user: user, tx: data);
                              if (!context.mounted) return;
                              await Printing.layoutPdf(onLayout: (_) async => bytes);
                            } catch (e) {
                              debugPrint('Receipt export failed err=$e');
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Téléchargement du reçu impossible.')));
                            }
                          },
                          icon: const Icon(Icons.download_rounded),
                        ),
                      ],
                    ),
                  );
                }).toList(growable: false),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReceiptPdf {
  static Future<Uint8List> build({required AppUser user, required Map<String, dynamic> tx}) async {
    final title = (tx['title'] as String?) ?? 'Transaction';
    final amount = tx['amount'];
    final currency = (tx['currency'] as String?) ?? 'USD';
    final method = (tx['method'] as String?) ?? '—';
    final status = (tx['status'] as String?) ?? 'paid';
    final created = tx['created_at'];
    final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
    final dateStr = dt == null ? '—' : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final amountStr = '${(amount is num ? amount.toStringAsFixed(2) : amount?.toString() ?? '0.00')} $currency';

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (_) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('THIX ID — Reçu', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 12),
                pw.Text('Utilisateur: ${user.displayName}'),
                pw.Text('THIX ID: ${user.thixId}'),
                pw.SizedBox(height: 12),
                pw.Text('Opération: $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Montant: $amountStr'),
                pw.Text('Méthode: $method'),
                pw.Text('Statut: $status'),
                pw.Text('Date: $dateStr'),
                pw.SizedBox(height: 18),
                pw.Text('Ce reçu est généré automatiquement (simulation).'),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }
}

// ============================================================================
// Security Tab
// ============================================================================

class _SecurityTab extends StatelessWidget {
  final String uid;
  final AppUser user;
  final FirestoreUserService userService;
  const _SecurityTab({required this.uid, required this.user, required this.userService});

  @override
  Widget build(BuildContext context) {
    return _TabScaffold(
      children: [
        DashboardCard(
          icon: Icons.security_rounded,
          title: 'Sécurité du Compte',
          subtitle: 'Paramètres de protection et journalisation',
          child: Column(
            children: [
              _SecurityToggleRow(
                icon: Icons.fingerprint_rounded,
                title: 'Biométrie (Face ID / Empreinte)',
                value: user.biometricsEnabled,
                onChanged: (v) async {
                  try {
                    await userService.updateProfile(uid: uid, biometricsEnabled: v);
                    unawaited(userService.logSecurityEvent(uid: uid, type: 'security_change', label: 'Biométrie ${v ? 'activée' : 'désactivée'}'));
                  } catch (e) {
                    debugPrint('SecurityTab: biometrics toggle failed err=$e');
                  }
                },
              ),
              _SecurityToggleRow(
                icon: Icons.vpn_key_rounded,
                title: 'Double Authentification (2FA)',
                value: user.twoFaEnabled,
                onChanged: (v) async {
                  try {
                    await userService.updateProfile(uid: uid, twoFaEnabled: v);
                    unawaited(userService.logSecurityEvent(uid: uid, type: 'security_change', label: '2FA ${v ? 'activée' : 'désactivée'}'));
                  } catch (e) {
                    debugPrint('SecurityTab: 2fa toggle failed err=$e');
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Historique des connexions', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  TextButton.icon(onPressed: () => context.push(AppRoutes.settings), icon: const Icon(Icons.settings_rounded, size: 18), label: const Text('Paramètres')),
                ],
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: userService.streamSecurityEvents(uid),
                builder: (context, snap) {
                  final list = snap.data ?? const <Map<String, dynamic>>[];
                  if (list.isEmpty) {
                    return Align(alignment: Alignment.centerLeft, child: Text('Aucun événement.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)));
                  }
                  return Column(
                    children: list.take(8).map((data) {
                      final label = (data['label'] as String?) ?? (data['type'] as String?) ?? 'Événement';
                      final created = data['created_at'];
                      final dt = created is DateTime ? created : (created is String ? DateTime.tryParse(created) : null);
                      final dateStr = dt == null ? '—' : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.history_rounded, color: LightModeColors.secondaryText),
                        title: Text(label, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                        subtitle: Text(dateStr, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                      );
                    }).toList(growable: false),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Gestion avancée (2FA, appareils, etc.)'),
                  style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary, side: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SecurityToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SecurityToggleRow({required this.icon, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: LightModeColors.secondaryText, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(title, style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
          ],
        ),
        Switch(value: value, onChanged: onChanged, activeColor: LightModeColors.success),
      ],
    );
  }
}

// ============================================================================
// Skills Editor Sheet
// ============================================================================

class _SkillsEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SkillsEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _SkillsEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _SkillsEditorBody({required this.profile, required this.profileService});

  @override
  State<_SkillsEditorBody> createState() => _SkillsEditorBodyState();
}

class _SkillsEditorBodyState extends State<_SkillsEditorBody> {
  final _nameC = TextEditingController();
  final _detailsC = TextEditingController();
  String _level = 'Intermédiaire';
  bool _saving = false;
  int? _editingIndex;

  @override
  void dispose() {
    _nameC.dispose();
    _detailsC.dispose();
    super.dispose();
  }

  void _loadForEdit(int index, Map<String, dynamic> entry) {
    setState(() {
      _editingIndex = index;
      _nameC.text = (entry['name'] as String?) ?? '';
      _level = (entry['level'] as String?) ?? 'Intermédiaire';
      _detailsC.text = (entry['details'] as String?) ?? '';
    });
  }

  void _resetForm() {
    setState(() {
      _editingIndex = null;
      _nameC.clear();
      _level = 'Intermédiaire';
      _detailsC.clear();
    });
  }

  Future<void> _save(List<Map<String, dynamic>> existing) async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom de compétence requis.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final next = [...existing];
      final patch = {
        'name': name,
        'level': _level,
        if (_detailsC.text.trim().isNotEmpty) 'details': _detailsC.text.trim(),
      };
      if (_editingIndex != null && _editingIndex! >= 0 && _editingIndex! < next.length) {
        next[_editingIndex!] = patch;
      } else {
        next.add(patch);
      }
      await widget.profileService.updateProfile(userId: widget.profile.userId, skills: next);
      if (!mounted) return;
      final wasEdit = _editingIndex != null;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wasEdit ? 'Compétence mise à jour.' : 'Compétence ajoutée.')));
    } catch (e) {
      debugPrint('SkillsEditor: save failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde impossible.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(List<Map<String, dynamic>> existing, int index) async {
    if (index < 0 || index >= existing.length) return;
    setState(() => _saving = true);
    try {
      final next = [...existing]..removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, skills: next);
      if (!mounted) return;
      if (_editingIndex == index) _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compétence supprimée.')));
    } catch (e) {
      debugPrint('SkillsEditor: delete failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suppression impossible.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), topRight: Radius.circular(AppRadius.xl)), border: Border.all(color: Theme.of(context).dividerColor)),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<ThixProfile?>(
          stream: widget.profileService.streamMyProfile(widget.profile.userId),
          builder: (context, snap) {
            final existing = (snap.data ?? widget.profile).skills;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_editingIndex == null ? 'Ajouter une compétence' : 'Modifier une compétence', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (existing.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Vos compétences', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(existing.length, (i) {
                          final e = existing[i];
                          final name = (e['name'] as String?) ?? '—';
                          final level = (e['level'] as String?) ?? '—';
                          final details = (e['details'] as String?) ?? '';
                          final selected = _editingIndex == i;
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(color: selected ? LightModeColors.accent.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: selected ? LightModeColors.accent : Theme.of(context).dividerColor)),
                            child: ListTile(
                              dense: true,
                              title: Text(name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                              subtitle: Text(
                                [level, details.trim().isEmpty ? '' : _truncate(details, 90)].where((v) => v.trim().isNotEmpty).join(' • '),
                                style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35),
                              ),
                              onTap: _saving ? null : () => _loadForEdit(i, e),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: LightModeColors.error), onPressed: _saving ? null : () => _delete(existing, i)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                if (existing.isNotEmpty) const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _nameC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Compétence', prefixIcon: const Icon(Icons.psychology_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _detailsC,
                  textInputAction: TextInputAction.next,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Explication / Détails', hintText: 'Expliquez en bref votre compétence…', prefixIcon: const Icon(Icons.notes_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _level,
                  items: const [
                    DropdownMenuItem(value: 'Débutant', child: Text('Débutant')),
                    DropdownMenuItem(value: 'Intermédiaire', child: Text('Intermédiaire')),
                    DropdownMenuItem(value: 'Avancé', child: Text('Avancé')),
                    DropdownMenuItem(value: 'Expert', child: Text('Expert')),
                  ],
                  onChanged: (v) => setState(() => _level = v ?? 'Intermédiaire'),
                  decoration: InputDecoration(labelText: 'Niveau', prefixIcon: const Icon(Icons.stacked_bar_chart_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(existing),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0A2F5C)))
                        : const Icon(Icons.save_rounded, color: Color(0xFF0A2F5C)),
                    label: Text(_editingIndex == null ? 'AJOUTER' : 'METTRE À JOUR', style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF0A2F5C), fontWeight: FontWeight.w900)),
                    style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                  ),
                ),
                if (_editingIndex != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(onPressed: _saving ? null : _resetForm, icon: const Icon(Icons.restart_alt_rounded), label: const Text('Annuler la modification')),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Experience Editor Sheet
// ============================================================================

class _ExperienceEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExperienceEditorBody(profile: profile, profileService: profileService),
    );
  }
}

class _ExperienceEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  const _ExperienceEditorBody({required this.profile, required this.profileService});

  @override
  State<_ExperienceEditorBody> createState() => _ExperienceEditorBodyState();
}

class _ExperienceEditorBodyState extends State<_ExperienceEditorBody> {
  final _titleC = TextEditingController();
  final _orgC = TextEditingController();
  final _dateC = TextEditingController();
  final _tasksC = TextEditingController();
  final _sectorC = TextEditingController();
  final _cityC = TextEditingController();
  List<EvidenceFileRef> _evidence = const [];
  final _docs = DocumentService();
  bool _saving = false;
  int? _editingIndex;

  @override
  void dispose() {
    _titleC.dispose();
    _orgC.dispose();
    _dateC.dispose();
    _tasksC.dispose();
    _sectorC.dispose();
    _cityC.dispose();
    super.dispose();
  }

  void _loadForEdit(int index, Map<String, dynamic> entry) {
    final rawEvidence = (entry['evidence'] as List?) ?? const [];
    final parsed = rawEvidence.map(EvidenceFileRef.tryParse).whereType<EvidenceFileRef>().toList(growable: false);
    setState(() {
      _editingIndex = index;
      _titleC.text = (entry['title'] as String?) ?? '';
      _orgC.text = (entry['org'] as String?) ?? (entry['company'] as String?) ?? '';
      _dateC.text = (entry['date'] as String?) ?? (entry['period'] as String?) ?? '';
      _tasksC.text = (entry['tasks'] as String?) ?? (entry['missions'] as String?) ?? '';
      _sectorC.text = (entry['sector'] as String?) ?? '';
      _cityC.text = (entry['city'] as String?) ?? '';
      _evidence = parsed;
    });
  }

  void _resetForm() {
    setState(() {
      _editingIndex = null;
      _titleC.clear();
      _orgC.clear();
      _dateC.clear();
      _tasksC.clear();
      _sectorC.clear();
      _cityC.clear();
      _evidence = const [];
    });
  }

  Future<void> _pickEvidenceFiles() async {
    try {
      final res = await FilePicker.pickFiles(allowMultiple: true, withData: kIsWeb, type: FileType.custom, allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp']);
      if (res == null || res.files.isEmpty) return;
      setState(() => _saving = true);
      final uid = widget.profile.userId;
      final uploaded = <EvidenceFileRef>[];
      for (final f in res.files) {
        final docId = 'CRED_EXP_${DateTime.now().millisecondsSinceEpoch}_${f.name}'.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_').toUpperCase();
        await _docs.uploadPickedFile(uid: uid, docId: docId, title: 'Pièce expérience: ${_titleC.text.trim().isEmpty ? f.name : _titleC.text.trim()}', file: f, docType: 'credential_experience');
        uploaded.add(EvidenceFileRef(storagePathOrUrl: 'documents:$docId', label: f.name));
      }
      if (!mounted) return;
      setState(() => _evidence = [..._evidence, ...uploaded]);
    } catch (e) {
      debugPrint('ExperienceEditor: pick evidence failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajout de pièces impossible.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(List<Map<String, dynamic>> existing) async {
    final title = _titleC.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre requis.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final next = [...existing];
      final patch = {
        'title': title,
        'org': _orgC.text.trim(),
        'date': _dateC.text.trim(),
        'sector': _sectorC.text.trim(),
        'city': _cityC.text.trim(),
        if (_tasksC.text.trim().isNotEmpty) 'tasks': _tasksC.text.trim(),
        'verification_status': VerificationStatus.pending.value,
        'evidence': _evidence.map((e) => e.toJson()).toList(growable: false),
      };
      if (_editingIndex != null && _editingIndex! >= 0 && _editingIndex! < next.length) {
        next[_editingIndex!] = patch;
      } else {
        next.add(patch);
      }
      await widget.profileService.updateProfile(userId: widget.profile.userId, experience: next);
      if (!mounted) return;
      final wasEdit = _editingIndex != null;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(wasEdit ? 'Expérience mise à jour.' : 'Expérience ajoutée.')));
    } catch (e) {
      debugPrint('ExperienceEditor: save failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde impossible.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(List<Map<String, dynamic>> existing, int index) async {
    if (index < 0 || index >= existing.length) return;
    setState(() => _saving = true);
    try {
      final next = [...existing]..removeAt(index);
      await widget.profileService.updateProfile(userId: widget.profile.userId, experience: next);
      if (!mounted) return;
      if (_editingIndex == index) _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expérience supprimée.')));
    } catch (e) {
      debugPrint('ExperienceEditor: delete failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suppression impossible.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), topRight: Radius.circular(AppRadius.xl)), border: Border.all(color: Theme.of(context).dividerColor)),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: StreamBuilder<ThixProfile?>(
          stream: widget.profileService.streamMyProfile(widget.profile.userId),
          builder: (context, snap) {
            final existing = (snap.data ?? widget.profile).experience;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_editingIndex == null ? 'Ajouter une expérience' : 'Modifier une expérience', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (existing.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).dividerColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Vos expériences', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: AppSpacing.sm),
                        ...List.generate(existing.length, (i) {
                          final e = existing[i];
                          final title = (e['title'] as String?) ?? '—';
                          final org = (e['org'] as String?) ?? (e['company'] as String?) ?? '';
                          final date = (e['date'] as String?) ?? (e['period'] as String?) ?? '';
                          final tasks = (e['tasks'] as String?) ?? (e['missions'] as String?) ?? '';
                          final subtitle = [org, date, tasks.trim().isEmpty ? '' : _truncate(tasks, 90)].where((v) => v.trim().isNotEmpty).join(' • ');
                          final selected = _editingIndex == i;
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            decoration: BoxDecoration(color: selected ? LightModeColors.accent.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: selected ? LightModeColors.accent : Theme.of(context).dividerColor)),
                            child: ListTile(
                              dense: true,
                              title: Text(title, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                              subtitle: subtitle.trim().isEmpty ? null : Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText)),
                              onTap: _saving ? null : () => _loadForEdit(i, e),
                              trailing: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: LightModeColors.error), onPressed: _saving ? null : () => _delete(existing, i)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                if (existing.isNotEmpty) const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _titleC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Titre', prefixIcon: const Icon(Icons.work_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _orgC,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: 'Organisation', prefixIcon: const Icon(Icons.business_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _sectorC,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Secteur', prefixIcon: const Icon(Icons.category_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _cityC,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Ville', prefixIcon: const Icon(Icons.location_city_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _dateC,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(labelText: 'Période', hintText: '2023-2025', prefixIcon: const Icon(Icons.calendar_today_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _tasksC,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: 'Tâches / Responsabilités', hintText: 'Expliquez vos tâches principales…', prefixIcon: const Icon(Icons.playlist_add_check_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attachment_rounded, size: 18, color: LightModeColors.secondaryText),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Pièces obtenues', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
                          OutlinedButton.icon(onPressed: _saving ? null : _pickEvidenceFiles, icon: const Icon(Icons.upload_file_rounded), label: const Text('Ajouter')),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_evidence.isEmpty)
                        Text('Aucune pièce ajoutée.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))
                      else
                        ..._evidence.map((e) {
                          final label = (e.label ?? '').trim().isEmpty ? 'Pièce' : e.label!.trim();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file_rounded, size: 18, color: LightModeColors.accent),
                                const SizedBox(width: 10),
                                Expanded(child: Text(label, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                                IconButton(
                                  onPressed: _saving ? null : () => setState(() => _evidence = _evidence.where((x) => x != e).toList(growable: false)),
                                  icon: const Icon(Icons.close_rounded, color: LightModeColors.error),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _save(existing),
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0A2F5C)))
                        : const Icon(Icons.save_rounded, color: Color(0xFF0A2F5C)),
                    label: Text(_editingIndex == null ? 'AJOUTER' : 'METTRE À JOUR'),
                    style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF0A2F5C), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full))),
                  ),
                ),
                if (_editingIndex != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: _saving ? null : _resetForm,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Annuler la modification'),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Profile Editor Sheet (version simplifiée mais complète)
// ============================================================================

class _ProfileEditorSheet {
  static Future<void> show(BuildContext context, {required ThixProfile profile, required ProfileService profileService, required AppUser authUser}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileEditorBody(profile: profile, profileService: profileService, authUser: authUser),
    );
  }
}

class _ProfileEditorBody extends StatefulWidget {
  final ThixProfile profile;
  final ProfileService profileService;
  final AppUser authUser;
  const _ProfileEditorBody({required this.profile, required this.profileService, required this.authUser});

  @override
  State<_ProfileEditorBody> createState() => _ProfileEditorBodyState();
}

class _ProfileEditorBodyState extends State<_ProfileEditorBody> {
  late final TextEditingController _nameC;
  late final TextEditingController _bioC;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.profile.fullName ?? widget.authUser.displayName);
    _bioC = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nameC.dispose();
    _bioC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameC.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom requis.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.profileService.updateProfile(
        userId: widget.profile.userId,
        fullName: name,
        bio: _bioC.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour.')));
      context.pop();
    } catch (e) {
      debugPrint('ProfileEditor: save failed err=$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Modifier le profil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameC,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioC,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const CircularProgressIndicator() : const Text('SAUVEGARDER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Extensions et fonctions utilitaires
// ============================================================================

extension ThemeHelper on BuildContext {
  ThemeData get theme => Theme.of(this);
}

String _truncate(String v, int max) {
  final s = v.trim();
  if (s.length <= max) return s;
  return '${s.substring(0, max).trim()}…';
}
