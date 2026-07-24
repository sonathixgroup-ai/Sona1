import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import '../../nav.dart';
import '../common/notifications_sheet.dart';

// ============================================================
//  DASHBOARD_UI.DART - TOUS LES WIDGETS STATIQUES PURS
//  Aucune logique métier, aucun service
// ============================================================

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.35, colors: [Color(0xFFEFF5FF), Color(0xFFF6F9FF)]))),
      const Align(alignment: Alignment.center, child: Opacity(opacity: 0.05, child: Icon(Icons.fingerprint_rounded, size: 650, color: Color(0xFF123B7A)))),
    ]);
  }
}

class DashboardTopBar extends StatelessWidget {
  final dynamic user;
  final int score;
  final VoidCallback onBack, onOpenSettings, onEditProfile, onDownloadCv, onShareProfile;
  final Future<void> Function() onLogout;
  const DashboardTopBar({super.key, required this.user, required this.score, required this.onBack, required this.onOpenSettings, required this.onLogout, required this.onEditProfile, required this.onDownloadCv, required this.onShareProfile});
  @override
  Widget build(BuildContext context) {
    final status = (user.registrationStatus ?? '—').toLowerCase();
    final verified = status == 'paid' || status == 'verified';
    final photoUrl = (user.photoUrl ?? '').trim();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF123B7A), Color(0xFF2D6CDF)])),
      child: Stack(children: [
        const Positioned(right: -40, top: 12, child: Opacity(opacity: 0.08, child: Icon(Icons.star_rounded, size: 220, color: Colors.white))),
        const Positioned(right: 40, bottom: -60, child: Opacity(opacity: 0.06, child: Icon(Icons.star_rounded, size: 260, color: Colors.white))),
        Column(children: [
          Row(children: [
            _TopIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
            const Spacer(),
            Text('THIX ID', style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
            const Spacer(),
            _TopIconButton(icon: Icons.notifications_rounded, onTap: () => NotificationsSheet.show(context)),
            const SizedBox(width: AppSpacing.sm),
            _TopIconButton(icon: Icons.settings_rounded, onTap: onOpenSettings),
            const SizedBox(width: AppSpacing.sm),
            _TopIconButton(icon: Icons.logout_rounded, onTap: () async => onLogout()),
          ]),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.10), borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: Colors.white.withOpacity(0.16))),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Stack(children: [
                  Container(width: 92, height: 92, decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: LightModeColors.accent.withOpacity(0.85), width: 3), color: Colors.white.withOpacity(0.10), image: DecorationImage(image: photoUrl.isEmpty ? const AssetImage('assets/images/African_businessman_in_suit_grayscale_1775573970767.jpg') : NetworkImage(photoUrl) as ImageProvider, fit: BoxFit.cover))),
                  Positioned(bottom: -4, right: -4, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: verified ? LightModeColors.success : LightModeColors.accent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF123B7A), width: 3)), alignment: Alignment.center, child: Icon(verified ? Icons.check_rounded : Icons.hourglass_bottom_rounded, color: Colors.white, size: 16))),
                ]),
                const SizedBox(width: AppSpacing.lg),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.displayName, style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: Text(user.thixId, style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withOpacity(0.88), fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.18))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(verified ? Icons.verified_rounded : Icons.hourglass_bottom_rounded, size: 12, color: Colors.white), const SizedBox(width: 4), Text(verified ? 'Vérifiée' : 'En attente', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10))])),
                  ]),
                  const SizedBox(height: 8),
                  Text((user.bio ?? '').trim().isEmpty ? 'Complétez votre profil.' : user.bio!.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withOpacity(0.86), height: 1.35)),
                ])),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(child: _HeaderActionButton(icon: Icons.edit_rounded, label: 'Modifier Profil', onTap: onEditProfile)),
                const SizedBox(width: 8), Expanded(child: _HeaderActionButton(icon: Icons.download_rounded, label: 'CV Numérique', onTap: onDownloadCv)),
                const SizedBox(width: 8), Expanded(child: _HeaderActionButton(icon: Icons.ios_share_rounded, label: 'Partager', onTap: onShareProfile)),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _TopIconButton({required this.icon, required this.onTap});
  @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.white.withOpacity(0.12))), child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap));
}
class _HeaderActionButton extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _HeaderActionButton({required this.icon, required this.label, required this.onTap});
  @override Widget build(BuildContext context) => SizedBox(height: 44, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18, color: Colors.white), label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.22)), backgroundColor: Colors.white.withOpacity(0.10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))));
}

