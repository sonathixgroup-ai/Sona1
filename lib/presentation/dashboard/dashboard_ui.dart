import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme.dart';
import '../../nav.dart';
import '../common/notifications_sheet.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});
  @override Widget build(BuildContext context) => Stack(children: [
    Container(decoration: const BoxDecoration(gradient: RadialGradient(center: Alignment.center, radius: 1.35, colors: [Color(0xFFEFF5FF), Color(0xFFF6F9FF)]))),
    const Align(alignment: Alignment.center, child: Opacity(opacity: 0.05, child: Icon(Icons.fingerprint_rounded, size: 650, color: Color(0xFF123B7A)))),
  ]);
}

class DashboardTopBar extends StatelessWidget {
  final dynamic user; final int score;
  final VoidCallback onBack, onOpenSettings, onEditProfile, onDownloadCv, onShareProfile;
  final Future<void> Function() onLogout;
  const DashboardTopBar({super.key, required this.user, required this.score, required this.onBack, required this.onOpenSettings, required this.onLogout, required this.onEditProfile, required this.onDownloadCv, required this.onShareProfile});
  @override Widget build(BuildContext context) {
    final verified = (user.registrationStatus ?? '').toLowerCase() == 'paid';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF123B7A), Color(0xFF2D6CDF)])),
      child: Column(children: [
        Row(children: [
          _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          const Spacer(), Text('THIX ID', style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const Spacer(),
          _IconBtn(icon: Icons.notifications_rounded, onTap: () => NotificationsSheet.show(context)),
          const SizedBox(width: 8), _IconBtn(icon: Icons.settings_rounded, onTap: onOpenSettings),
          const SizedBox(width: 8), _IconBtn(icon: Icons.logout_rounded, onTap: () async => onLogout()),
        ]),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.15))),
          child: Row(children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: LightModeColors.accent, width: 2), image: DecorationImage(image: (user.photoUrl ?? '').isEmpty ? const AssetImage('assets/images/African_businessman_in_suit_grayscale_1775573970767.jpg') : NetworkImage(user.photoUrl) as ImageProvider, fit: BoxFit.cover))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.displayName, style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(user.thixId, style: context.textStyles.bodySmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(verified ? Icons.verified : Icons.hourglass_bottom, size: 12, color: Colors.white), const SizedBox(width: 4), Text(verified ? 'Vérifié' : 'En attente', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))])),
            ])),
          ])),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ActionBtn(icon: Icons.edit, label: 'Modifier', onTap: onEditProfile)),
          const SizedBox(width: 8), Expanded(child: _ActionBtn(icon: Icons.download, label: 'CV', onTap: onDownloadCv)),
          const SizedBox(width: 8), Expanded(child: _ActionBtn(icon: Icons.share, label: 'Partager', onTap: onShareProfile)),
        ])
      ]),
    );
  }
}
class _IconBtn extends StatelessWidget { final IconData icon; final VoidCallback onTap; const _IconBtn({required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: IconButton(icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap)); }
class _ActionBtn extends StatelessWidget { final IconData icon; final String label; final VoidCallback onTap; const _ActionBtn({required this.icon, required this.label, required this.onTap}); @override Widget build(BuildContext context) => SizedBox(height: 40, child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 16, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.2)), backgroundColor: Colors.white.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))))); }

class DashboardTabsHeader extends StatelessWidget { const DashboardTabsHeader({super.key}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12,0,12,8), color: const Color(0xFF123B7A), child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)), child: TabBar(isScrollable: true, labelColor: LightModeColors.accent, unselectedLabelColor: Colors.white70, indicator: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(30)), dividerColor: Colors.transparent, labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900), tabs: const [Tab(icon: Icon(Icons.person, size:18), text: 'Profil'), Tab(icon: Icon(Icons.folder, size:18), text: 'Docs'), Tab(icon: Icon(Icons.work, size:18), text: 'Exp'), Tab(icon: Icon(Icons.school, size:18), text: 'Form'), Tab(icon: Icon(Icons.description, size:18), text: 'CV'), Tab(icon: Icon(Icons.payments, size:18), text: 'Pay'), Tab(icon: Icon(Icons.security, size:18), text: 'Sec')]))); }
class ChatFab extends StatelessWidget { const ChatFab({super.key}); @override Widget build(BuildContext context) => Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [LightModeColors.accent, Color(0xFFE5B13A)])), child: const Icon(Icons.forum, color: Color(0xFF123B7A))); }
class DashboardCard extends StatelessWidget { final IconData icon; final String title, subtitle; final Widget child; const DashboardCard({super.key, required this.icon, required this.title, required this.subtitle, required this.child}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEAEAEA))), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: const Color(0xFF123B7A), size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey))]))]), const SizedBox(height: 12), child])); }
class DashboardInfoRow extends StatelessWidget { final String label, value; const DashboardInfoRow({super.key, required this.label, required this.value}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700))), Expanded(child: Text(value, style: const TextStyle(fontSize: 13)))])); }
class StatusChip extends StatelessWidget { final String label; final Color bg, textColor; const StatusChip({super.key, required this.label, required this.bg, required this.textColor}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w700))); }
class DocRow extends StatelessWidget { final String name, date, status; final Color statusBg, statusText; const DocRow({super.key, required this.name, required this.date, required this.status, required this.statusBg, required this.statusText}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0F4FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.insert_drive_file, color: Color(0xFF123B7A))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey))])), StatusChip(label: status, bg: statusBg, textColor: statusText)])); }
class ActivationCalloutCard extends StatelessWidget { final VoidCallback onActivate; const ActivationCalloutCard({super.key, required this.onActivate}); @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: LightModeColors.accent.withOpacity(0.3))), child: Column(children: [const Row(children: [Icon(Icons.verified, color: Color(0xFF123B7A)), SizedBox(width: 8), Text('Compte en attente', style: TextStyle(fontWeight: FontWeight.w900))]), const SizedBox(height: 12), ElevatedButton.icon(onPressed: onActivate, icon: const Icon(Icons.payments, color: Color(0xFF123B7A)), label: const Text('Activer mon compte', style: TextStyle(color: Color(0xFF123B7A), fontWeight: FontWeight.w900)), style: ElevatedButton.styleFrom(backgroundColor: LightModeColors.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))))])); }
class TabScaffold extends StatelessWidget { final List<Widget> children; const TabScaffold({super.key, required this.children}); @override Widget build(BuildContext context) => SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16,16,16,120), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)); }
class ShareProfileSheet { static Future<void> show(BuildContext context, dynamic profile) async { await showModalBottomSheet<void>(context: context, backgroundColor: Colors.transparent, builder: (_) => Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))), padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.remove_red_eye), title: const Text('Voir profil public'), onTap: (){ context.pop(); context.push('${AppRoutes.publicProfile}?thixId=${Uri.encodeComponent(profile.thixId)}'); }), ListTile(leading: const Icon(Icons.share), title: const Text('Partager lien'), onTap: () async { context.pop(); final url = 'https://thix.app/public-profile?thixId=${Uri.encodeComponent(profile.thixId)}'; await Share.share('Mon THIX ID: ${profile.thixId}\n$url'); })]))); } }