class DashboardTabsHeader extends StatelessWidget {
  const DashboardTabsHeader({super.key});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF123B7A), Color(0xFF2D6CDF)])),
    child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.1))), child: TabBar(isScrollable: true, labelColor: LightModeColors.accent, unselectedLabelColor: Colors.white.withOpacity(0.82), indicator: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30)), dividerColor: Colors.transparent, labelStyle: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w900), tabs: const [Tab(icon: Icon(Icons.person_rounded), text: 'Profil'), Tab(icon: Icon(Icons.folder_rounded), text: 'Documents'), Tab(icon: Icon(Icons.work_rounded), text: 'Expériences'), Tab(icon: Icon(Icons.school_rounded), text: 'Formations'), Tab(icon: Icon(Icons.description_rounded), text: 'CV'), Tab(icon: Icon(Icons.payments_rounded), text: 'Paiements'), Tab(icon: Icon(Icons.security_rounded), text: 'Sécurité')])),
  );
}
class ChatFab extends StatelessWidget { const ChatFab({super.key}); @override Widget build(BuildContext context) => Container(width: 60, height: 60, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [LightModeColors.accent, Color(0xFFE5B13A)]), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 18, offset: const Offset(0, 12))], border: Border.all(color: Colors.white.withOpacity(0.22), width: 2)), alignment: Alignment.center, child: const Icon(Icons.forum_rounded, size: 26, color: Color(0xFF123B7A))); }

class SectionHeader extends StatelessWidget {
  final String title, subtitle, actionLabel; final bool showAction;
  const SectionHeader({super.key, required this.title, required this.subtitle, this.actionLabel="Action", this.showAction=false});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.titleLarge?.copyWith(color: context.theme.colorScheme.onSurface)), const SizedBox(height: 4), Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))]), if(showAction) TextButton(onPressed: (){}, child: Text(actionLabel, style: context.textStyles.labelMedium?.copyWith(color: context.theme.colorScheme.primary)))]));
}
class DashboardProfileStat extends StatelessWidget { final String label, value; const DashboardProfileStat({super.key, required this.label, required this.value}); @override Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, style: context.textStyles.titleMedium?.copyWith(color: context.theme.colorScheme.onSurface, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(label, style: context.textStyles.labelSmall?.copyWith(color: LightModeColors.secondaryText))])); }
class DashboardCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final Widget child;
  const DashboardCard({super.key, required this.icon, required this.title, required this.subtitle, required this.child});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: AppSpacing.md), padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: context.theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: context.theme.dividerColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0,1))]), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: context.theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md)), alignment: Alignment.center, child: Icon(icon, color: context.theme.colorScheme.primary, size: 22)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.titleMedium?.copyWith(color: context.theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis), Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis)])), const Icon(Icons.chevron_right_rounded, color: LightModeColors.hint, size: 20)]), const SizedBox(height: AppSpacing.md), child]));
}
class StatusChip extends StatelessWidget { final String label; final Color bg, textColor; const StatusChip({super.key, required this.label, required this.bg, required this.textColor}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(30)), child: Text(label, style: context.textStyles.labelSmall?.copyWith(color: textColor))); }
class DocRow extends StatelessWidget { final String name, date, status; final Color statusBg, statusText; const DocRow({super.key, required this.name, required this.date, required this.status, required this.statusBg, required this.statusText}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: context.theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(AppRadius.md)), alignment: Alignment.center, child: Icon(Icons.insert_drive_file_rounded, color: context.theme.colorScheme.primary, size: 24)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(date, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText))])), StatusChip(label: status, bg: statusBg, textColor: statusText)])); }
class NetworkItem extends StatelessWidget { final String name, role, avatarDesc; const NetworkItem({super.key, required this.name, required this.role, required this.avatarDesc}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: Row(children: [const CircleAvatar(radius: 24, backgroundColor: LightModeColors.background, child: Icon(Icons.person, color: LightModeColors.hint)), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: context.theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(role, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText), maxLines: 1, overflow: TextOverflow.ellipsis)])), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: context.theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(30)), child: Text("Connecté", style: context.textStyles.labelSmall?.copyWith(color: LightModeColors.success)))])); }
class DashboardInfoRow extends StatelessWidget { final String label, value; const DashboardInfoRow({super.key, required this.label, required this.value}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 130, child: Text(label, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, fontWeight: FontWeight.w700))), const SizedBox(width: AppSpacing.md), Expanded(child: Text(value, style: context.textStyles.bodyMedium?.copyWith(color: context.theme.colorScheme.onSurface, height: 1.35), softWrap: true))])); }
class ActivationCalloutCard extends StatelessWidget { final VoidCallback onActivate; const ActivationCalloutCard({super.key, required this.onActivate}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: AppSpacing.md), padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: context.theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.xl), border: Border.all(color: LightModeColors.accent.withOpacity(0.35)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [LightModeColors.accent, Color(0xFFE5B13A)]), borderRadius: BorderRadius.circular(AppRadius.lg)), alignment: Alignment.center, child: const Icon(Icons.verified_rounded, color: Color(0xFF123B7A))), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Compte en attente d\'activation', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('Vos informations sont bien enregistrées. Activez maintenant pour obtenir votre THIX ID officiel et accéder aux fonctionnalités protégées.', style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.secondaryText, height: 1.35))]))]), const SizedBox(height: AppSpacing.md), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: LightModeColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: LightModeColors.accent.withOpacity(0.22))), child: Row(children: [const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF123B7A)), const SizedBox(width: 10), Expanded(child: Text('Paiement fictif (simulation) : aucune API réelle n\'est utilisée pour le moment.', style: context.textStyles.bodySmall?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w700, height: 1.3)))])), const SizedBox(height: AppSpacing.md), SizedBox(height: 52, child: ElevatedButton.icon(onPressed: onActivate, icon: const Icon(Icons.payments_rounded, color: Color(0xFF123B7A)), label: Text('Activer mon compte (paiement fictif)', style: context.textStyles.labelLarge?.copyWith(color: const Color(0xFF123B7A), fontWeight: FontWeight.w900)), style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, foregroundColor: const Color(0xFF123B7A), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))))])); }
class TabScaffold extends StatelessWidget { final List<Widget> children; const TabScaffold({super.key, required this.children}); @override Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)); }
class ShareProfileSheet { static Future<void> show(BuildContext context, dynamic profile) async { await showModalBottomSheet<void>(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(decoration: BoxDecoration(color: context.theme.colorScheme.surface, borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.xl), topRight: Radius.circular(AppRadius.xl)), border: Border.all(color: context.theme.dividerColor)), padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Public View', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)), IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))]), const SizedBox(height: AppSpacing.md), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.remove_red_eye_rounded), title: const Text('Voir mon profil public'), subtitle: const Text('Aperçu en lecture seule (données publiques uniquement).'), onTap: () { context.pop(); final thixId = profile.thixId.trim(); context.push('${AppRoutes.publicProfile}?thixId=${Uri.encodeComponent(thixId)}'); }), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.ios_share_rounded), title: const Text('Partager mon lien public'), subtitle: const Text('Copie/partage le lien du profil public.'), onTap: () async { context.pop(); final thixId = profile.thixId.trim(); final url = thixId.isEmpty ? '' : 'https://thix.app/public-profile?thixId=${Uri.encodeComponent(thixId)}'; final text = url.isEmpty ? 'Mon profil THIX ID: $thixId' : 'Mon profil THIX ID: $thixId\n$url'; try { await Share.share(text); } catch (e) { debugPrint('Share profile failed err=$e'); } })]))); } }

extension ThemeHelper on BuildContext { ThemeData get theme => Theme.of(this); }
